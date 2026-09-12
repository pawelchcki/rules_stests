package main

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
)

const maxStressRequests = 10000

type requestLedger struct {
	Execution string            `json:"execution"`
	Scenario  string            `json:"scenario"`
	Sequence  int               `json:"sequence"`
	ID        string            `json:"id"`
	Method    string            `json:"method"`
	Path      string            `json:"path"`
	Status    int               `json:"status"`
	SQLCount  int               `json:"sqlCount"`
	SQLMarker string            `json:"sqlMarker"`
	Incoming  map[string]string `json:"incoming"`
	Start     int64             `json:"startUnixNano"`
	End       int64             `json:"endUnixNano"`
}

type stressSpan struct {
	TraceID  uint64            `json:"trace_id"`
	SpanID   uint64            `json:"span_id"`
	ParentID uint64            `json:"parent_id"`
	Start    int64             `json:"start"`
	Duration int64             `json:"duration"`
	Service  string            `json:"service"`
	Name     string            `json:"name"`
	Resource string            `json:"resource"`
	Type     string            `json:"type"`
	Error    int               `json:"error"`
	Meta     map[string]string `json:"meta"`
}
type stressIdentity struct {
	Low  uint64
	High string
	Span uint64
}

func randomIdentifier() string {
	var value [16]byte
	if _, err := rand.Read(value[:]); err != nil {
		panic(err)
	}
	return hex.EncodeToString(value[:])
}

func isDatadogServer(name string) bool {
	return name == "aiohttp.request" || name == "django.request" || name == "rack.request" || name == "gin.request" || name == "http.request"
}

// All ownership comparisons use the full 128-bit trace identity. A chunk's
// high bits apply to its children even when only the root carries the tag.
// Untagged chunks inherit high bits only through unambiguous span/parent links;
// equal low trace bits alone never join chunks.
func stressIndex(capture []byte) (map[stressIdentity]stressSpan, error) {
	var records []struct {
		Payload struct {
			Traces [][]stressSpan `json:"traces"`
		} `json:"payload"`
	}
	if err := json.Unmarshal(capture, &records); err != nil {
		return nil, err
	}
	type intakeChunk struct {
		spans  []stressSpan
		high   string
		tagged bool
	}
	var chunks []intakeChunk
	for _, record := range records {
		for _, spans := range record.Payload.Traces {
			chunk := intakeChunk{spans: spans, high: "0000000000000000"}
			for _, span := range spans {
				if span.TraceID == 0 || span.SpanID == 0 || span.Start <= 0 || span.Duration <= 0 {
					return nil, fmt.Errorf("invalid native span identity/timing")
				}
				if span.TraceID != spans[0].TraceID {
					return nil, fmt.Errorf("conflicting chunk trace identity")
				}
				if value := span.Meta["_dd.p.tid"]; value != "" {
					if len(value) != 16 || !allASCIIHex(value) {
						return nil, fmt.Errorf("malformed full trace identifier")
					}
					value = strings.ToLower(value)
					if chunk.tagged && chunk.high != value {
						return nil, fmt.Errorf("conflicting chunk trace identity")
					}
					chunk.high, chunk.tagged = value, true
				}
			}
			chunks = append(chunks, chunk)
		}
	}
	// Components connect chunks through actual span identities and parent
	// references. Indexed component joins avoid pairwise
	// comparisons when many independent traces reuse the same span IDs.
	components := make([]int, len(chunks))
	for i := range components {
		components[i] = i
	}
	find := func(i int) int {
		for components[i] != i {
			components[i] = components[components[i]]
			i = components[i]
		}
		return i
	}
	join := func(a, b int) {
		components[find(a)] = find(b)
	}
	type nativeID struct{ low, span uint64 }
	bySpan := map[nativeID]int{}
	for i, chunk := range chunks {
		for _, span := range chunk.spans {
			key := nativeID{span.TraceID, span.SpanID}
			if other, ok := bySpan[key]; ok {
				join(i, other)
			} else {
				bySpan[key] = i
			}
		}
	}
	for i, chunk := range chunks {
		for _, span := range chunk.spans {
			if other, ok := bySpan[nativeID{span.TraceID, span.ParentID}]; ok {
				join(i, other)
			}
		}
	}
	highs := map[int]map[string]bool{}
	for i, chunk := range chunks {
		if chunk.tagged {
			component := find(i)
			if highs[component] == nil {
				highs[component] = map[string]bool{}
			}
			highs[component][chunk.high] = true
		}
	}
	result := map[stressIdentity]stressSpan{}
	for i, chunk := range chunks {
		if !chunk.tagged {
			candidates := highs[find(i)]
			if len(candidates) > 1 {
				return nil, fmt.Errorf("ambiguous untagged chunk trace identity")
			}
			for high := range candidates {
				chunk.high = high
			}
		}
		for _, span := range chunk.spans {
			key := stressIdentity{span.TraceID, chunk.high, span.SpanID}
			if _, ok := result[key]; ok {
				return nil, fmt.Errorf("duplicate native span identity")
			}
			result[key] = span
		}
	}
	return result, nil
}

