package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

type sinkRecord struct {
	Signal   string          `json:"signal"`
	Encoding string          `json:"encoding"`
	Request  sinkRequest     `json:"request"`
	Payload  json.RawMessage `json:"payload"`
}

type sinkRequest struct {
	Path    string       `json:"path"`
	Headers []sinkHeader `json:"headers"`
}

type sinkHeader struct {
	Name  string `json:"name"`
	Value string `json:"value"`
}

func main() {
	serviceSuffix := flag.String("service-suffix", "", "suffix of the OTLP sink service label")
	flag.Parse()
	if *serviceSuffix == "" {
		fatal(errors.New("--service-suffix is required"))
	}
	port, err := assignedSinkPort(*serviceSuffix)
	if err != nil {
		fatal(err)
	}
	endpoint := fmt.Sprintf("http://127.0.0.1:%d", port)

	requests := []struct {
		signal      string
		contentType string
		body        []byte
		marker      string
	}{
		{"traces", "application/x-protobuf", []byte{0x0a, 0x00}, "trace-protobuf"},
		{"metrics", "application/json", []byte(`{"resourceMetrics":[{"schemaUrl":"probe-metric"}]}`), "metric-json"},
		{"logs", "application/json", []byte(`{"resourceLogs":[{"schemaUrl":"probe-log"}]}`), "log-json"},
	}
	for _, item := range requests {
		req, err := http.NewRequest(http.MethodPost, endpoint+"/v1/"+item.signal, bytes.NewReader(item.body))
		if err != nil {
			fatal(err)
		}
		req.Header.Set("Content-Type", item.contentType)
		req.Header.Set("X-Otel-Sink-Probe", item.marker)
		response, err := http.DefaultClient.Do(req)
		if err != nil {
			fatal(fmt.Errorf("send %s: %w", item.signal, err))
		}
		contents, readErr := io.ReadAll(response.Body)
		response.Body.Close()
		if readErr != nil {
			fatal(readErr)
		}
		if response.StatusCode != http.StatusOK {
			fatal(fmt.Errorf("send %s: HTTP %d: %s", item.signal, response.StatusCode, contents))
		}
	}

	response, err := http.Get(endpoint + "/dump")
	if err != nil {
		fatal(err)
	}
	defer response.Body.Close()
	var records []sinkRecord
	if err := json.NewDecoder(response.Body).Decode(&records); err != nil {
		fatal(fmt.Errorf("decode sink dump: %w", err))
	}
	if len(records) != len(requests) {
		fatal(fmt.Errorf("got %d records, want %d", len(records), len(requests)))
	}
	for index, item := range requests {
		record := records[index]
		if record.Signal != item.signal || record.Request.Path != "/v1/"+item.signal {
			fatal(fmt.Errorf("record %d routes %q to %q", index, record.Request.Path, record.Signal))
		}
		wantEncoding := "json"
		if strings.Contains(item.contentType, "protobuf") {
			wantEncoding = "protobuf"
		}
		if record.Encoding != wantEncoding {
			fatal(fmt.Errorf("record %d encoding is %q, want %q", index, record.Encoding, wantEncoding))
		}
		if !hasHeader(record.Request.Headers, "x-otel-sink-probe", item.marker) {
			fatal(fmt.Errorf("record %d did not preserve probe header", index))
		}
		if item.signal == "traces" && !bytes.Contains(record.Payload, []byte(`"resource_spans"`)) {
			fatal(fmt.Errorf("trace protobuf was not semantically decoded: %s", record.Payload))
		}
		if item.signal != "traces" && !bytes.Contains(record.Payload, []byte("probe-")) {
			fatal(fmt.Errorf("JSON payload was not preserved: %s", record.Payload))
		}
	}
	fmt.Printf("OTLP sink accepted and described traces, metrics, and logs at %s\n", endpoint)
}

func hasHeader(headers []sinkHeader, name, value string) bool {
	for _, header := range headers {
		if header.Name == name && header.Value == value {
			return true
		}
	}
	return false
}

func assignedSinkPort(serviceSuffix string) (int, error) {
	var ports map[string]json.RawMessage
	if err := json.Unmarshal([]byte(os.Getenv("ASSIGNED_PORTS")), &ports); err != nil {
		return 0, fmt.Errorf("decode ASSIGNED_PORTS: %w", err)
	}
	for label, encoded := range ports {
		if !strings.HasSuffix(label, serviceSuffix) {
			continue
		}
		var port int
		if err := json.Unmarshal(encoded, &port); err == nil {
			return port, nil
		}
		var value string
		if err := json.Unmarshal(encoded, &value); err != nil {
			return 0, err
		}
		return strconv.Atoi(value)
	}
	return 0, fmt.Errorf("service ending in %q is absent from ASSIGNED_PORTS", serviceSuffix)
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, "otel_sink_probe:", err)
	time.Sleep(10 * time.Millisecond)
	os.Exit(1)
}
