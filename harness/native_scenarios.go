package main

// Consumer workloads use the existing service, intake, Scheme validator and
// receipt writer. No application code or Ruby evaluation is introduced here.
import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"
)

const nativeConnections = 8
const nativeRequestsPerConnection = 20

func nativeContext(index int) (uint64, uint64, uint64) {
	return 0x4bf92f3577b34da6, 0x8000000000000000 + uint64(index+1), 0xf067aa0ba902b7
}

func nativeReadResponse(reader *bufio.Reader, request *http.Request, status int) error {
	response, err := http.ReadResponse(reader, request)
	if err != nil {
		return err
	}
	_, readErr := io.Copy(io.Discard, response.Body)
	closeErr := response.Body.Close()
	if response.StatusCode != status {
		return fmt.Errorf("expected HTTP %d, received %d", status, response.StatusCode)
	}
	if readErr != nil {
		return readErr
	}
	return closeErr
}

func nativeDial(endpoint string) (net.Conn, error) {
	parsed, err := url.Parse(endpoint)
	if err != nil {
		return nil, err
	}
	connection, err := net.DialTimeout("tcp", parsed.Host, 10*time.Second)
	if err == nil {
		err = connection.SetDeadline(time.Now().Add(45 * time.Second))
	}
	return connection, err
}

func runNativeConcurrency(endpoint string) error {
	start := make(chan struct{})
	failures := make(chan error, nativeConnections)
	var ready sync.WaitGroup
	var done sync.WaitGroup
	ready.Add(nativeConnections)
	done.Add(nativeConnections)
	for worker := 0; worker < nativeConnections; worker++ {
		go func(worker int) {
			defer done.Done()
			connection, err := nativeDial(endpoint)
			ready.Done()
			if err != nil {
				failures <- err
				return
			}
			defer connection.Close()
			reader := bufio.NewReader(connection)
			<-start
			for step := 0; step < nativeRequestsPerConnection; step++ {
				index := worker*nativeRequestsPerConnection + step
				request, err := http.NewRequest("GET", endpoint+"/api/tags", nil)
				if err != nil {
					failures <- err
					return
				}
				high, low, parent := nativeContext(index)
				switch index % 4 {
				case 1:
					request.Header.Set("traceparent", "00-not-a-trace-id-not-a-parent-01")
					request.Header.Set("x-datadog-trace-id", "0")
					request.Header.Set("x-datadog-parent-id", "invalid")
				case 2:
					request.Header.Set("traceparent", fmt.Sprintf("00-%016x%016x-%016x-01", high, low, parent))
				case 3:
					request.Header.Set("x-datadog-trace-id", fmt.Sprint(low))
					request.Header.Set("x-datadog-parent-id", fmt.Sprint(parent))
					request.Header.Set("x-datadog-sampling-priority", "1")
					request.Header.Set("x-datadog-tags", fmt.Sprintf("_dd.p.tid=%016x", high))
				}
				if err = request.Write(connection); err == nil {
					err = nativeReadResponse(reader, request, 200)
				}
				if err != nil {
					failures <- fmt.Errorf("connection %d request %d: %w", worker, step, err)
					return
				}
			}
		}(worker)
	}
	ready.Wait()
	close(start)
	done.Wait()
	close(failures)
	for err := range failures {
		return err
	}
	return nil
}

func nativeRawExchange(endpoint, request string, fragment bool, statuses ...int) error {
	connection, err := nativeDial(endpoint)
	if err != nil {
		return err
	}
	defer connection.Close()
	if fragment {
		lineEnd := strings.Index(request, "\r\n")
		if lineEnd < 4 || !strings.HasSuffix(request, "\r\n\r\n") {
			return fmt.Errorf("invalid fragmented HTTP request")
		}
		// Leave the request line and then the header terminator incomplete
		// across server read opportunities.
		parts := []string{request[:4], request[4 : lineEnd+2], request[lineEnd+2 : len(request)-2], request[len(request)-2:]}
		for index, part := range parts {
			if _, err = io.WriteString(connection, part); err != nil {
				return err
			}
			if index+1 < len(parts) {
				time.Sleep(100 * time.Millisecond)
			}
		}
	} else if _, err = io.WriteString(connection, request); err != nil {
		return err
	}
	reader := bufio.NewReader(connection)
	for _, status := range statuses {
		if err = nativeReadResponse(reader, nil, status); err != nil {
			return err
		}
	}
	return nil
}

