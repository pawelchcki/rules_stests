package main

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/metric"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/metric/exemplar"
	"go.opentelemetry.io/otel/sdk/metric/metricdata"
)

type metricSummary struct {
	Scope       string            `json:"scope"`
	Name        string            `json:"name"`
	Description string            `json:"description"`
	Unit        string            `json:"unit"`
	Value       int64             `json:"value"`
	Attributes  map[string]string `json:"attributes"`
}

type labMetricExporter struct {
	mu            sync.Mutex
	calls         int
	active        int
	maximum       int
	lastValue     int64
	batchSize     int
	flushed       bool
	shut          bool
	failNext      bool
	flushFailNext bool
}

func (*labMetricExporter) Temporality(sdkmetric.InstrumentKind) metricdata.Temporality {
	return metricdata.CumulativeTemporality
}
func (*labMetricExporter) Aggregation(kind sdkmetric.InstrumentKind) sdkmetric.Aggregation {
	if kind == sdkmetric.InstrumentKindHistogram {
		return sdkmetric.AggregationDrop{}
	}
	return sdkmetric.DefaultAggregationSelector(kind)
}
func (e *labMetricExporter) Export(ctx context.Context, data *metricdata.ResourceMetrics) error {
	e.mu.Lock()
	e.active++
	if e.active > e.maximum {
		e.maximum = e.active
	}
	e.calls++
	e.batchSize = 0
	for _, scope := range data.ScopeMetrics {
		for _, stream := range scope.Metrics {
			e.batchSize++
			if sum, ok := stream.Data.(metricdata.Sum[int64]); ok {
				for _, point := range sum.DataPoints {
					e.lastValue = point.Value
				}
			}
		}
	}
	fail := e.failNext
	e.failNext = false
	e.mu.Unlock()
	defer func() { e.mu.Lock(); e.active--; e.mu.Unlock() }()
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-time.After(2 * time.Millisecond):
	}
	if fail {
		return fmt.Errorf("controlled exporter failure")
	}
	return nil
}
func (e *labMetricExporter) ForceFlush(ctx context.Context) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	e.mu.Lock()
	fail := e.flushFailNext
	e.flushFailNext = false
	e.flushed = true
	e.mu.Unlock()
	if fail {
		return fmt.Errorf("controlled force-flush failure")
	}
	return nil
}
func (e *labMetricExporter) Shutdown(context.Context) error {
	e.mu.Lock()
	e.shut = true
	e.mu.Unlock()
	return nil
}

func inspectMetricExporter(ctx context.Context) (any, error) {
	exporter := &labMetricExporter{}
	reader := sdkmetric.NewPeriodicReader(exporter, sdkmetric.WithInterval(time.Hour))
	provider := sdkmetric.NewMeterProvider(sdkmetric.WithReader(reader))
	meter := provider.Meter("lab.exporter")
	counter, err := meter.Int64Counter("lab.exporter.counter")
	if err != nil {
		return nil, err
	}
	histogram, err := meter.Int64Histogram("lab.exporter.histogram")
	if err != nil {
		return nil, err
	}
	counter.Add(ctx, 2)
	counter.Add(ctx, 3)
	histogram.Record(ctx, 9)
	if err := provider.ForceFlush(ctx); err != nil {
		return nil, err
	}
	exporter.mu.Lock()
	firstValue, firstBatch, firstCalls, firstFlushed := exporter.lastValue, exporter.batchSize, exporter.calls, exporter.flushed
	exporter.failNext = true
	exporter.mu.Unlock()
	counter.Add(ctx, 1)
	failure := provider.ForceFlush(ctx) != nil
	exporter.mu.Lock()
	exporter.flushFailNext = true
	exporter.mu.Unlock()
	flushFailure := provider.ForceFlush(ctx) != nil
	expired, cancel := context.WithDeadline(ctx, time.Now().Add(-time.Second))
	defer cancel()
	flushTimeout := errors.Is(exporter.ForceFlush(expired), context.DeadlineExceeded)
	providerFlushTimeout := errors.Is(provider.ForceFlush(expired), context.DeadlineExceeded)
	counter.Add(ctx, 1)
	var workers sync.WaitGroup
	failures := make(chan error, 8)
	for range 8 {
		workers.Add(1)
		go func() { defer workers.Done(); failures <- provider.ForceFlush(ctx) }()
	}
	workers.Wait()
	close(failures)
	for flushErr := range failures {
		if flushErr != nil {
			return nil, flushErr
		}
	}
	if err := provider.Shutdown(ctx); err != nil {
		return nil, err
	}
	exporter.mu.Lock()
	defer exporter.mu.Unlock()
	return map[string]any{"first_value": firstValue, "first_batch": firstBatch, "first_calls": firstCalls,
		"first_flushed": firstFlushed, "controlled_failure": failure, "flush_failure": flushFailure, "flush_timeout": flushTimeout, "provider_flush_timeout": providerFlushTimeout, "calls": exporter.calls,
		"maximum_concurrent": exporter.maximum, "shutdown": exporter.shut, "flush": exporter.flushed}, nil
}

