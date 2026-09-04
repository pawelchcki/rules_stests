package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"sort"
	"strings"
	"unicode"

	"github.com/pawelchcki/rules_stests/report"
)

type registryEntry struct {
	ID       string `json:"id"`
	Binding  string `json:"binding"`
	Library  string `json:"library"`
	Category string `json:"category"`
}

var preferredBindings = map[string]string{
	"traces.tracerprovider.get-a-tracer":                               "tracer/get",
	"traces.tracerprovider.get-a-tracer-with-schema-url":               "tracer/get-with-schema-url",
	"traces.tracerprovider.associate-tracer-with-instrumentationscope": "tracer/scope-associated",
	"traces.tracer.create-a-new-span":                                  "span/create",
	"traces.span.create-root-span":                                     "span/create-root",
	"traces.span.create-with-default-parent-active-span":               "span/create-with-active-parent",
	"traces.span.create-with-parent-from-context":                      "span/create-with-context-parent",
	"traces.span.end":                                              "span/end",
	"traces.span-attributes.string-type":                           "span/string-attribute",
	"traces.span-attributes.signed-int64-type":                     "span/int64-attribute",
	"traces.span-exceptions.recordexception":                       "span/record-exception",
	"traces.span-exceptions.recordexception-with-extra-parameters": "span/record-exception-with-parameters",
	"metrics.meterprovider-provides-a-way-to-get-a-meter":          "meter/get",
	"metrics.get-meter-accepts-name-version-and-schema-url":        "meter/get-with-version-schema",
	"metrics.associate-meter-with-instrumentationscope":            "meter/scope-associated",
	"metrics.counter-instrument-is-supported":                      "metric/counter",
	"metrics.asynchronouscounter-instrument-is-supported":          "metric/async-counter",
	"metrics.histogram-instrument-is-supported":                    "metric/histogram",
	"metrics.asynchronousgauge-instrument-is-supported":            "metric/async-gauge",
	"metrics.updowncounter-instrument-is-supported":                "metric/up-down-counter",
	"metrics.asynchronousupdowncounter-instrument-is-supported":    "metric/async-up-down-counter",
	"metrics.instruments-have-name":                                "metric/instrument-name",
	"metrics.instruments-have-kind":                                "metric/instrument-kind",
	"metrics.instruments-have-an-optional-unit-of-measure":         "metric/instrument-unit",
	"metrics.instruments-have-an-optional-description":             "metric/instrument-description",
	"metrics.a-specified-resource-can-be-associated-with-all-the-produced-metrics-from-any-meter-from-the-meterprovider":                                             "metric/resource-associated",
	"metrics.the-supplied-name-version-and-schema-url-arguments-passed-to-the-meterprovider-are-used-to-create-an-instrumentationscope-instance-stored-in-the-meter": "meter/name-version-schema-stored",
	"metrics.the-sum-aggregation-is-available":                        "metric/sum-aggregation",
	"metrics.the-lastvalue-aggregation-is-available":                  "metric/last-value-aggregation",
	"metrics.the-explicitbuckethistogram-aggregation-is-available":    "metric/explicit-bucket-histogram-aggregation",
	"logs.loggerprovider-get-logger":                                  "logger/get",
	"logs.logger-emit-logrecord":                                      "logger/emit",
	"logs.otlp-http-exporter":                                         "log/otlp-http-exporter",
	"resource.create-from-attributes":                                 "resource/create-from-attributes",
	"resource.resource-detector-interface-mechanism":                  "resource/detector-interface",
	"resource.resource-detectors-populate-schema-url":                 "resource/detector-schema-url",
	"exporters.otlp.otlp-http-binary-protobuf-exporter":               "exporter/otlp-http-binary-protobuf",
	"traces.tracerprovider.create-tracerprovider":                     "tracer-provider/create",
	"traces.span-attributes.setattribute":                             "span/set-attribute",
	"traces.spancontext.isvalid":                                      "span-context/is-valid",
	"traces.spancontext.conforms-to-the-w3c-tracecontext-spec":        "span-context/w3c-conformant",
	"traces.sampling.idgenerators":                                    "sampling/id-generator",
	"traces.span.updatename":                                          "span/update-name",
	"traces.span.set-status-with-statuscode-unset-ok-error":           "span/set-status",
	"traces.span-events.addevent":                                     "span/add-event",
	"resource.retrieve-attributes":                                    "resource/retrieve-attributes",
	"metrics.gauge-instrument-is-supported":                           "metric/gauge",
	"metrics.meterprovider-allows-a-resource-to-be-specified":         "meter/resource-configurable",
	"metrics.the-default-aggregation-is-available":                    "metric/default-aggregation",
	"metrics.instrument-names-conform-to-the-specified-syntax":        "metric/instrument-name-syntax",
	"metrics.instrument-units-conform-to-the-specified-syntax":        "metric/instrument-unit-syntax",
	"metrics.instrument-descriptions-conform-to-the-specified-syntax": "metric/instrument-description-syntax",
	"logs.batchlogrecordprocessor":                                    "log/batch-processor",
	"exporters.otlp.honors-the-user-agent-spec":                       "exporter/otlp-user-agent",
	"exporters.otlp.schemaurl-in-resourcespans-and-scopespans":        "exporter/otlp-traces-schema-url",
	"exporters.otlp.schemaurl-in-resourcemetrics-and-scopemetrics":    "exporter/otlp-metrics-schema-url",
	"exporters.otlp.schemaurl-in-resourcelogs-and-scopelogs":          "exporter/otlp-logs-schema-url",
}