func runNativeMalformed(endpoint string) error {
	parsed, err := url.Parse(endpoint)
	if err != nil {
		return err
	}
	// Puma rejects malformed syntax before Rack. An otherwise valid header over
	// the socket parser's 4096-byte bound must still reach the unchanged app.
	malformed := "GET /api/tags HTTP/1.1\r\nHost: " + parsed.Host + "\r\nbad header\r\n\r\n"
	if err = nativeRawExchange(endpoint, malformed, false, 400); err != nil {
		return fmt.Errorf("malformed request: %w", err)
	}
	request := "GET /api/tags HTTP/1.1\r\nHost: " + parsed.Host + "\r\n\r\n"
	oversized := "GET /api/tags HTTP/1.1\r\nHost: " + parsed.Host + "\r\nX-Native-Padding: " + strings.Repeat("a", 5000) + "\r\n\r\n"
	if err = nativeRawExchange(endpoint, oversized, false, 200); err != nil {
		return fmt.Errorf("oversized request: %w", err)
	}
	if err = nativeRawExchange(endpoint, request, true, 200); err != nil {
		return fmt.Errorf("fragmented request: %w", err)
	}
	return nativeRawExchange(endpoint, request+request, false, 200, 200)
}

func runNativeExceptions(endpoint string) error {
	connection, err := nativeDial(endpoint)
	if err != nil {
		return err
	}
	defer connection.Close()
	reader := bufio.NewReader(connection)
	request, err := http.NewRequest("POST", endpoint+"/api/users", strings.NewReader(`{"user":"not-an-object"}`))
	if err != nil {
		return err
	}
	request.Header.Set("Content-Type", "application/json")
	if err = request.Write(connection); err != nil {
		return err
	}
	if err = nativeReadResponse(reader, request, 500); err != nil {
		return err
	}
	request, err = http.NewRequest("GET", endpoint+"/api/tags", nil)
	if err != nil {
		return err
	}
	if err = request.Write(connection); err != nil {
		return err
	}
	return nativeReadResponse(reader, request, 200)
}

func runNativeWorkload(scenario, client, endpoint, agentURL string) error {
	switch scenario {
	case "native_concurrency":
		return runNativeConcurrency(endpoint)
	case "native_malformed":
		return runNativeMalformed(endpoint)
	case "native_exceptions":
		return runNativeExceptions(endpoint)
	case "native_ruby_client":
		if client == "" {
			return fmt.Errorf("native Ruby client executable is required")
		}
		executable, err := resolvePath(client, false)
		if err != nil {
			return err
		}
		command := exec.Command(executable)
		command.Env = append(os.Environ(), "DD_TRACE_AGENT_URL="+agentURL)
		command.Stdout, command.Stderr = os.Stdout, os.Stderr
		return command.Run()
	default:
		return fmt.Errorf("unknown native scenario %q", scenario)
	}
}

type nativeCapturedSpan struct {
	TraceID  uint64            `json:"trace_id"`
	SpanID   uint64            `json:"span_id"`
	ParentID uint64            `json:"parent_id"`
	Name     string            `json:"name"`
	Type     string            `json:"type"`
	Error    int               `json:"error"`
	Meta     map[string]string `json:"meta"`
}

