package main

import (
	"context"
	"fmt"
	"time"

	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/baggage"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/sdk/trace/tracetest"
	"go.opentelemetry.io/otel/trace"
)

type traceProbeKey struct{}

type traceProbeSampler struct {
	parentID string
	marker   string
	state    trace.TraceState
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
