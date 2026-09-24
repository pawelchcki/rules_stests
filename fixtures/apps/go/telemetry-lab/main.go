// telemetry-lab is a standalone OpenTelemetry API workload. It has no
// RealWorld routes, database, or framework-specific behavior.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"sync"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/baggage"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/trace"
)

func main() {
	port := flag.Int("port", 0, "HTTP port")
	flag.Parse()
	if *port < 1 || *port > 65535 {
		log.Fatal("--port must be between 1 and 65535")
	}
	ctx := context.Background()
	exporter, err := otlptracehttp.New(ctx)
	if err != nil {
		log.Fatal(err)
	}
	service := os.Getenv("OTEL_SERVICE_NAME")
	if service == "" {
		service = "go-telemetry-lab"
	}
	provider := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter, sdktrace.WithBatchTimeout(100*time.Millisecond)),
		sdktrace.WithResource(resource.NewWithAttributes("", attribute.String("service.name", service))),
	)
	defer provider.Shutdown(ctx)
	otel.SetTracerProvider(provider)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(propagation.TraceContext{}, propagation.Baggage{}))
	tracer := otel.Tracer("telemetry-lab.go", trace.WithInstrumentationVersion("1.0.0"))
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		respond(w, map[string]any{"ready": true})
	})
	mux.HandleFunc("GET /v1/spans", func(w http.ResponseWriter, r *http.Request) {
		ctx, parent := tracer.Start(r.Context(), "lab.parent", trace.WithAttributes(
			attribute.String("lab.string", "visible"),
			attribute.Bool("lab.boolean", true),
			attribute.Int("lab.integer", 42),
			attribute.Float64("lab.double", 3.5),
			attribute.StringSlice("lab.array", []string{"red", "blue"}),
		))
		parent.AddEvent("lab.first", trace.WithAttributes(attribute.Int("lab.order", 1)))
		_, child := tracer.Start(ctx, "lab.child")
		child.SetAttributes(attribute.String("lab.updated", "after-start"))
		child.SetName("lab.child.renamed")
		child.SetStatus(codes.Ok, "")
		child.End()
		parent.AddEvent("lab.second", trace.WithAttributes(attribute.Int("lab.order", 2)))
		id := parent.SpanContext().TraceID().String()
		parent.End()
		respond(w, map[string]any{"trace_id": id})
	})
	mux.HandleFunc("GET /v1/exceptions", func(w http.ResponseWriter, r *http.Request) {
		_, span := tracer.Start(r.Context(), "lab.exception")
		span.RecordError(errors.New("controlled lab error"), trace.WithAttributes(attribute.Bool("lab.handled", true)))
		span.SetStatus(codes.Error, "controlled lab error")
		span.End()
		respond(w, map[string]any{"handled": true})
	})
	mux.HandleFunc("GET /v1/concurrency", func(w http.ResponseWriter, r *http.Request) {
		ctx, shared := tracer.Start(r.Context(), "lab.shared")
		var workers sync.WaitGroup
		for index := range 32 {
			workers.Add(1)
			go func() {
				defer workers.Done()
				workerTracer := provider.Tracer("telemetry-lab.concurrent")
				_, span := workerTracer.Start(ctx, "lab.concurrent", trace.WithAttributes(attribute.Int("lab.index", index)))
				shared.SetAttributes(attribute.Bool(fmt.Sprintf("lab.concurrent.%d", index), true))
				shared.AddEvent("lab.parallel", trace.WithAttributes(attribute.Int("lab.index", index)))
				span.End()
			}()
		}
		workers.Wait()
		shared.End()
		respond(w, map[string]any{"workers": 32})
	})
	mux.HandleFunc("GET /v1/resources", func(w http.ResponseWriter, r *http.Request) {
		empty := resource.Empty()
		left := resource.NewWithAttributes("", attribute.String("lab.left", "one"))
		right := resource.NewWithAttributes("", attribute.String("lab.right", "two"))
		merged, err := resource.Merge(left, right)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		values := map[string]string{}
		for _, keyValue := range merged.Attributes() {
			values[string(keyValue.Key)] = keyValue.Value.AsString()
		}
		respond(w, map[string]any{"empty": len(empty.Attributes()), "merged": values})
	})
	mux.HandleFunc("GET /v1/metric-views", func(w http.ResponseWriter, r *http.Request) {
		result, err := inspectMetricViews(r.Context())
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		respond(w, result)
	})
	mux.HandleFunc("GET /v1/metric-advanced", func(w http.ResponseWriter, r *http.Request) {
		result, err := inspectMetricAdvanced(r.Context())
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		respond(w, result)
	})
	mux.HandleFunc("GET /v1/metric-exporter", func(w http.ResponseWriter, r *http.Request) {
		result, err := inspectMetricExporter(r.Context())
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		respond(w, result)
	})
	mux.HandleFunc("GET /v1/metric-exemplars", func(w http.ResponseWriter, r *http.Request) {
		result, err := inspectMetricExemplars(r.Context())
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		respond(w, result)
	})
	mux.HandleFunc("GET /v1/sdk-trace", func(w http.ResponseWriter, r *http.Request) {
		result, err := inspectTraceSDK(r.Context())
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		respond(w, result)
	})
	mux.HandleFunc("GET /v1/propagation", func(w http.ResponseWriter, r *http.Request) {
		ctx := otel.GetTextMapPropagator().Extract(r.Context(), propagation.HeaderCarrier(r.Header))
		remoteParent := trace.SpanContextFromContext(ctx).IsRemote()
		member, err := baggage.NewMember("lab-key", "lab-value")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		bag, err := baggage.New(member)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		ctx = baggage.ContextWithBaggage(ctx, bag)
		ctx, span := tracer.Start(ctx, "lab.propagated")
		carrier := propagation.MapCarrier{}
		otel.GetTextMapPropagator().Inject(ctx, carrier)
		span.End()
		respond(w, map[string]any{"remote_parent": remoteParent, "baggage": baggage.FromContext(ctx).Member("lab-key").Value(), "carrier": carrier})
	})
	log.Fatal(http.ListenAndServe(fmt.Sprintf("127.0.0.1:%d", *port), mux))
}

func respond(w http.ResponseWriter, value any) {
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(value); err != nil {
		log.Print(err)
	}
}
