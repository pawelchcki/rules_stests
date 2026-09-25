package main

import "sort"

// Each catalog ID is bound to the behavioral check that must finish before a
// passing receipt can name it. The mapping declares what to test; it never
// declares the result.
var labClaimsByCheck = map[string]map[string][]string{
	"go": {
		"response/otlp-partial": {
			"exporters.otlp.partial-success-messages-are-handled-and-logged-for-otlp-http",
		},
		"response/metric-exporter": {
			"metrics.the-metrics-exporter-forceflush-can-inform-the-caller-whether-it-succeeded-failed-or-timed-out",
			"metrics.the-metrics-reader-implementation-supports-registering-metric-exporters",
			"metrics.the-metrics-reader-implementation-supports-configuring-the-default-aggregation-on-the-basis-of-instrument-kind",
			"metrics.the-metrics-exporter-has-access-to-the-aggregated-metrics-data-aggregated-points-not-raw-measurements",
			"metrics.the-metrics-exporter-export-function-can-not-be-called-concurrently-from-the-same-exporter-instance",
			"metrics.the-metrics-exporter-export-function-receives-a-batch-of-metrics",
			"metrics.the-metrics-exporter-export-function-returns-success-or-failure",
			"metrics.the-metrics-exporter-provides-a-forceflush-function",
			"metrics.the-metrics-exporter-provides-a-shutdown-function",
		},
		"response/otlp-http": {
			"exporters.otlp.concurrent-sending",
			"exporters.otlp.honors-non-retryable-responses",
			"exporters.otlp.honors-retryable-responses-with-backoff",
			"exporters.otlp.otlp-http-gzip-content-encoding-support",
		},
		"response/sdk-trace": {
			"traces.tracerprovider.get-a-tracer-with-scope-attributes",
			"traces.tracerprovider.forceflush-sdk-only-required",
			"traces.tracerprovider.shutdown-sdk-only-required",
			"traces.span.spanprocessor-onstart-receives-parent-context",
			"traces.sampling.allow-samplers-to-modify-tracestate",
			"traces.sampling.shouldsample-gets-full-parent-context",
			"traces.sampling.new-span-id-created-also-for-non-recording-spans",
			"traces.sampling.built-in-spanprocessors-implement-forceflush-spec",
			"traces.sampling.fetch-instrumentationscope-from-readablespan",
			"exporters.in-memory-mock-exporter",
		},
		"capture/span-array": {
			"traces.span-attributes.array-of-primitives-homogeneous",
		},
		"capture/span-boolean": {
			"traces.span-attributes.boolean-type",
		},
		"capture/span-double": {
			"traces.span-attributes.double-floating-point-type",
		},
		"capture/span-events": {
			"traces.span-events.add-order-preserved",
			"traces.span-events.addevent",
		},
		"capture/span-exception": {
			"traces.span-exceptions.recordexception",
		},
		"capture/span-exception-attributes": {
			"traces.span-exceptions.recordexception-with-extra-parameters",
		},
		"capture/span-status": {
			"traces.span.set-status-with-statuscode-unset-ok-error",
		},
		"response/propagation": {
			"baggage.basic-support",
			"baggage.use-official-header-name-baggage",
		},
		"capture/concurrency": {
			"traces.tracerprovider.safe-for-concurrent-calls",
			"traces.tracer.safe-for-concurrent-calls",
			"traces.span.safe-for-concurrent-calls",
			"traces.span-events.safe-for-concurrent-calls",
		},
		"response/resources": {
			"resource.create-empty",
			"resource.merge-v2",
		},
		"response/metric-views": {
			"metrics.the-api-provides-a-way-to-set-and-get-a-global-default-meterprovider",
			"metrics.it-is-possible-to-create-any-number-of-meterproviders",
			"metrics.it-is-possible-to-register-two-instruments-with-same-name-under-different-meters",
			"metrics.all-methods-of-meterprovider-are-safe-to-be-called-concurrently",
			"metrics.all-methods-of-meter-are-safe-to-be-called-concurrently",
			"metrics.all-methods-of-any-instrument-are-safe-to-be-called-concurrently",
			"metrics.there-is-a-way-to-register-views-with-a-meterprovider",
			"metrics.the-view-instrument-selection-criteria-is-as-specified",
			"metrics.the-view-instrument-selection-criteria-supports-wildcards",
			"metrics.the-view-instrument-selection-criteria-supports-the-match-all-wildcard",
			"metrics.configuration-is-managed-solely-by-the-meterprovider",
			"metrics.the-view-allows-configuring-the-name-description-attributes-keys-and-aggregation-of-the-resulting-metric-stream",
			"metrics.the-view-allows-configuring-excluded-attribute-keys-of-resulting-metric-stream",
			"metrics.the-sdk-allows-more-than-one-view-to-be-specified-per-instrument",
			"metrics.the-drop-aggregation-is-available",
		},
		"response/metric-advanced": {
			"metrics.get-meter-accepts-attributes",
			"metrics.when-an-invalid-name-is-specified-a-working-meter-implementation-is-returned-as-a-fallback",
			"metrics.the-fallback-meter-name-property-keeps-its-original-invalid-value",
			"metrics.a-valid-instrument-must-be-created-and-warning-should-be-emitted-when-multiple-instruments-are-registered-under-the-same-meter-using-the-same-name",
			"metrics.instrument-supports-the-advisory-explicitbucketboundaries-parameter",
			"metrics.the-default-aggregation-uses-the-specified-aggregation-by-instrument",
			"metrics.the-exponentialbuckethistogram-aggregation-is-available",
			"metrics.metric-sdk-implements-cardinality-limit",
		},
		"response/metric-exemplars": {
			"metrics.the-view-allows-configuring-the-exemplar-reservoir-of-resulting-metric-stream",
			"metrics.exemplar-sampling-can-be-disabled",
			"metrics.the-metrics-sdk-supports-sdk-wide-exemplar-filter-configuration",
			"metrics.the-metrics-sdk-supports-alwayson-exemplar-filter",
			"metrics.the-metrics-sdk-supports-alwaysoff-exemplar-filter",
			"metrics.exemplars-retain-any-attributes-available-in-the-measurement-that-are-not-preserved-by-aggregation-or-view-configuration",
			"metrics.the-metrics-sdk-provides-an-exemplarreservoir-interface-or-extension-point",
			"metrics.an-exemplarreservoir-has-an-offer-method-with-access-to-the-measurement-value-attributes-context-and-timestamp",
			"metrics.the-metrics-sdk-provides-a-simplefixedsizeexemplarreservoir-that-is-used-by-default-for-all-aggregations-except-explicitbuckethistogram",
			"metrics.the-metrics-sdk-provides-an-alignedhistogrambucketexemplarreservoir-that-is-used-by-default-for-explicitbuckethistogram-aggregation",
		},
	},
	"ruby": {
		"response/lifecycle": {
			"traces.span.isrecording",
			"traces.span.isrecording-becomes-false-after-end",
			"traces.trace-context-interaction.get-active-span",
			"traces.trace-context-interaction.set-active-span",
			"traces.tracer.get-active-span",
			"traces.tracer.mark-span-active",
			"context-propagation.create-context-key",
			"context-propagation.get-value-from-context",
			"context-propagation.set-value-for-context",
			"context-propagation.attach-context",
			"context-propagation.detach-context",
			"context-propagation.get-current-context",
		},
		"capture/lifecycle": {
			"traces.span.user-defined-start-timestamp",
			"traces.span.end-with-timestamp",
		},
		"capture/links": {
			"traces.span-linking.links-can-be-recorded-on-span-creation",
			"traces.span-linking.links-can-be-recorded-after-span-creation",
			"traces.span-linking.links-order-is-preserved",
		},
		"capture/span-array": {
			"traces.span-attributes.array-of-primitives-homogeneous",
		},
		"capture/span-boolean": {
			"traces.span-attributes.boolean-type",
		},
		"capture/span-double": {
			"traces.span-attributes.double-floating-point-type",
		},
		"capture/span-events": {
			"traces.span-events.add-order-preserved",
			"traces.span-events.addevent",
		},
		"capture/span-exception": {
			"traces.span-exceptions.recordexception",
		},
		"capture/span-exception-attributes": {
			"traces.span-exceptions.recordexception-with-extra-parameters",
		},
		"capture/span-status": {
			"traces.span.set-status-with-statuscode-unset-ok-error",
		},
		"capture/span-unicode": {
			"traces.span-attributes.unicode-support-for-keys-and-string-values",
		},
		"response/baggage": {
			"baggage.basic-support",
		},
	},
	"python": {
		"response/metric-scope": {
			"metrics.the-supplied-name-version-and-schema-url-arguments-passed-to-the-meterprovider-are-used-to-create-an-instrumentationscope-instance-stored-in-the-meter",
		},
		"capture/schema": {
			"exporters.otlp.schemaurl-in-resourcelogs-and-scopelogs",
		},
		"capture/root": {
			"traces.span.no-explicit-parent-span-spancontext-allowed",
		},
		"response/legacy-propagators": {
			"context-propagation.jaeger-propagator",
			"context-propagation.ot-propagator",
		},
		"response/prometheus": {
			"exporters.prometheus.unit-metadata",
			"exporters.prometheus.name-sanitization",
			"exporters.prometheus.unit-suffixes",
			"exporters.prometheus.help-metadata",
			"exporters.prometheus.type-metadata",
			"exporters.prometheus.otel-scope-name-and-otel-scope-version-labels-on-all-metrics",
			"exporters.prometheus.gauges-become-prometheus-gauges",
			"exporters.prometheus.cumulative-monotonic-sums-become-prometheus-counters",
			"exporters.prometheus.prometheus-counters-have-total-suffix-by-default",
			"exporters.prometheus.cumulative-non-monotonic-sums-become-prometheus-gauges",
			"exporters.prometheus.cumulative-histograms-become-prometheus-histograms",
			"exporters.prometheus.attributes-keys-are-sanitized",
			"exporters.prometheus.target-info-metric-from-resource",
		},
		"response/console-exporter": {
			"exporters.standard-output-logging",
		},
		"response/trace-exporter": {
			"exporters.exporter-interface",
			"exporters.exporter-interface-has-forceflush",
		},
		"response/propagation-custom": {
			"context-propagation.environment-variables-as-context-propagation-carriers",
			"context-propagation.setter-argument",
			"context-propagation.getter-argument-returning-keys",
		},
		"response/log-sdk": {
			"logs.loggerprovider-get-logger-accepts-attributes",
			"logs.loggerprovider-shutdown",
			"logs.loggerprovider-forceflush",
			"logs.simplelogrecordprocessor",
			"logs.can-plug-custom-logrecordprocessor",
			"logs.can-plug-custom-logrecordexporter",
		},
		"capture/span-array": {
			"traces.span-attributes.array-of-primitives-homogeneous",
		},
		"capture/span-boolean": {
			"traces.span-attributes.boolean-type",
		},
		"capture/span-double": {
			"traces.span-attributes.double-floating-point-type",
		},
		"capture/span-events": {
			"traces.span-events.add-order-preserved",
			"traces.span-events.addevent",
		},
		"capture/span-exception": {
			"traces.span-exceptions.recordexception",
		},
		"capture/span-exception-attributes": {
			"traces.span-exceptions.recordexception-with-extra-parameters",
		},
		"capture/span-status": {
			"traces.span.set-status-with-statuscode-unset-ok-error",
		},
		"capture/links": {
			"traces.span-linking.links-can-be-recorded-on-span-creation",
			"traces.span-linking.links-can-be-recorded-after-span-creation",
			"traces.span-linking.links-order-is-preserved",
		},
		"capture/lifecycle": {
			"traces.span.user-defined-start-timestamp",
			"traces.span.end-with-timestamp",
		},
		"response/lifecycle": {
			"traces.span.isrecording",
			"traces.span.isrecording-becomes-false-after-end",
			"traces.trace-context-interaction.get-active-span",
			"traces.trace-context-interaction.set-active-span",
			"traces.tracer.get-active-span",
			"traces.tracer.mark-span-active",
			"context-propagation.create-context-key",
			"context-propagation.get-value-from-context",
			"context-propagation.set-value-for-context",
			"context-propagation.attach-context",
			"context-propagation.detach-context",
			"context-propagation.get-current-context",
		},
		"response/propagation": {
			"baggage.basic-support",
			"baggage.use-official-header-name-baggage",
		},
		"capture/log-correlation": {
			"logs.trace-context-injection",
		},
	},
}