func validateNativeScenario(profile atomicProfile, capture []byte) error {
	if !strings.HasPrefix(profile.Scenario, "native_") {
		return nil
	}
	var records []struct {
		Payload struct {
			Traces [][]nativeCapturedSpan `json:"traces"`
		} `json:"payload"`
	}
	if err := json.Unmarshal(capture, &records); err != nil {
		return err
	}
	byID := map[uint64]nativeCapturedSpan{}
	servers := map[uint64]nativeCapturedSpan{}
	for _, record := range records {
		for _, trace := range record.Payload.Traces {
			for _, span := range trace {
				if span.SpanID == 0 || span.TraceID == 0 {
					return fmt.Errorf("native workload: zero identity")
				}
				if _, found := byID[span.SpanID]; found {
					return fmt.Errorf("native workload: duplicate completion")
				}
				byID[span.SpanID] = span
				if span.Name == "rack.request" {
					if _, found := servers[span.TraceID]; found {
						return fmt.Errorf("native workload: requests share a trace")
					}
					servers[span.TraceID] = span
				}
			}
		}
	}
	expected := map[string]int{"native_concurrency": 160, "native_malformed": 4, "native_exceptions": 2}
	if count, ok := expected[profile.Scenario]; ok && len(servers) != count {
		return fmt.Errorf("%s: got %d Rack spans, want %d", profile.Scenario, len(servers), count)
	}
	controllers := map[uint64]int{}
	queries := map[uint64]int{}
	for _, span := range byID {
		if span.Name == "rack.request" || (profile.Scenario == "native_ruby_client" && span.Name == "ruby.http.fixture") {
			continue
		}
		parent, found := byID[span.ParentID]
		if !found || parent.TraceID != span.TraceID || (span.Meta["_dd.p.tid"] != "" && parent.Meta["_dd.p.tid"] != span.Meta["_dd.p.tid"]) {
			return fmt.Errorf("native workload: missing or foreign parent for %s", span.Name)
		}
		switch span.Name {
		case "rails.action_controller":
			if parent.Name != "rack.request" {
				return fmt.Errorf("controller must be a direct Rack child")
			}
			controllers[span.TraceID]++
		case "sqlite.query":
			if parent.Name != "rails.action_controller" && parent.Name != "sqlite.query" {
				return fmt.Errorf("SQL must descend from controller")
			}
			queries[span.TraceID]++
		default:
			if profile.Scenario != "native_ruby_client" && span.Name != "active_record.instantiation" {
				return fmt.Errorf("unexpected native span %q", span.Name)
			}
		}
	}
	for traceID, server := range servers {
		if controllers[traceID] != 1 {
			return fmt.Errorf("request requires exactly one controller")
		}
		if server.Meta["http.status_code"] == "200" && queries[traceID] == 0 {
			return fmt.Errorf("successful request is missing SQL coverage")
		}
	}
	if profile.Scenario == "native_concurrency" {
		external := map[uint64]int{}
		for index := 0; index < 160; index++ {
			if index%4 >= 2 {
				_, low, _ := nativeContext(index)
				external[low] = index
			}
		}
		roots := 0
		for traceID, server := range servers {
			if server.Error != 0 || server.Meta["http.status_code"] != "200" {
				return fmt.Errorf("concurrency request failed")
			}
			if index, found := external[traceID]; found {
				high, _, parent := nativeContext(index)
				if server.ParentID != parent || server.Meta["_dd.p.tid"] != fmt.Sprintf("%016x", high) {
					return fmt.Errorf("lost 128-bit propagation for request %d", index)
				}
				delete(external, traceID)
			} else {
				roots++
				if server.ParentID != 0 {
					return fmt.Errorf("absent/invalid context inherited another request")
				}
			}
		}
		if roots != 80 || len(external) != 0 {
			return fmt.Errorf("incorrect propagated vs independent request inventory")
		}
	}
	if profile.Scenario == "native_exceptions" {
		failed, clean, detailed := 0, 0, 0
		for _, span := range byID {
			if span.Name == "rack.request" {
				if span.ParentID != 0 {
					return fmt.Errorf("exception request leaked context")
				}
				if span.Meta["http.status_code"] == "500" && span.Error == 1 {
					failed++
				}
				if span.Meta["http.status_code"] == "200" && span.Error == 0 {
					clean++
				}
			}
			if span.Name == "rails.action_controller" && span.Error == 1 && span.Meta["error.type"] == "NoMethodError" && span.Meta["error.message"] != "" && span.Meta["error.stack"] != "" {
				detailed++
			}
		}
		if failed != 1 || clean != 1 || detailed != 1 {
			return fmt.Errorf("exception classification/details or context cleanup mismatch")
		}
	}
	if profile.Scenario == "native_ruby_client" {
		roots, clients, successes, failures := 0, 0, 0, 0
		var root nativeCapturedSpan
		for _, span := range byID {
			if span.Name == "ruby.http.fixture" && span.ParentID == 0 {
				roots++
				root = span
			}
		}
		if roots != 1 || len(byID) != 4 || len(servers) != 0 {
			return fmt.Errorf("Ruby client expected one fixture root and three HTTP clients")
		}
		for _, span := range byID {
			if span.Name == "ruby.http.fixture" {
				continue
			}
			if span.Name != "http.request" || span.Type != "http" || span.ParentID != root.SpanID || span.TraceID != root.TraceID || span.Meta["span.kind"] != "client" {
				return fmt.Errorf("invalid Ruby HTTP client ancestry or identity")
			}
			clients++
			if span.Meta["http.method"] == "GET" && span.Meta["http.status_code"] == "200" && span.Error == 0 {
				successes++
			}
			if span.Meta["http.method"] == "POST" && span.Meta["http.status_code"] == "503" && span.Error == 1 {
				failures++
			}
		}
		if err := validateNativeWire(byID, root); err != nil {
			return err
		}
		if clients != 3 || successes != 2 || failures != 1 {
			return fmt.Errorf("Ruby client response/error inventory mismatch")
		}
	}

	return nil
}

