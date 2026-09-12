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
	for _, mutation := range []string{"sql-moved", "parent", "duplicate-request", "missing-request", "missing-server", "duplicate-span", "low-bit-merge", "no-overlap", "wrong-service", "lost-marker", "lost-sql", "wrong-sql-count", "short-context", "invalid-context", "zero-parent", "wrong-server-type"} {
		t.Run(mutation, func(t *testing.T) {
			ledger, chunks := stressFixture()
			switch mutation {
			case "wrong-server-type":
				chunks[0][0].Type = "sql"
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

func TestStressSQLLifecycleMarkers(t *testing.T) {
	for _, operation := range []string{"Begin", "Commit", "Rollback"} {
		ledger, chunks := stressFixture()
		span := &chunks[0][1]
		span.Name, span.Resource = "sqlite3.query", operation
		span.Meta = map[string]string{"component": "database/sql", "sql.query_type": operation, "rules_stests.request_id": ledger[0].ID, "rules_stests.sql_marker": ledger[0].SQLMarker}
		if err := validateStress(encodeStress(chunks), ledger, "svc"); err != nil {
			t.Fatal(err)
		}
		span.Meta["rules_stests.sql_marker"] = ledger[1].SQLMarker
		if err := validateStress(encodeStress(chunks), ledger, "svc"); err == nil {
			t.Fatal("accepted crossed lifecycle marker")
		}
	}
}

func TestStressRejectsInconsistentChunkIdentity(t *testing.T) {
	for _, mutation := range []string{"mixed-low-bits", "zero-then-nonzero-high-bits", "nonzero-then-zero-high-bits"} {
		t.Run(mutation, func(t *testing.T) {
			_, chunks := stressFixture()
			switch mutation {
			case "mixed-low-bits":
				chunks[0][1].TraceID++
			case "zero-then-nonzero-high-bits":
				chunks[0][0].Meta["_dd.p.tid"] = "0000000000000000"
				chunks[0][1].Meta = map[string]string{"_dd.p.tid": "0000000000000001"}
			case "nonzero-then-zero-high-bits":
				chunks[0][1].Meta = map[string]string{"_dd.p.tid": "0000000000000000"}
			}
			if _, err := stressIndex(encodeStress(chunks)); err == nil {
				t.Fatal("accepted inconsistent identity within a native intake chunk")
			}
		})
	}
}

func TestStressAcceptsExplicitZeroHighBits(t *testing.T) {
	_, chunks := stressFixture()
	chunks = chunks[:1]
	chunks[0][0].Meta["_dd.p.tid"] = "0000000000000000"
	chunks[0][1].Meta = map[string]string{"_dd.p.tid": "0000000000000000"}
	spans, err := stressIndex(encodeStress(chunks))
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := spans[stressIdentity{Low: 1, High: "0000000000000000", Span: 2}]; !ok {
		t.Fatal("lost the explicit 64-bit child identity")
	}
}

func TestStressRejectsCapturedRemoteParent(t *testing.T) {
	ledger, chunks := stressFixture()
	// The ledger claims caller span 7 is outside the application. Making a SQL
	// child use that identity creates a cycle through the server's remote parent.
	chunks[0][1].SpanID = 7
	if err := validateStress(encodeStress(chunks), ledger, "svc"); err == nil {
		t.Fatal("accepted a cycle through a workload server's incoming parent")
	}
}

func TestStressAllowsRemoteParentIdentityInAnotherTrace(t *testing.T) {
	ledger, chunks := stressFixture()
	// The other trace may legitimately reuse a caller's span ID. Full trace
	// identity, including the high bits, separates this child from that caller.
	chunks[1][1].SpanID = 7
	chunks[1][0].ParentID = 8
	ledger[1].Incoming["traceparent"] = strings.Replace(ledger[1].Incoming["traceparent"], "-0000000000000007-", "-0000000000000008-", 1)
	if err := validateStress(encodeStress(chunks), ledger, "svc"); err != nil {
		t.Fatal(err)
	}
}

func TestStressOverlapRequiresPositiveIntersection(t *testing.T) {
	if got := overlap([][2]int64{{1, 2}, {2, 3}}); got != 1 {
		t.Fatalf("touching requests counted as concurrent: %d", got)
	}
	if got := overlap([][2]int64{{1, 3}, {2, 4}}); got != 2 {
		t.Fatalf("overlapping requests not counted: %d", got)
	}
}

func TestStressResolvesTaggedParentsAcrossChunks(t *testing.T) {
	ledger, chunks := stressFixture()
	var split [][]stressSpan
	for _, chunk := range chunks {
		root, child := chunk[0], chunk[1]
		child.Meta = map[string]string{"_dd.p.tid": root.Meta["_dd.p.tid"]}
		// Completed children can arrive before a later chunk containing the root.
		split = append(split, []stressSpan{child}, []stressSpan{root})
	}
	if err := validateStress(encodeStress(split), ledger, "svc"); err != nil {
		t.Fatal(err)
	}
}

func TestStressResolvesUntaggedParentsAcrossChunks(t *testing.T) {
	ledger, chunks := stressFixture()
	var split [][]stressSpan
	for i, chunk := range chunks {
		root, child := chunk[0], chunk[1]
		root.SpanID = uint64(10 * (i + 1))
		child.SpanID, child.ParentID = root.SpanID+1, root.SpanID+2
		middle := stressSpan{TraceID: root.TraceID, SpanID: root.SpanID + 2, ParentID: root.SpanID, Start: child.Start, Duration: child.Duration, Name: "controller"}
		// Two untagged chunks precede the root that establishes their high bits.
		split = append(split, []stressSpan{child}, []stressSpan{middle}, []stressSpan{root})
	}
	if err := validateStress(encodeStress(split), ledger, "svc"); err != nil {
		t.Fatal(err)
	}
	// The same low ID and parent span ID now match two different high IDs.
	// Assigning either one would silently merge independently owned requests.
	split[5][0].SpanID = split[2][0].SpanID
	split[4][0].ParentID = split[2][0].SpanID
	if _, err := stressIndex(encodeStress(split)); err == nil {
		t.Fatal("accepted ambiguous untagged parent identity")
	}
}

func TestStressDoesNotInferHighBitsFromLowBitsAlone(t *testing.T) {
	_, chunks := stressFixture()
	untagged := stressSpan{TraceID: 1, SpanID: 55, Start: 1, Duration: 1, Name: "standalone"}
	chunks = append(chunks, []stressSpan{untagged})
	spans, err := stressIndex(encodeStress(chunks))
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := spans[stressIdentity{Low: 1, High: "0000000000000000", Span: 55}]; !ok {
		t.Fatal("inferred high bits without a span or parent link")
	}
}