var labClaims = func() map[string][]string {
	result := make(map[string][]string, len(labClaimsByCheck))
	for language, groups := range labClaimsByCheck {
		checks := make([]string, 0, len(groups))
		for check := range groups {
			checks = append(checks, check)
		}
		sort.Strings(checks)
		for _, check := range checks {
			result[language] = append(result[language], groups[check]...)
		}
	}
	return result
}()

func labCheckFor(language, scenario, featureID string) string {
	if scenario != "base" {
		for _, id := range labVariantClaims[scenario] {
			if id == featureID {
				return "scenario/" + scenario
			}
		}
		return ""
	}
	for check, ids := range labClaimsByCheck[language] {
		for _, id := range ids {
			if id == featureID {
				return check
			}
		}
	}
	return ""
}

var labVariantClaims = map[string][]string{
	"default-service":   {"resource.default-value-for-service-name"},
	"disabled":          {"environment-variables.otel-sdk-disabled"},
	"sampler-off":       {"environment-variables.otel-traces-sampler"},
	"sampler-arg-zero":  {"environment-variables.otel-traces-sampler-arg"},
	"sampler-arg-one":   {}, // Positive control for sampler-arg-zero.
	"log-length-edge":   {}, // Regression for SDK byte and string-conversion limit gaps.
	"ot-baggage-hyphen": {}, // Regression for OpenTracing header-name filtering.
	"otlp-retry-after":  {}, // Regression for Go OTLP HTTP Retry-After units.
	"log-count":         {"environment-variables.otel-logrecord-attribute-count-limit"},
	"log-length":        {"environment-variables.otel-logrecord-attribute-value-length-limit"},
	"exemplars-off":     {"environment-variables.otel-metrics-exemplar-filter"},
	"histogram-exponential": {
		"environment-variables.otel-exporter-otlp-metrics-default-histogram-aggregation",
		"exporters.otlp.metric-exporter-configurable-default-aggregation",
	},
	"resource-attributes": {
		"environment-variables.otel-resource-attributes",
	},
	"span-events": {
		"traces.span.events-collection-size-limit",
		"environment-variables.otel-span-event-count-limit",
	},
	"event-attributes": {
		"environment-variables.otel-event-attribute-count-limit",
	},
	"attribute-count": {
		"environment-variables.otel-attribute-count-limit",
	},
	"span-value-length": {
		"environment-variables.otel-span-attribute-value-length-limit",
	},
	"attribute-value-length": {
		"environment-variables.otel-attribute-value-length-limit",
	},
	"links-count": {
		"traces.span.links-collection-size-limit",
		"environment-variables.otel-span-link-count-limit",
	},
	"link-attributes": {
		"environment-variables.otel-link-attribute-count-limit",
	},
}
