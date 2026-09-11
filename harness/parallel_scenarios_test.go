package main

import (
	"encoding/json"
	"fmt"
	"strings"
	"testing"
)

func stressFixture() ([]requestLedger, [][]stressSpan) {
	var ledger []requestLedger
	var chunks [][]stressSpan
	for i := 1; i <= 2; i++ {
		high := fmt.Sprintf("%016x", i)
		id := fmt.Sprintf("%032x", i)
		marker := strings.Repeat(fmt.Sprint(i), 32)
		ledger = append(ledger, requestLedger{Execution: id, Scenario: "tags", Sequence: 1, ID: id, Method: "GET", Path: "/api/tags", Status: 200, SQLMarker: marker, SQLCount: 1, Start: 1, End: 10, Incoming: map[string]string{"traceparent": "00-" + high + "0000000000000001-0000000000000007-01"}})
		root := stressSpan{TraceID: 1, SpanID: 1, ParentID: 7, Start: int64(100 * i), Duration: 300, Service: "svc", Name: "aiohttp.request", Type: "web", Meta: map[string]string{"_dd.p.tid": high, "rules_stests.request_id": id, "http.method": "GET", "http.status_code": "200", "http.url": "http://localhost:1234/api/tags"}}
		sql := stressSpan{TraceID: 1, SpanID: 2, ParentID: 1, Start: int64(100*i + 1), Duration: 10, Name: "sqlite.query", Type: "sql", Resource: "SELECT 1 /* rules_stests_request=" + id + "; marker=" + marker + " */"}
		chunks = append(chunks, []stressSpan{root, sql})
	}
	return ledger, chunks
}

func encodeStress(chunks [][]stressSpan) []byte {
	data, _ := json.Marshal([]any{map[string]any{"payload": map[string]any{"traces": chunks}}})
	return data
}

func TestStressRejectsCrossedWorkersAndLostEvidence(t *testing.T) {
	ledger, chunks := stressFixture()
	if err := validateStress(encodeStress(chunks), ledger, "svc"); err != nil {
		t.Fatal(err)
	}
	for _, mutation := range []string{"sql-moved", "parent", "duplicate-request", "missing-request", "missing-server", "duplicate-span", "low-bit-merge", "no-overlap", "wrong-service", "lost-marker", "lost-sql", "wrong-sql-count", "short-context", "invalid-context", "zero-parent"} {
		t.Run(mutation, func(t *testing.T) {
			ledger, chunks := stressFixture()
			switch mutation {
			case "short-context":
				ledger[0].Incoming["traceparent"] = "00-1-2-01"
			case "invalid-context":
				ledger[0].Incoming["traceparent"] = "00-zzzzzzzzzzzzzzzz0000000000000001-0000000000000007-01"
			case "zero-parent":
				ledger[0].Incoming["traceparent"] = "00-00000000000000010000000000000001-0000000000000000-01"
			case "sql-moved":
				chunks[0][1], chunks[1][1] = chunks[1][1], chunks[0][1]
			case "parent":
				chunks[0][1].ParentID = 999
			case "duplicate-request":
				ledger = append(ledger, ledger[0])
			case "missing-request":
				ledger = ledger[1:]
			case "missing-server":
				chunks[0] = chunks[0][1:]
			case "duplicate-span":
				chunks[0] = append(chunks[0], chunks[0][1])
			case "low-bit-merge":
				chunks[1][0].Meta["_dd.p.tid"] = chunks[0][0].Meta["_dd.p.tid"]
			case "no-overlap":
				chunks[1][0].Start = 9999
			case "wrong-service":
				chunks[0][0].Service = "wrong"
			case "lost-sql":
				chunks[0] = chunks[0][:1]
			case "wrong-sql-count":
				ledger[0].SQLCount++
			case "lost-marker":
				chunks[0][1].Resource = "SELECT 1"
			}
			if err := validateStress(encodeStress(chunks), ledger, "svc"); err == nil {
				t.Fatal("accepted corrupted workload evidence")
			}
		})
	}
}