func inspectMetricExemplars(ctx context.Context) (any, error) {
	inspect := func(filter exemplar.Filter, customView bool) (int, bool, bool, error) {
		reader := sdkmetric.NewManualReader()
		options := []sdkmetric.Option{sdkmetric.WithReader(reader), sdkmetric.WithExemplarFilter(filter)}
		selectorCalled := false
		if customView {
			options = append(options, sdkmetric.WithView(sdkmetric.NewView(sdkmetric.Instrument{Name: "lab.exemplar"}, sdkmetric.Stream{
				AttributeFilter: attribute.NewAllowKeysFilter("lab.keep"),
				ExemplarReservoirProviderSelector: func(agg sdkmetric.Aggregation) exemplar.ReservoirProvider {
					selectorCalled = true
					return exemplar.FixedSizeReservoirProvider(1)
				},
			})))
		}
		provider := sdkmetric.NewMeterProvider(options...)
		defer provider.Shutdown(ctx)
		counter, err := provider.Meter("lab.exemplar.scope").Int64Counter("lab.exemplar")
		if err != nil {
			return 0, false, false, err
		}
		counter.Add(ctx, 1, metric.WithAttributes(attribute.String("lab.keep", "yes"), attribute.String("lab.secret", "retained")))
		var data metricdata.ResourceMetrics
		if err := reader.Collect(ctx, &data); err != nil {
			return 0, false, false, err
		}
		for _, scope := range data.ScopeMetrics {
			for _, stream := range scope.Metrics {
				if stream.Name != "lab.exemplar" {
					continue
				}
				sum, ok := stream.Data.(metricdata.Sum[int64])
				if !ok || len(sum.DataPoints) != 1 {
					return 0, false, false, fmt.Errorf("exemplar sum missing")
				}
				point := sum.DataPoints[0]
				filtered := false
				if len(point.Exemplars) > 0 {
					for _, item := range point.Exemplars[0].FilteredAttributes {
						if item.Key == "lab.secret" && item.Value.AsString() == "retained" {
							filtered = true
						}
					}
				}
				return len(point.Exemplars), filtered, selectorCalled, nil
			}
		}
		return 0, false, false, fmt.Errorf("exemplar metric missing")
	}
	onCount, retained, selected, err := inspect(exemplar.AlwaysOnFilter, true)
	if err != nil {
		return nil, err
	}
	offCount, _, _, err := inspect(exemplar.AlwaysOffFilter, false)
	if err != nil {
		return nil, err
	}
	defaultSum := sdkmetric.DefaultExemplarReservoirProviderSelector(sdkmetric.AggregationSum{})(*attribute.EmptySet())
	defaultHistogram := sdkmetric.DefaultExemplarReservoirProviderSelector(sdkmetric.AggregationExplicitBucketHistogram{Boundaries: []float64{1, 2}})(*attribute.EmptySet())
	manual := exemplar.NewFixedSizeReservoir(1)
	offeredAt := time.Now()
	manual.Offer(ctx, offeredAt, exemplar.NewValue(int64(7)), []attribute.KeyValue{attribute.String("lab.offer", "received")})
	var offered []exemplar.Exemplar
	manual.Collect(&offered)
	offerValid := len(offered) == 1 && offered[0].Value.Int64() == 7 && offered[0].Time.Equal(offeredAt) && len(offered[0].FilteredAttributes) == 1 && offered[0].FilteredAttributes[0].Key == "lab.offer"
	return map[string]any{"on_count": onCount, "off_count": offCount, "retained_filtered_attribute": retained, "custom_reservoir_selected": selected,
		"default_sum_reservoir": fmt.Sprintf("%T", defaultSum), "default_histogram_reservoir": fmt.Sprintf("%T", defaultHistogram), "offer_valid": offerValid}, nil
}

