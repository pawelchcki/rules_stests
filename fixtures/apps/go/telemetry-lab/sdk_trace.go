package main

import (
	"compress/gzip"
	"context"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"sync"
	"sync/atomic"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/baggage"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/sdk/instrumentation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/sdk/trace/tracetest"
	"go.opentelemetry.io/otel/trace"
)

type traceProbeKey struct{}

type labErrorRecorder struct {
	mu       sync.Mutex
	messages []string
}

func (r *labErrorRecorder) Handle(err error) {
	r.mu.Lock()
	r.messages = append(r.messages, err.Error())
	r.mu.Unlock()
}

func inspectOTLPPartialSuccess(ctx context.Context) (any, error) {
	message := "lab partial"
	// ExportTraceServiceResponse.partial_success contains rejected_spans=1
	// and error_message="lab partial" in protobuf wire format.
	partial := append([]byte{0x08, 0x01, 0x12, byte(len(message))}, []byte(message)...)
	response := append([]byte{0x0a, byte(len(partial))}, partial...)
	requests := 0
	collector := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requests++
		w.Header().Set("Content-Type", "application/x-protobuf")
		_, _ = w.Write(response)
	}))
	defer collector.Close()
	exporter, err := otlptracehttp.New(ctx, otlptracehttp.WithEndpointURL(collector.URL+"/v1/traces"))
	if err != nil {
		return nil, err
	}
	recorder := &labErrorRecorder{}
	previous := otel.GetErrorHandler()
	otel.SetErrorHandler(recorder)
	defer otel.SetErrorHandler(previous)
	provider := sdktrace.NewTracerProvider(sdktrace.WithSyncer(exporter))
	_, span := provider.Tracer("lab.partial").Start(ctx, "lab.partial")
	span.End()
	if err := provider.Shutdown(ctx); err != nil {
		return nil, err
	}
	recorder.mu.Lock()
	defer recorder.mu.Unlock()
	return map[string]any{"requests": requests, "messages": recorder.messages}, nil
}

type traceProbeSampler struct {
	parentID string
	marker   string
	state    trace.TraceState
}

func inspectOTLPHTTP(ctx context.Context) (any, error) {
	start := time.Now()
	span := tracetest.SpanStub{
		Name: "lab.http-export", StartTime: start, EndTime: start.Add(time.Millisecond),
		SpanContext: trace.NewSpanContext(trace.SpanContextConfig{
			TraceID: trace.TraceID{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16},
			SpanID:  trace.SpanID{1, 2, 3, 4, 5, 6, 7, 8}, TraceFlags: trace.FlagsSampled,
		}),
		Resource: resource.Empty(), InstrumentationScope: instrumentation.Scope{Name: "lab.http-export"},
	}.Snapshot()
	results := map[string]any{}
	for _, mode := range []string{"non-retryable", "retryable", "throttled", "gzip"} {
		requests := 0
		validPayload := true
		compressed := false
		collector := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			requests++
			if r.Method != http.MethodPost || r.URL.Path != "/v1/traces" || r.Header.Get("Content-Type") != "application/x-protobuf" {
				validPayload = false
			}
			var reader io.Reader = r.Body
			if r.Header.Get("Content-Encoding") == "gzip" {
				compressed = true
				uncompressed, err := gzip.NewReader(r.Body)
				if err != nil {
					validPayload = false
				} else {
					defer uncompressed.Close()
					reader = uncompressed
				}
			}
			body, err := io.ReadAll(reader)
			if err != nil || len(body) == 0 {
				validPayload = false
			}
			if requests == 1 {
				switch mode {
				case "non-retryable":
					w.WriteHeader(http.StatusBadRequest)
					return
				case "retryable":
					w.WriteHeader(http.StatusServiceUnavailable)
					return
				case "throttled":
					w.Header().Set("Retry-After", "1")
					w.WriteHeader(http.StatusTooManyRequests)
					return
				}
			}
			w.WriteHeader(http.StatusOK)
		}))
		options := []otlptracehttp.Option{
			otlptracehttp.WithEndpointURL(collector.URL + "/v1/traces"),
			otlptracehttp.WithRetry(otlptracehttp.RetryConfig{
				Enabled: true, InitialInterval: 20 * time.Millisecond,
				MaxInterval: 20 * time.Millisecond, MaxElapsedTime: 3 * time.Second,
			}),
		}
		if mode == "gzip" {
			options = append(options, otlptracehttp.WithCompression(otlptracehttp.GzipCompression))
		}
		exporter, err := otlptracehttp.New(ctx, options...)
		if err != nil {
			collector.Close()
			return nil, err
		}
		began := time.Now()
		exportErr := exporter.ExportSpans(ctx, []sdktrace.ReadOnlySpan{span})
		elapsed := time.Since(began)
		shutdownErr := exporter.Shutdown(ctx)
		collector.Close()
		if shutdownErr != nil {
			return nil, shutdownErr
		}
		results[mode] = map[string]any{
			"requests": requests, "payload_valid": validPayload, "compressed": compressed,
			"error": exportErr != nil, "elapsed_millis": elapsed.Milliseconds(),
		}
	}
	var concurrentRequests, active, maximum atomic.Int32
	concurrentCollector := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		concurrentRequests.Add(1)
		current := active.Add(1)
		for {
			previous := maximum.Load()
			if current <= previous || maximum.CompareAndSwap(previous, current) {
				break
			}
		}
		time.Sleep(40 * time.Millisecond)
		active.Add(-1)
		w.WriteHeader(http.StatusOK)
	}))
	concurrentExporter, err := otlptracehttp.New(ctx, otlptracehttp.WithEndpointURL(concurrentCollector.URL+"/v1/traces"))
	if err != nil {
		concurrentCollector.Close()
		return nil, err
	}
	var workers sync.WaitGroup
	var successes atomic.Int32
	for range 4 {
		workers.Add(1)
		go func() {
			defer workers.Done()
			if concurrentExporter.ExportSpans(ctx, []sdktrace.ReadOnlySpan{span}) == nil {
				successes.Add(1)
			}
		}()
	}
	workers.Wait()
	shutdownErr := concurrentExporter.Shutdown(ctx)
	concurrentCollector.Close()
	if shutdownErr != nil {
		return nil, shutdownErr
	}
	results["concurrent"] = map[string]any{"requests": concurrentRequests.Load(), "maximum": maximum.Load(), "successes": successes.Load()}
	return results, nil
}