func readNativeWire() ([]byte, error) {
	root := os.Getenv("TEST_UNDECLARED_OUTPUTS_DIR")
	if root == "" {
		return nil, fmt.Errorf("Ruby client wire evidence output directory is missing")
	}
	return os.ReadFile(filepath.Join(root, "native-client-wire.json"))
}

func validateNativeWire(spans map[uint64]nativeCapturedSpan, root nativeCapturedSpan) error {
	data, err := readNativeWire()
	if err != nil {
		return err
	}
	var wire []struct {
		Method        string `json:"method"`
		Traceparent   string `json:"traceparent"`
		DatadogParent string `json:"datadog_parent"`
		DatadogTrace  string `json:"datadog_trace"`
		DatadogTags   string `json:"datadog_tags"`
	}
	if err := json.Unmarshal(data, &wire); err != nil {
		return err
	}
	if len(wire) != 3 {
		return fmt.Errorf("expected three downstream propagation records")
	}
	seen := map[uint64]bool{}
	high := root.Meta["_dd.p.tid"]
	if high == "" {
		high = "0000000000000000"
	}
	for _, request := range wire {
		parent, err := strconv.ParseUint(request.DatadogParent, 10, 64)
		if err != nil {
			return err
		}
		trace, err := strconv.ParseUint(request.DatadogTrace, 10, 64)
		if err != nil {
			return err
		}
		span, found := spans[parent]
		if !found || seen[parent] || span.Name != "http.request" || trace != span.TraceID || request.Method != span.Meta["http.method"] {
			return fmt.Errorf("downstream Datadog headers do not match captured HTTP client")
		}
		expected := fmt.Sprintf("00-%s%016x-%016x-01", high, trace, parent)
		if request.Traceparent != expected || !nativeHasTraceIDHigh(request.DatadogTags, high) {
			return fmt.Errorf("downstream propagation lost client span or 128-bit trace identity")
		}
		seen[parent] = true
	}
	return nil
}

func nativeHasTraceIDHigh(tags, high string) bool {
	for _, tag := range strings.Split(tags, ",") {
		key, value, found := strings.Cut(tag, "=")
		if found && key == "_dd.p.tid" && value == high {
			return true
		}
	}
	return false
}