func summaries(data metricdata.ResourceMetrics) []metricSummary {
	var result []metricSummary
	for _, scope := range data.ScopeMetrics {
		for _, stream := range scope.Metrics {
			sum, ok := stream.Data.(metricdata.Sum[int64])
			if !ok {
				continue
			}
			for _, point := range sum.DataPoints {
				attrs := map[string]string{}
				for _, item := range point.Attributes.ToSlice() {
					attrs[string(item.Key)] = item.Value.AsString()
				}
				result = append(result, metricSummary{
					Scope: scope.Scope.Name, Name: stream.Name,
					Description: stream.Description, Unit: stream.Unit,
					Value: point.Value, Attributes: attrs,
				})
			}
		}
	}
	return result
}

func inspectMetricViews(ctx context.Context) (any, error) {
	reader := sdkmetric.NewManualReader()
	provider := sdkmetric.NewMeterProvider(
		sdkmetric.WithReader(reader),
		sdkmetric.WithView(
			sdkmetric.NewView(sdkmetric.Instrument{Name: "lab.view.counter"}, sdkmetric.Stream{
				Name: "lab.view.renamed", Description: "renamed by exact view", Unit: "{call}",
				AttributeFilter: attribute.NewAllowKeysFilter("lab.keep"), Aggregation: sdkmetric.AggregationSum{},
			}),
			sdkmetric.NewView(sdkmetric.Instrument{Name: "lab.view.*"}, sdkmetric.Stream{
				Description: "selected by wildcard", AttributeFilter: attribute.NewDenyKeysFilter("lab.drop"),
			}),
			sdkmetric.NewView(sdkmetric.Instrument{Name: "lab.dropped"}, sdkmetric.Stream{
				Aggregation: sdkmetric.AggregationDrop{},
			}),
		),
	)
	defer provider.Shutdown(ctx)
	otel.SetMeterProvider(provider)
	global := otel.GetMeterProvider() == provider
	meter := provider.Meter("lab.primary")
	viewed, err := meter.Int64Counter("lab.view.counter", metric.WithDescription("original"))
	if err != nil {
		return nil, err
	}
	viewed.Add(ctx, 3, metric.WithAttributes(attribute.String("lab.keep", "yes"), attribute.String("lab.drop", "no")))
	unmatched, err := meter.Int64Counter("lab.unmatched")
	if err != nil {
		return nil, err
	}
	unmatched.Add(ctx, 4)
	dropped, err := meter.Int64Counter("lab.dropped")
	if err != nil {
		return nil, err
	}
	dropped.Add(ctx, 5)
	otherMeter := provider.Meter("lab.secondary")
	firstScope, err := meter.Int64Counter("lab.scope.counter")
	if err != nil {
		return nil, err
	}
	secondScope, err := otherMeter.Int64Counter("lab.scope.counter")
	if err != nil {
		return nil, err
	}
	firstScope.Add(ctx, 6)
	secondScope.Add(ctx, 7)
	concurrentMeter := provider.Meter("lab.concurrent")
	sharedCounter, err := concurrentMeter.Int64Counter("lab.concurrent.counter")
	if err != nil {
		return nil, err
	}
	var workers sync.WaitGroup
	for range 32 {
		workers.Add(1)
		go func() {
			defer workers.Done()
			provider.Meter("lab.concurrent")
			_, createErr := concurrentMeter.Int64Counter("lab.concurrent.counter")
			if createErr == nil {
				sharedCounter.Add(ctx, 1)
			}
		}()
	}
	workers.Wait()
	var collected metricdata.ResourceMetrics
	if err := reader.Collect(ctx, &collected); err != nil {
		return nil, fmt.Errorf("collect view metrics: %w", err)
	}
	allReader := sdkmetric.NewManualReader()
	allProvider := sdkmetric.NewMeterProvider(sdkmetric.WithReader(allReader), sdkmetric.WithView(
		sdkmetric.NewView(sdkmetric.Instrument{Name: "*"}, sdkmetric.Stream{Description: "matched all"}),
	))
	defer allProvider.Shutdown(ctx)
	allMeter := allProvider.Meter("lab.all")
	allCounter, err := allMeter.Int64Counter("lab.all.counter")
	if err != nil {
		return nil, err
	}
	allCounter.Add(ctx, 8)
	var allCollected metricdata.ResourceMetrics
	if err := allReader.Collect(ctx, &allCollected); err != nil {
		return nil, fmt.Errorf("collect match-all metrics: %w", err)
	}
	return map[string]any{
		"global": global, "providers_distinct": provider != allProvider,
		"streams": summaries(collected), "all_streams": summaries(allCollected),
	}, nil
}