func (s *traceProbeSampler) ShouldSample(parameters sdktrace.SamplingParameters) sdktrace.SamplingResult {
	s.parentID = trace.SpanContextFromContext(parameters.ParentContext).SpanID().String()
	s.marker, _ = parameters.ParentContext.Value(traceProbeKey{}).(string)
	return sdktrace.SamplingResult{Decision: sdktrace.RecordAndSample, Tracestate: s.state}
}

func (*traceProbeSampler) Description() string { return "telemetry-lab custom sampler" }

type traceProbeProcessor struct {
	parentID        string
	marker          string
	scope           string
	scopeAttributes bool
	flushed         bool
	shut            bool
}

func (p *traceProbeProcessor) OnStart(parent context.Context, _ sdktrace.ReadWriteSpan) {
	p.parentID = trace.SpanContextFromContext(parent).SpanID().String()
	p.marker, _ = parent.Value(traceProbeKey{}).(string)
}

func (p *traceProbeProcessor) OnEnd(span sdktrace.ReadOnlySpan) {
	p.scope = span.InstrumentationScope().Name
	attributes := span.InstrumentationScope().Attributes
	value, ok := attributes.Value("lab.scope")
	p.scopeAttributes = ok && value.AsString() == "trace"
}

func (p *traceProbeProcessor) ForceFlush(context.Context) error { p.flushed = true; return nil }
func (p *traceProbeProcessor) Shutdown(context.Context) error   { p.shut = true; return nil }

func inspectTraceSDK(ctx context.Context) (any, error) {
	state, err := trace.ParseTraceState("lab=sampled")
	if err != nil {
		return nil, err
	}
	sam := &traceProbeSampler{state: state}
	processor := &traceProbeProcessor{}
	exporter := tracetest.NewInMemoryExporter()
	provider := sdktrace.NewTracerProvider(
		sdktrace.WithSampler(sam),
		sdktrace.WithSpanProcessor(processor),
		sdktrace.WithBatcher(exporter, sdktrace.WithBatchTimeout(time.Hour)),
	)
	parent := trace.NewSpanContext(trace.SpanContextConfig{
		TraceID:    trace.TraceID{1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16},
		SpanID:     trace.SpanID{1, 2, 3, 4, 5, 6, 7, 8},
		TraceFlags: trace.FlagsSampled,
		Remote:     true,
	})
	ctx = context.WithValue(ctx, traceProbeKey{}, "context-marker")
	ctx = trace.ContextWithRemoteSpanContext(ctx, parent)
	member, err := baggage.NewMember("lab-parent", "present")
	if err != nil {
		return nil, err
	}
	bag, err := baggage.New(member)
	if err != nil {
		return nil, err
	}
	ctx = baggage.ContextWithBaggage(ctx, bag)
	_, span := provider.Tracer("lab.sdk.scope", trace.WithInstrumentationAttributes(attribute.String("lab.scope", "trace"))).Start(ctx, "lab.sdk.child", trace.WithAttributes(attribute.String("lab.source", "custom")))
	spanID := span.SpanContext().SpanID().String()
	spanState := span.SpanContext().TraceState().Get("lab")
	span.End()
	if err := provider.ForceFlush(ctx); err != nil {
		return nil, fmt.Errorf("force flush batch processor: %w", err)
	}
	exported := exporter.GetSpans()
	if err := provider.Shutdown(ctx); err != nil {
		return nil, fmt.Errorf("shutdown provider: %w", err)
	}
	never := sdktrace.NewTracerProvider(sdktrace.WithSampler(sdktrace.NeverSample()))
	_, dropped := never.Tracer("lab.sdk.drop").Start(ctx, "lab.sdk.nonrecording")
	droppedID := dropped.SpanContext().SpanID().String()
	droppedValid := dropped.SpanContext().IsValid()
	droppedRecording := dropped.IsRecording()
	dropped.End()
	if err := never.Shutdown(ctx); err != nil {
		return nil, err
	}
	return map[string]any{
		"parent_id": parent.SpanID().String(), "sampler_parent_id": sam.parentID,
		"processor_parent_id": processor.parentID,
		"sampler_marker":      sam.marker, "processor_marker": processor.marker,
		"span_id": spanID, "span_state": spanState,
		"scope": processor.scope, "scope_attributes": processor.scopeAttributes, "flushed": processor.flushed, "shut": processor.shut,
		"exported": len(exported), "nonrecording_id": droppedID,
		"nonrecording_valid": droppedValid, "nonrecording_recording": droppedRecording,
	}, nil
}