func validateStress(capture []byte, ledger []requestLedger, service string) error {
	spans, err := stressIndex(capture)
	if err != nil {
		return err
	}
	requests := map[string]requestLedger{}
	sequences := map[string]map[int]bool{}
	for _, request := range ledger {
		if request.SQLCount < 0 || request.ID == "" || request.SQLMarker == "" || request.Status < 100 || request.End <= request.Start {
			return fmt.Errorf("incomplete request ledger")
		}
		if _, ok := requests[request.ID]; ok {
			return fmt.Errorf("duplicate request ledger identity")
		}
		requests[request.ID] = request
		if sequences[request.Execution] == nil {
			sequences[request.Execution] = map[int]bool{}
		}
		if sequences[request.Execution][request.Sequence] {
			return fmt.Errorf("duplicate request sequence")
		}
		sequences[request.Execution][request.Sequence] = true
	}
	for _, seq := range sequences {
		for i := 1; i <= len(seq); i++ {
			if !seq[i] {
				return fmt.Errorf("missing request sequence")
			}
		}
	}
	servers := map[string]stressIdentity{}
	for key, span := range spans {
		if !isDatadogServer(span.Name) {
			continue
		}
		if _, captured := spans[stressIdentity{key.Low, key.High, span.ParentID}]; captured {
			return fmt.Errorf("workload server parent belongs to capture")
		}
		id := span.Meta["rules_stests.request_id"]
		request, ok := requests[id]
		if !ok {
			return fmt.Errorf("unexpected workload server span %q", id)
		}
		if _, ok := servers[id]; ok {
			return fmt.Errorf("duplicate server span for request")
		}
		servers[id] = key
		if span.Type != "web" || span.Service != service || span.Meta["http.method"] != request.Method || span.Meta["http.status_code"] != strconv.Itoa(request.Status) {
			return fmt.Errorf("server metadata differs from request ledger")
		}
		expectedError := 0
		if request.Status >= 500 {
			expectedError = 1
		}
		if span.Error != expectedError {
			return fmt.Errorf("wrong HTTP error classification")
		}
		path := span.Meta["http.url"]
		if path != "" {
			parsed, err := url.Parse(path)
			if err != nil || parsed.Path != strings.SplitN(request.Path, "?", 2)[0] {
				return fmt.Errorf("server path differs from ledger")
			}
		}
		if remote := request.Incoming["traceparent"]; remote != "" {
			parts := strings.Split(remote, "-")
			if len(parts) != 4 || parts[0] != "00" || len(parts[1]) != 32 || len(parts[2]) != 16 || len(parts[3]) != 2 {
				return fmt.Errorf("malformed incoming context")
			}
			low, lowErr := strconv.ParseUint(parts[1][16:], 16, 64)
			high, highErr := strconv.ParseUint(parts[1][:16], 16, 64)
			parent, parentErr := strconv.ParseUint(parts[2], 16, 64)
			_, flagsErr := strconv.ParseUint(parts[3], 16, 8)
			if lowErr != nil || highErr != nil || parentErr != nil || flagsErr != nil || (low == 0 && high == 0) || parent == 0 {
				return fmt.Errorf("malformed incoming context")
			}
			if key.Low != low || key.High != parts[1][:16] || span.ParentID != parent {
				return fmt.Errorf("wrong propagated full trace identity or parent")
			}
		} else if remote := request.Incoming["x-datadog-trace-id"]; remote != "" {
			low, lowErr := strconv.ParseUint(remote, 10, 64)
			parent, parentErr := strconv.ParseUint(request.Incoming["x-datadog-parent-id"], 10, 64)
			if lowErr != nil || parentErr != nil || low == 0 || parent == 0 {
				return fmt.Errorf("malformed incoming Datadog context")
			}
			if key.Low != low || span.ParentID != parent || request.Incoming["x-datadog-tags"] != "_dd.p.tid="+key.High {
				return fmt.Errorf("wrong Datadog caller identity")
			}
		} else if span.ParentID != 0 {
			return fmt.Errorf("unexpected server parent")
		}
	}
	if len(servers) != len(requests) || len(requests) == 0 {
		return fmt.Errorf("missing workload server requests: captured %d, ledger %d", len(servers), len(requests))
	}
	owners := map[stressIdentity]string{}
	var owner func(stressIdentity, map[stressIdentity]bool) (string, error)
	owner = func(key stressIdentity, visiting map[stressIdentity]bool) (string, error) {
		if value := owners[key]; value != "" {
			return value, nil
		}
		if visiting[key] || len(visiting) > 64 {
			return "", fmt.Errorf("cyclic/deep workload graph")
		}
		visiting[key] = true
		defer delete(visiting, key)
		span, ok := spans[key]
		if !ok {
			return "", fmt.Errorf("missing parent span")
		}
		if isDatadogServer(span.Name) {
			id := span.Meta["rules_stests.request_id"]
			owners[key] = id
			return id, nil
		}
		if span.ParentID == 0 {
			return "", fmt.Errorf("unexpected workload root")
		}
		parent := stressIdentity{key.Low, key.High, span.ParentID}
		id, err := owner(parent, visiting)
		if err == nil {
			owners[key] = id
		}
		return id, err
	}
	sqlCounts := map[string]int{}
	for key, span := range spans {
		id, err := owner(key, map[stressIdentity]bool{})
		if err != nil {
			return err
		}
		if span.Type == "sql" {
			sqlCounts[id]++
			request := requests[id]
			marker := "/* rules_stests_request=" + id + "; marker=" + request.SQLMarker + " */"
			lifecycle := span.Name == "sqlite3.query" && span.Meta["component"] == "database/sql" &&
				(span.Resource == "Begin" || span.Resource == "Commit" || span.Resource == "Rollback") && span.Meta["sql.query_type"] == span.Resource
			if lifecycle {
				// Driver transaction methods have no SQL text. Their independent
				// request marker is injected through the SDK context before tracing.
				if span.Meta["rules_stests.request_id"] != id || span.Meta["rules_stests.sql_marker"] != request.SQLMarker {
					return fmt.Errorf("crossed or missing SQL lifecycle marker")
				}
			} else if strings.Count(span.Resource, "rules_stests_request=") != 1 || !strings.Contains(span.Resource, marker) {
				return fmt.Errorf("crossed or missing SQL request marker")
			}
		}
	}
	for id, request := range requests {
		if sqlCounts[id] != request.SQLCount {
			return fmt.Errorf("lost or extra SQL spans: request %s executed %d queries, captured %d", id, request.SQLCount, sqlCounts[id])
		}
	}
	var intervals [][2]int64
	for _, key := range servers {
		span := spans[key]
		intervals = append(intervals, [2]int64{span.Start, span.Start + span.Duration})
	}
	if overlap(intervals) < 2 {
		return fmt.Errorf("native server spans do not overlap")
	}
	return nil
}

