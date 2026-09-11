//go:build datadog

package main

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	httptrace "github.com/DataDog/dd-trace-go/contrib/net/http/v2"
	"github.com/DataDog/dd-trace-go/v2/ddtrace/tracer"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

var probeMarkers sync.Map
var probeHeld sync.Map

type probeMarker struct {
	request, marker string
	count           atomic.Int64
}
type probeResponseWriter struct {
	gin.ResponseWriter
	marker *probeMarker
}

func (w probeResponseWriter) stamp() {
	w.Header().Set("X-Rules-Stests-Sql-Count", fmt.Sprint(w.marker.count.Load()))
}
func (w probeResponseWriter) WriteHeader(code int) { w.stamp(); w.ResponseWriter.WriteHeader(code) }
func (w probeResponseWriter) WriteHeaderNow()      { w.stamp(); w.ResponseWriter.WriteHeaderNow() }
func (w probeResponseWriter) Write(data []byte) (int, error) {
	w.stamp()
	return w.ResponseWriter.Write(data)
}
func (w probeResponseWriter) WriteString(data string) (int, error) {
	w.stamp()
	return w.ResponseWriter.WriteString(data)
}

func probeSQL(ctx context.Context, query string) string {
	if strings.Contains(query, "/* rules_stests_request=") {
		return query
	}
	if span, ok := tracer.SpanFromContext(ctx); ok {
		if value, ok := probeMarkers.Load(span.Context().TraceID()); ok {
			m := value.(*probeMarker)
			m.count.Add(1)
			return query + " /* rules_stests_request=" + m.request + "; marker=" + m.marker + " */"
		}
	}
	return query
}

type markedPool struct{ gorm.ConnPool }

func (p markedPool) PrepareContext(ctx context.Context, q string) (*sql.Stmt, error) {
	return p.ConnPool.PrepareContext(ctx, probeSQL(ctx, q))
}
func (p markedPool) ExecContext(ctx context.Context, q string, args ...interface{}) (sql.Result, error) {
	return p.ConnPool.ExecContext(ctx, probeSQL(ctx, q), args...)
}
func (p markedPool) QueryContext(ctx context.Context, q string, args ...interface{}) (*sql.Rows, error) {
	return p.ConnPool.QueryContext(ctx, probeSQL(ctx, q), args...)
}
func (p markedPool) QueryRowContext(ctx context.Context, q string, args ...interface{}) *sql.Row {
	return p.ConnPool.QueryRowContext(ctx, probeSQL(ctx, q), args...)
}
func (p markedPool) BeginTx(ctx context.Context, options *sql.TxOptions) (gorm.ConnPool, error) {
	if b, ok := p.ConnPool.(gorm.TxBeginner); ok {
		tx, err := b.BeginTx(ctx, options)
		if err != nil {
			return nil, err
		}
		return &markedTx{markedPool{tx}}, nil
	}
	if b, ok := p.ConnPool.(gorm.ConnPoolBeginner); ok {
		tx, err := b.BeginTx(ctx, options)
		if err != nil {
			return nil, err
		}
		return &markedTx{markedPool{tx}}, nil
	}
	return nil, fmt.Errorf("probe pool cannot begin transaction")
}

type markedTx struct{ markedPool }

func (p *markedTx) Commit() error   { return p.ConnPool.(gorm.TxCommitter).Commit() }
func (p *markedTx) Rollback() error { return p.ConnPool.(gorm.TxCommitter).Rollback() }

