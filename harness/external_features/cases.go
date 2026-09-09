package main

// These experiments exercise SDKs through application HTTP and captured OTLP.
// Each prerequisite is checked against the same workload without the setting:
// absence alone is never evidence that a limit or disable switch worked.
type experiment struct {
	Name     string
	Env      map[string]string
	Features []string
}

var samplerArgumentControl = experiment{Name: "sampler-arg-control", Env: map[string]string{"OTEL_TRACES_SAMPLER": "traceidratio", "OTEL_TRACES_SAMPLER_ARG": "1"}}

var experimentControls = map[string]experiment{
	"sampler-arg":         samplerArgumentControl,
	"log-batch":           {Name: "log-batch-control", Env: map[string]string{"OTEL_BLRP_SCHEDULE_DELAY": "1000", "OTEL_BLRP_MAX_EXPORT_BATCH_SIZE": "512"}},
	"exemplars-always-on": {Name: "exemplars-always-on-control", Env: map[string]string{"OTEL_TRACES_SAMPLER": "always_off", "OTEL_METRICS_EXEMPLAR_FILTER": "trace_based"}},
}

var experiments = []experiment{
	{"default-service", map[string]string{"OTEL_SERVICE_NAME": ""}, []string{"resource.default-value-for-service-name"}},
	{"span-batch", map[string]string{"OTEL_BSP_MAX_EXPORT_BATCH_SIZE": "1"}, []string{"environment-variables.otel-bsp"}},
	{"log-batch", map[string]string{"OTEL_BLRP_SCHEDULE_DELAY": "1000", "OTEL_BLRP_MAX_EXPORT_BATCH_SIZE": "1"}, []string{"environment-variables.otel-blrp"}},
	{"exemplars-always-on", map[string]string{"OTEL_TRACES_SAMPLER": "always_off", "OTEL_METRICS_EXEMPLAR_FILTER": "always_on"}, []string{"metrics.the-metrics-sdk-supports-alwayson-exemplar-filter"}},
	{"request-headers", map[string]string{"OTEL_INSTRUMENTATION_HTTP_CAPTURE_HEADERS_SERVER_REQUEST": "x-probe-feature"}, []string{"traces.span-attributes.array-of-primitives-homogeneous"}},
	// This exercises an already-covered feature with a negative propagation
	// setting; it deliberately contributes no additional feature ID.
	{"propagation-none", map[string]string{"OTEL_PROPAGATORS": "none"}, nil},
	{"resource", map[string]string{"OTEL_RESOURCE_ATTRIBUTES": "probe.external=visible,service.name=shadowed"}, []string{"environment-variables.otel-resource-attributes"}},
	{"disabled", map[string]string{"OTEL_SDK_DISABLED": "true"}, []string{"environment-variables.otel-sdk-disabled"}},
	{"sampler", map[string]string{"OTEL_TRACES_SAMPLER": "always_off"}, []string{"environment-variables.otel-traces-sampler"}},
	{"sampler-arg", map[string]string{"OTEL_TRACES_SAMPLER": "traceidratio", "OTEL_TRACES_SAMPLER_ARG": "0"}, []string{"environment-variables.otel-traces-sampler-arg"}},
	{"span-length", map[string]string{"OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT": "8"}, []string{"environment-variables.otel-span-attribute-value-length-limit"}},
	{"attribute-length", map[string]string{"OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT": "8"}, []string{"environment-variables.otel-attribute-value-length-limit"}},
	{"attribute-count", map[string]string{"OTEL_ATTRIBUTE_COUNT_LIMIT": "2"}, []string{"environment-variables.otel-attribute-count-limit"}},
	{"events", map[string]string{"OTEL_SPAN_EVENT_COUNT_LIMIT": "0"}, []string{"environment-variables.otel-span-event-count-limit", "traces.span.events-collection-size-limit"}},
	{"event-attributes", map[string]string{"OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT": "1"}, []string{"environment-variables.otel-event-attribute-count-limit"}},
	{"log-count", map[string]string{"OTEL_LOGRECORD_ATTRIBUTE_COUNT_LIMIT": "1"}, []string{"environment-variables.otel-logrecord-attribute-count-limit"}},
	{"log-length", map[string]string{"OTEL_LOGRECORD_ATTRIBUTE_VALUE_LENGTH_LIMIT": "8"}, []string{"environment-variables.otel-logrecord-attribute-value-length-limit"}},
	{"exemplars", map[string]string{"OTEL_METRICS_EXEMPLAR_FILTER": "always_off"}, []string{
		"environment-variables.otel-metrics-exemplar-filter",
		"metrics.exemplar-sampling-can-be-disabled",
		"metrics.the-metrics-sdk-supports-sdk-wide-exemplar-filter-configuration",
		"metrics.the-metrics-sdk-supports-alwaysoff-exemplar-filter",
	}},
	{"histogram", map[string]string{"OTEL_EXPORTER_OTLP_METRICS_DEFAULT_HISTOGRAM_AGGREGATION": "base2_exponential_bucket_histogram"}, []string{
		"environment-variables.otel-exporter-otlp-metrics-default-histogram-aggregation",
		"metrics.the-exponentialbuckethistogram-aggregation-is-available",
		"metrics.the-metrics-reader-implementation-supports-configuring-the-default-aggregation-on-the-basis-of-instrument-kind",
	}},
}