func overlap(intervals [][2]int64) int {
	type event struct {
		at    int64
		delta int
	}
	var events []event
	for _, interval := range intervals {
		events = append(events, event{interval[0], 1}, event{interval[1], -1})
	}
	sort.Slice(events, func(i, j int) bool {
		if events[i].at == events[j].at {
			return events[i].delta < events[j].delta
		}
		return events[i].at < events[j].at
	})
	active, peak := 0, 0
	for _, event := range events {
		active += event.delta
		if active > peak {
			peak = active
		}
	}
	return peak
}

func runParallelScenarios(endpoint, rootfs string, specs []string, manifest, sinkSuffix string, concurrency, repetitions int) error {
	if concurrency < 2 || concurrency > 128 || repetitions < 1 || repetitions > 20 {
		return fmt.Errorf("stress requires 2..128 workers and 1..20 repetitions")
	}
	data, err := os.ReadFile(mustResolve(manifest))
	if err != nil {
		return err
	}
	var declaration atomicProfileManifest
	if err = json.Unmarshal(data, &declaration); err != nil {
		return err
	}
	if declaration.Family != "datadog" {
		return fmt.Errorf("parallel trace isolation requires a Datadog profile")
	}
	if len(specs) != len(declaration.Scenarios) {
		return fmt.Errorf("parallel workload must contain every declared scenario")
	}
	allowed := map[string]bool{}
	for _, name := range declaration.Scenarios {
		allowed[name] = true
	}
	for _, spec := range specs {
		name := strings.TrimSuffix(filepath.Base(spec), ".hurl")
		if !allowed[name] {
			return fmt.Errorf("unexpected or duplicate scenario")
		}
		delete(allowed, name)
	}
	if err = resetStartupTelemetry(sinkSuffix, map[string]bool{"traces": true}, "datadog"); err != nil {
		return err
	}
	sinkPort, err := assignedPort(sinkSuffix)
	if err != nil {
		return err
	}
	sink := fmt.Sprintf("http://127.0.0.1:%d", sinkPort)
	destination, err := url.Parse(endpoint)
	if err != nil {
		return err
	}
	var mutex sync.Mutex
	var ledger []*requestLedger
	sequences := map[string]int{}
	executionNames := map[string]string{}
	proxy := httputil.NewSingleHostReverseProxy(destination)
	proxy.ModifyResponse = func(response *http.Response) error {
		id := response.Request.Header.Get("X-Rules-Stests-Request-Id")
		mutex.Lock()
		defer mutex.Unlock()
		for _, entry := range ledger {
			if entry.ID == id {
				entry.Status = response.StatusCode
				entry.SQLMarker = response.Header.Get("X-Rules-Stests-Sql-Marker")
				count, err := strconv.Atoi(response.Header.Get("X-Rules-Stests-Sql-Count"))
				if err != nil {
					count = -1
				}
				entry.SQLCount = count
				entry.End = time.Now().UnixNano()
				break
			}
		}
		return nil
	}
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		execution, path, ok := strings.Cut(strings.TrimPrefix(r.URL.Path, "/"), "/")
		if !ok {
			http.Error(w, "execution required", 400)
			return
		}
		mutex.Lock()
		name, exists := executionNames[execution]
		if !exists || len(ledger) >= maxStressRequests {
			mutex.Unlock()
			http.Error(w, "unknown execution or ledger overflow", 507)
			return
		}
		sequences[execution]++
		sequence := sequences[execution]
		entry := &requestLedger{Execution: execution, Scenario: name, Sequence: sequence, ID: randomIdentifier(), Method: r.Method, Path: "/" + path, Start: time.Now().UnixNano(), Incoming: map[string]string{}}
		if r.URL.RawQuery != "" {
			entry.Path += "?" + r.URL.RawQuery
		}
		// Deliberately reuse low bits across executions, while giving each request
		// independent high bits and caller span IDs. Never inject into plain cases.
		high := entry.ID[:16]
		parent := entry.ID[16:]
		if r.Header.Get("Traceparent") != "" {
			r.Header.Set("Traceparent", "00-"+high+"00000000075bcd15-"+parent+"-01")
		}
		if r.Header.Get("X-Datadog-Trace-Id") != "" {
			p, _ := strconv.ParseUint(parent, 16, 64)
			r.Header.Set("X-Datadog-Trace-Id", "123456789")
			r.Header.Set("X-Datadog-Parent-Id", strconv.FormatUint(p, 10))
			r.Header.Set("X-Datadog-Tags", "_dd.p.tid="+high)
		}
		for _, key := range []string{"traceparent", "tracestate", "x-datadog-trace-id", "x-datadog-parent-id", "x-datadog-tags", "x-datadog-sampling-priority"} {
			if value := r.Header.Get(key); value != "" {
				entry.Incoming[key] = value
			}
		}
		ledger = append(ledger, entry)
		mutex.Unlock()
		r.Header.Set("X-Rules-Stests-Request-Id", entry.ID)
		r.URL.Path = "/" + path
		r.URL.RawPath = ""
		r.Host = destination.Host
		proxy.ServeHTTP(w, r)
	})
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return err
	}
	server := &http.Server{Handler: handler, ReadHeaderTimeout: 5 * time.Second}
	defer server.Close()
	go server.Serve(listener)
	type execution struct{ id, spec, name string }
	var jobs []execution
	for repeat := 0; repeat < repetitions; repeat++ {
		for _, spec := range specs {
			id := randomIdentifier()
			name := strings.TrimSuffix(filepath.Base(spec), ".hurl")
			jobs = append(jobs, execution{id, spec, name})
			executionNames[id] = name
		}
	}
	queue := make(chan execution, len(jobs))
	for _, job := range jobs {
		queue <- job
	}
	close(queue)
	var workers sync.WaitGroup
	var failures []string
	workloadStart := time.Now()
	for worker := 0; worker < concurrency; worker++ {
		workers.Add(1)
		go func() {
			defer workers.Done()
			for job := range queue {
				args := []string{"--library-path", filepath.Join(rootfs, "lib") + ":" + filepath.Join(rootfs, "usr/lib"), filepath.Join(rootfs, "usr/bin/hurl"), "--test", "--jobs=1", "--variable", "host=http://" + listener.Addr().String() + "/" + job.id, "--variable", "uid=rules_stests_" + job.id, job.spec}
				command := exec.Command(filepath.Join(rootfs, "lib/ld-musl-x86_64.so.1"), args...)
				output, err := command.CombinedOutput()
				if err != nil {
					mutex.Lock()
					failures = append(failures, fmt.Sprintf("%s: %v: %s", job.name, err, output))
					mutex.Unlock()
				}
			}
		}()
	}
	workers.Wait()
	workloadMS := time.Since(workloadStart).Milliseconds()
	// Only the coordinator drains and freezes the shared sink, once.
	client := http.Client{Timeout: 10 * time.Second}
	quietStart := time.Now()
	last := sinkStats{}
	drained := false
	for deadline := time.Now().Add(30 * time.Second); time.Now().Before(deadline); {
		stats, err := readSinkStats(client, sink, "datadog")
		if err != nil {
			return err
		}
		if stats.CaptureOverflow {
			failures = append(failures, "stress capture overflow")
			drained = true
			break
		}
		if stats.TraceSpans != last.TraceSpans || stats.TraceRequests != last.TraceRequests {
			last = stats
			quietStart = time.Now()
		}
		if stats.TraceSpans > 0 && time.Since(quietStart) >= 2*time.Second {
			drained = true
			break
		}
		time.Sleep(100 * time.Millisecond)
	}
	if !drained {
		failures = append(failures, "shared sink did not become quiescent")
	}
	response, err := client.Get(sinkURL(sink, "/dump", "datadog"))
	if err != nil {
		return err
	}
	capture, err := io.ReadAll(response.Body)
	response.Body.Close()
	if err != nil {
		return err
	}
	if response.StatusCode != 200 {
		return fmt.Errorf("stress dump HTTP %d", response.StatusCode)
	}
	values := make([]requestLedger, len(ledger))
	var intervals [][2]int64
	for i, entry := range ledger {
		values[i] = *entry
		intervals = append(intervals, [2]int64{entry.Start, entry.End})
	}
	var plan normalizedProofPlan
	if err = json.Unmarshal([]byte(declaration.ProofPlan), &plan); err != nil {
		return err
	}
	if err = validateStress(capture, values, plan.ServiceName); err != nil {
		failures = append(failures, err.Error())
	}
	if overlap(intervals) < 2 {
		failures = append(failures, "proxy observed no overlapping requests")
	}
	encodedLedger, _ := json.MarshalIndent(values, "", "  ")
	evidence := map[string]any{"schemaVersion": 1, "profile": declaration.Profile, "concurrency": concurrency, "repetitions": repetitions, "workloadMs": workloadMS, "observedOverlap": overlap(intervals), "captureSha256": digestBytes(capture), "ledgerSha256": digestBytes(encodedLedger), "assertionsPassed": len(failures) == 0, "failures": failures}
	out := os.Getenv("TEST_UNDECLARED_OUTPUTS_DIR")
	if out == "" {
		return fmt.Errorf("stress evidence directory missing")
	}
	for name, contents := range map[string][]byte{"stress.capture.json": capture, "stress.ledger.json": encodedLedger} {
		if err = os.WriteFile(filepath.Join(out, name), contents, 0644); err != nil {
			return err
		}
	}
	encoded, _ := json.MarshalIndent(evidence, "", "  ")
	if err = os.WriteFile(filepath.Join(out, "stress.result.json"), encoded, 0644); err != nil {
		return err
	}
	if len(failures) > 0 {
		return fmt.Errorf("parallel scenario assertions: %s", strings.Join(failures, "; "))
	}
	fmt.Printf("Validated %d parallel scenario executions, %d requests, overlap %d\n", len(jobs), len(ledger), overlap(intervals))
	return nil
}

func mustResolve(value string) string {
	path, err := resolvePath(value, false)
	if err != nil {
		return value
	}
	return path
}
