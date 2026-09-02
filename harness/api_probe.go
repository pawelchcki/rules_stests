package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

func main() {
	serviceSuffix := flag.String("service-suffix", "", "suffix of the rules_itest service label")
	flag.Parse()
	if *serviceSuffix == "" {
		fmt.Fprintln(os.Stderr, "--service-suffix is required")
		os.Exit(2)
	}

	var ports map[string]json.RawMessage
	if err := json.Unmarshal([]byte(os.Getenv("ASSIGNED_PORTS")), &ports); err != nil {
		fmt.Fprintln(os.Stderr, "decode ASSIGNED_PORTS:", err)
		os.Exit(1)
	}
	port := 0
	for label, encoded := range ports {
		if strings.HasSuffix(label, *serviceSuffix) {
			if err := json.Unmarshal(encoded, &port); err != nil {
				var text string
				if stringErr := json.Unmarshal(encoded, &text); stringErr != nil {
					fmt.Fprintf(os.Stderr, "decode assigned port for %s: %v\n", label, err)
					os.Exit(1)
				}
				port, err = strconv.Atoi(text)
				if err != nil {
					fmt.Fprintf(os.Stderr, "decode assigned port for %s: %v\n", label, err)
					os.Exit(1)
				}
			}
			break
		}
	}
	if port == 0 {
		fmt.Fprintf(os.Stderr, "service ending in %q is absent from ASSIGNED_PORTS: %v\n", *serviceSuffix, ports)
		os.Exit(1)
	}

	client := &http.Client{Timeout: 10 * time.Second}
	response, err := client.Get(fmt.Sprintf("http://127.0.0.1:%d/api/tags", port))
	if err != nil {
		fmt.Fprintln(os.Stderr, "GET /api/tags:", err)
		os.Exit(1)
	}
	defer response.Body.Close()
	body, err := io.ReadAll(response.Body)
	if err != nil {
		fmt.Fprintln(os.Stderr, "read /api/tags:", err)
		os.Exit(1)
	}
	if response.StatusCode != http.StatusOK {
		fmt.Fprintf(os.Stderr, "GET /api/tags returned %s: %s\n", response.Status, body)
		os.Exit(1)
	}
	var payload struct {
		Tags []string `json:"tags"`
	}
	if err := json.Unmarshal(body, &payload); err != nil {
		fmt.Fprintln(os.Stderr, "decode /api/tags response:", err)
		os.Exit(1)
	}
	fmt.Printf("verified %s on port %d: %s\n", *serviceSuffix, port, body)
}