func installFixtureProbes(router *gin.Engine, db *gorm.DB) {
	markers := os.Getenv("RULES_STESTS_SQL_MARKERS") == "true"
	probes := os.Getenv("RULES_STESTS_PROBES") == "true"
	if !markers && !probes {
		return
	}
	if markers {
		db.ConnPool = markedPool{db.ConnPool}
		db.Statement.ConnPool = db.ConnPool
		mark := func(db *gorm.DB) {
			q := probeSQL(db.Statement.Context, db.Statement.SQL.String())
			db.Statement.SQL.Reset()
			db.Statement.SQL.WriteString(q)
		}
		callbacks := db.Callback()
		if err := callbacks.Query().After("gorm:query").Before("dd-trace-go:after_query").Register("rules_stests:marker", mark); err != nil {
			panic(err)
		}
		if err := callbacks.Create().After("gorm:create").Before("dd-trace-go:after_create").Register("rules_stests:marker", mark); err != nil {
			panic(err)
		}
		if err := callbacks.Update().After("gorm:update").Before("dd-trace-go:after_update").Register("rules_stests:marker", mark); err != nil {
			panic(err)
		}
		if err := callbacks.Delete().After("gorm:delete").Before("dd-trace-go:after_delete").Register("rules_stests:marker", mark); err != nil {
			panic(err)
		}
		if err := callbacks.Row().After("gorm:row").Before("dd-trace-go:after_row_query").Register("rules_stests:marker", mark); err != nil {
			panic(err)
		}
		if err := callbacks.Raw().After("gorm:raw").Before("dd-trace-go:after_raw_query").Register("rules_stests:marker", mark); err != nil {
			panic(err)
		}
	}
	router.Use(func(c *gin.Context) {
		id := c.GetHeader("X-Rules-Stests-Request-Id")
		if !markers || id == "" {
			c.Next()
			return
		}
		if len(id) != 32 {
			c.AbortWithStatus(400)
			return
		}
		if _, err := hex.DecodeString(id); err != nil {
			c.AbortWithStatus(400)
			return
		}
		var random [16]byte
		if _, err := rand.Read(random[:]); err != nil {
			panic(err)
		}
		marker := hex.EncodeToString(random[:])
		span, ok := tracer.SpanFromContext(c.Request.Context())
		if !ok {
			c.AbortWithStatus(500)
			return
		}
		key := span.Context().TraceID()
		m := &probeMarker{request: id, marker: marker}
		probeMarkers.Store(key, m)
		c.Writer = probeResponseWriter{ResponseWriter: c.Writer, marker: m}
		defer probeMarkers.Delete(key)
		span.SetTag("rules_stests.request_id", id)
		c.Header("X-Rules-Stests-Sql-Marker", marker)
		c.Next()
	})
	if !probes {
		return
	}
	router.Any("/__rules_stests/:kind", func(c *gin.Context) {
		kind := c.Param("kind")
		switch kind {
		case "nested", "keep", "drop", "partial":
			if root, ok := tracer.SpanFromContext(c.Request.Context()); ok {
				if kind == "keep" {
					root.SetTag("manual.keep", true)
				}
				if kind == "drop" {
					root.SetTag("manual.drop", true)
				}
			}
			parent, ctx := tracer.StartSpanFromContext(c.Request.Context(), "probe.parent", tracer.ResourceName(kind))
			for i := 0; i < 3; i++ {
				child, _ := tracer.StartSpanFromContext(ctx, "probe.child", tracer.ResourceName(fmt.Sprint(i)))
				child.SetTag("probe.index", fmt.Sprint(i))
				child.Finish()
			}
			parent.Finish()
			if kind == "partial" {
				event := make(chan struct{})
				key := c.Query("key")
				probeHeld.Store(key, event)
				defer probeHeld.Delete(key)
				select {
				case <-event:
				case <-time.After(15 * time.Second):
					c.AbortWithStatus(504)
					return
				}
			}
			c.JSON(200, gin.H{"children": 3})
		case "state":
			_, ok := probeHeld.Load(c.Query("key"))
			c.JSON(200, gin.H{"held": ok})
		case "release":
			value, ok := probeHeld.LoadAndDelete(c.Query("key"))
			if ok {
				close(value.(chan struct{}))
			}
			c.JSON(200, gin.H{"released": ok})
		case "exception":
			err := fmt.Errorf("controlled rules_stests exception")
			exception, _ := tracer.StartSpanFromContext(c.Request.Context(), "probe.exception")
			exception.Finish(tracer.WithError(err))
			if span, ok := tracer.SpanFromContext(c.Request.Context()); ok {
				span.SetTag("error", err)
			}
			c.JSON(500, gin.H{"error": err.Error()})
		case "outbound":
			target, err := url.Parse(c.Query("url"))
			if err != nil || target.Scheme != "http" || (target.Hostname() != "localhost" && target.Hostname() != "127.0.0.1") {
				c.AbortWithStatus(400)
				return
			}
			req, err := http.NewRequestWithContext(c.Request.Context(), "GET", target.String(), nil)
			if err != nil {
				panic(err)
			}
			response, err := httptrace.WrapClient(&http.Client{}).Do(req)
			if err != nil {
				c.AbortWithStatus(502)
				return
			}
			io.Copy(io.Discard, response.Body)
			response.Body.Close()
			after, _ := tracer.StartSpanFromContext(c.Request.Context(), "probe.after_outbound")
			after.Finish()
			c.JSON(200, gin.H{"status": response.StatusCode})
		case "echo":
			c.JSON(200, c.Request.Header)
		default:
			c.AbortWithStatus(404)
		}
	})
}