// inspectMetricAdvanced keeps the reader's raw data types visible to the
// probe, so a catalog claim cannot pass on an HTTP status alone.
func inspectMetricAdvanced(ctx context.Context) (any, error) {
	reader := sdkmetric.NewManualReader()
	provider := sdkmetric.NewMeterProvider(
		sdkmetric.WithReader(reader),
		sdkmetric.WithCardinalityLimit(2),
		sdkmetric.WithView(sdkmetric.NewView(sdkmetric.Instrument{Name: "lab.exp.hist"}, sdkmetric.Stream{
			Aggregation: sdkmetric.AggregationBase2ExponentialHistogram{MaxScale: 4, MaxSize: 16},
		})),
	)
	defer provider.Shutdown(ctx)
	meter := provider.Meter("lab.advanced", metric.WithInstrumentationAttributes(attribute.String("lab.scope", "present")))
	duplicateA, err := meter.Int64Counter("lab.duplicate", metric.WithDescription("first"))
	if err != nil {
		return nil, err
	}
	duplicateB, err := meter.Int64Counter("lab.duplicate", metric.WithDescription("first"))
	if err != nil {
		return nil, err
	}
	duplicateA.Add(ctx, 2)
	duplicateB.Add(ctx, 3)
	advisory, err := meter.Int64Histogram("lab.advisory.hist", metric.WithExplicitBucketBoundaries(2, 4))
	if err != nil {
		return nil, err
	}
	advisory.Record(ctx, 3)
	exponential, err := meter.Int64Histogram("lab.exp.hist")
	if err != nil {
		return nil, err
	}
	exponential.Record(ctx, 8)
	cardinal, err := meter.Int64Counter("lab.cardinal")
	if err != nil {
		return nil, err
	}
	for index := range 4 {
		cardinal.Add(ctx, 1, metric.WithAttributes(attribute.Int("lab.series", index)))
	}
	invalidMeter := provider.Meter("")
	invalidCounter, err := invalidMeter.Int64Counter("lab.invalid.meter")
	if err != nil {
		return nil, err
	}
	invalidCounter.Add(ctx, 1)
	var collected metricdata.ResourceMetrics
	if err := reader.Collect(ctx, &collected); err != nil {
		return nil, err
	}
	result := map[string]any{"scope_attributes": false, "invalid_scope": "", "duplicate_value": int64(0), "advisory_bounds": []float64{}, "exponential": false, "cardinal_points": 0, "cardinal_total": int64(0), "default_counter_sum": false}
	for _, scope := range collected.ScopeMetrics {
		if scope.Scope.Name == "lab.advanced" {
			value, ok := scope.Scope.Attributes.Value("lab.scope")
			result["scope_attributes"] = ok && value.AsString() == "present"
		}
		for _, stream := range scope.Metrics {
			switch stream.Name {
			case "lab.duplicate":
				if sum, ok := stream.Data.(metricdata.Sum[int64]); ok && len(sum.DataPoints) == 1 {
					result["duplicate_value"] = sum.DataPoints[0].Value
					result["default_counter_sum"] = sum.IsMonotonic
				}
			case "lab.advisory.hist":
				if histogram, ok := stream.Data.(metricdata.Histogram[int64]); ok && len(histogram.DataPoints) == 1 {
					result["advisory_bounds"] = histogram.DataPoints[0].Bounds
				}
			case "lab.exp.hist":
				_, result["exponential"] = stream.Data.(metricdata.ExponentialHistogram[int64])
			case "lab.cardinal":
				if sum, ok := stream.Data.(metricdata.Sum[int64]); ok {
					result["cardinal_points"] = len(sum.DataPoints)
					for _, point := range sum.DataPoints {
						result["cardinal_total"] = result["cardinal_total"].(int64) + point.Value
					}
				}
			case "lab.invalid.meter":
				result["invalid_scope"] = scope.Scope.Name
			}
		}
	}
	return result, nil
}