func main() {
	var matrixPath, metadataPath, schemePath, jsonPath string
	flag.StringVar(&matrixPath, "matrix", "", "pinned compliance matrix")
	flag.StringVar(&metadataPath, "metadata", "", "matrix metadata")
	flag.StringVar(&schemePath, "scheme-out", "", "generated Scheme standard libraries")
	flag.StringVar(&jsonPath, "json-out", "", "generated registry JSON")
	flag.Parse()
	if err := run(matrixPath, metadataPath, schemePath, jsonPath); err != nil {
		fmt.Fprintln(os.Stderr, "standard registry:", err)
		os.Exit(1)
	}
}

func run(matrixPath, metadataPath, schemePath, jsonPath string) error {
	matrix, err := os.ReadFile(matrixPath)
	if err != nil {
		return err
	}
	metadataBytes, err := os.ReadFile(metadataPath)
	if err != nil {
		return err
	}
	metadata, err := report.DecodeMetadata(metadataBytes)
	if err != nil {
		return err
	}
	if err := report.VerifyMatrixDigest(matrix, metadata.Source.SHA256); err != nil {
		return err
	}
	features, err := report.ImportMatrix(string(matrix), metadata.Source)
	if err != nil {
		return err
	}

	entries := make([]registryEntry, 0, len(features))
	bindings := map[string]string{}
	for _, feature := range features {
		binding := preferredBindings[feature.ID]
		if binding == "" {
			binding = slug(feature.Category) + "/" + strings.TrimPrefix(feature.ID, slug(feature.Category)+".")
		}
		if previous := bindings[binding]; previous != "" {
			return fmt.Errorf("binding %q aliases %q and %q", binding, previous, feature.ID)
		}
		bindings[binding] = feature.ID
		entries = append(entries, registryEntry{ID: feature.ID, Binding: binding, Library: slug(feature.Category), Category: feature.Category})
	}
	if len(entries) != 326 {
		return fmt.Errorf("matrix produced %d features, want 326", len(entries))
	}

	encoded, err := json.MarshalIndent(struct {
		SchemaVersion  int             `json:"schemaVersion"`
		MatrixRevision string          `json:"matrixRevision"`
		Features       []registryEntry `json:"features"`
	}{1, metadata.Source.Revision, entries}, "", "  ")
	if err != nil {
		return err
	}
	encoded = append(encoded, '\n')
	if err := os.WriteFile(jsonPath, encoded, 0o644); err != nil {
		return err
	}

	byLibrary := map[string][]registryEntry{}
	for _, entry := range entries {
		byLibrary[entry.Library] = append(byLibrary[entry.Library], entry)
	}
	libraries := make([]string, 0, len(byLibrary))
	for library := range byLibrary {
		libraries = append(libraries, library)
	}
	sort.Strings(libraries)
	var source strings.Builder
	for _, library := range libraries {
		items := byLibrary[library]
		source.WriteString("(define-library (otel standard " + library + ")\n  (export")
		for _, entry := range items {
			source.WriteString("\n    " + entry.Binding)
		}
		source.WriteString(")\n  (import (scheme base))\n  (begin\n")
		for _, entry := range items {
			fmt.Fprintf(&source, "(define %s %q)\n", entry.Binding, entry.ID)
		}
		source.WriteString("  ))\n")
	}
	return os.WriteFile(schemePath, []byte(source.String()), 0o644)
}

func slug(value string) string {
	var out strings.Builder
	dash := false
	for _, r := range strings.ToLower(value) {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			out.WriteRune(r)
			dash = false
		} else if out.Len() > 0 && !dash {
			out.WriteByte('-')
			dash = true
		}
	}
	return strings.Trim(out.String(), "-")
}
