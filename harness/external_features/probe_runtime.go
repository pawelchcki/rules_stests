package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"syscall"
	"time"
)

// Process, socket ownership, and capture mechanics shared by SDK experiments.
// Each executable supplies experimentEnvironment, protocolEndpoint and workload.
type experiment struct {
	Name     string
	Env      map[string]string
	Features []string
}

var client = &http.Client{Timeout: 5 * time.Second}

var errPortInUse = errors.New("application port already in use")

func collect(app, launcher string, args []string, sink, out string, e experiment) ([]byte, error) {
	attempt := 0
	return retryPortConflicts(func() ([]byte, error) {
		attempt++
		return collectOnce(app, launcher, args, sink, out, e, attempt)
	})
}

func retryPortConflicts(attempt func() ([]byte, error)) ([]byte, error) {
	var err error
	for tries := 0; tries < 3; tries++ {
		var data []byte
		data, err = attempt()
		if !errors.Is(err, errPortInUse) {
			return data, err
		}
	}
	return nil, fmt.Errorf("application port unavailable after three attempts: %w", err)
}

func collectOnce(app, launcher string, args []string, sink, out string, e experiment, attempt int) ([]byte, error) {
	if _, err := request("POST", protocolEndpoint(sink, "/reset"), nil); err != nil {
		return nil, err
	}
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return nil, err
	}
	port := listener.Addr().(*net.TCPAddr).Port
	listener.Close()
	env := experimentEnvironment(app, sink)
	for k, v := range e.Env {
		env[k] = v
	}
	var launchArgs []string
	for _, arg := range args {
		if arg == "--" {
			launchArgs = append(launchArgs, fmt.Sprintf("--instance=external-%s-%d", e.Name, attempt))
			keys := make([]string, 0, len(env))
			for key := range env {
				keys = append(keys, key)
			}
			sort.Strings(keys)
			for _, k := range keys {
				launchArgs = append(launchArgs, "--env="+k+"="+env[k])
			}
		}
		launchArgs = append(launchArgs, strings.ReplaceAll(arg, "{PORT}", strconv.Itoa(port)))
	}
	log, err := os.Create(filepath.Join(out, e.Name+".app.log"))
	if err != nil {
		return nil, err
	}
	defer log.Close()
	cmd := exec.Command(launcher, launchArgs...)
	// Ambient SDK configuration must not change either side of the experiment.
	for _, entry := range os.Environ() {
		if !strings.HasPrefix(entry, "OTEL_") && !strings.HasPrefix(entry, "DD_") && !strings.HasPrefix(entry, "APP_STATE_DIR=") {
			cmd.Env = append(cmd.Env, entry)
		}
	}
	cmd.Stdout, cmd.Stderr = log, log
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	if err := cmd.Start(); err != nil {
		return nil, err
	}
	done := make(chan error, 1)
	go func() { done <- cmd.Wait() }()
	stopped := false
	defer func() {
		if !stopped {
			syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL)
			<-done
		}
	}()
	base := fmt.Sprintf("http://127.0.0.1:%d", port)
	ready := false
	for deadline := time.Now().Add(30 * time.Second); time.Now().Before(deadline); {
		select {
		case err := <-done:
			stopped = true
			return nil, classifyProcessExit(err, log)
		default:
		}
		if response, err := client.Get(base + "/api/tags"); err == nil {
			io.Copy(io.Discard, response.Body)
			response.Body.Close()
			if response.StatusCode == 200 || response.StatusCode == 500 {
				owned, shared, err := processTCPPortOwnership(cmd.Process.Pid, port)
				if err != nil {
					return nil, err
				}
				if shared {
					return nil, errPortInUse
				}
				if !owned {
					// A concurrent fixture may be answering on the relinquished
					// port. Wait for this child to bind it or report the conflict.
					time.Sleep(100 * time.Millisecond)
					continue
				}
				if response.StatusCode == 500 {
					return nil, &workloadFailure{response.StatusCode}
				}
				ready = true
				break
			}
		}
		time.Sleep(100 * time.Millisecond)
	}
	if !ready {
		return nil, fmt.Errorf("application readiness timed out")
	}
	verifyOwnership := func() error {
		owned, shared, err := processTCPPortOwnership(cmd.Process.Pid, port)
		if err != nil {
			return err
		}
		if !owned || shared {
			return errPortInUse
		}
		return nil
	}
	if err := workload(base, e.Name, verifyOwnership); err != nil {
		return nil, err
	}
	// Several complete 500 ms reader periods give both captures measurements.
	// The process must remain alive and retain its port throughout the window.
	deadline := time.NewTimer(2500 * time.Millisecond)
	defer deadline.Stop()
	ownershipChecks := time.NewTicker(100 * time.Millisecond)
	defer ownershipChecks.Stop()
observation:
	for {
		select {
		case err := <-done:
			stopped = true
			exitErr := classifyProcessExit(err, log)
			if errors.Is(exitErr, errPortInUse) {
				return nil, exitErr
			}
			var startup *startupExit
			if !errors.As(exitErr, &startup) {
				return nil, exitErr
			}
			return nil, fmt.Errorf("application exited during workload: %v", err)
		case <-ownershipChecks.C:
			if err := verifyOwnership(); err != nil {
				return nil, err
			}
		case <-deadline.C:
			break observation
		}
	}
	syscall.Kill(-cmd.Process.Pid, syscall.SIGTERM)
	select {
	case <-done:
		stopped = true
	case <-time.After(time.Second):
		// Gin's instrumentation intercepts SIGTERM and flushes the SDK but
		// leaves the HTTP server running. Lifecycle shutdown is not a feature
		// claimed by these experiments; stop this owned process after its grace.
		if err := killAfterGrace(done, func() error { return syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL) }); err != nil {
			return nil, err
		}
		stopped = true
	}
	return request("GET", protocolEndpoint(sink, "/dump"), nil)
}

func processTCPPortOwnership(pid, port int) (bool, bool, error) {
	inodes := map[string]bool{}
	readTable := false
	for _, name := range []string{"tcp", "tcp6"} {
		data, err := os.ReadFile(fmt.Sprintf("/proc/%d/net/%s", pid, name))
		if err != nil {
			continue
		}
		readTable = true
		for _, line := range strings.Split(string(data), "\n")[1:] {
			fields := strings.Fields(line)
			if len(fields) < 10 || fields[3] != "0A" {
				continue
			}
			encodedAddress, encodedPort, ok := strings.Cut(fields[1], ":")
			if !ok || !conflictsWithProbeAddress(name, encodedAddress) {
				continue
			}
			value, err := strconv.ParseInt(encodedPort, 16, 32)
			if err == nil && int(value) == port {
				inodes[fields[9]] = true
			}
		}
	}
	if !readTable {
		return false, false, fmt.Errorf("read TCP socket table for process %d", pid)
	}
	entries, err := os.ReadDir(fmt.Sprintf("/proc/%d/fd", pid))
	if err != nil {
		return false, false, err
	}
	owned := map[string]bool{}
	for _, entry := range entries {
		target, err := os.Readlink(fmt.Sprintf("/proc/%d/fd/%s", pid, entry.Name()))
		if err != nil {
			continue
		}
		if inode, ok := strings.CutPrefix(target, "socket:["); ok {
			if inode, ok = strings.CutSuffix(inode, "]"); ok {
				owned[inode] = true
			}
		}
	}
	exclusive, shared := socketOwnership(inodes, owned)
	return exclusive, shared, nil
}

func conflictsWithProbeAddress(network, encoded string) bool {
	switch network {
	case "tcp":
		return encoded == "0100007F" || encoded == "00000000"
	case "tcp6":
		// The probe connects to 127.0.0.1 and separately requires the child
		// to own an IPv4 listener. A coexisting [::] socket may be IPV6_V6ONLY,
		// which /proc/net/tcp6 does not expose, so wildcard text alone is not
		// evidence that the IPv4 application port is shared. An explicitly
		// IPv4-mapped loopback listener does conflict with the probe address.
		return encoded == "0000000000000000FFFF00000100007F"
	default:
		return false
	}
}

func socketOwnership(listening, owned map[string]bool) (bool, bool) {
	if len(listening) == 0 {
		return false, false
	}
	target, foreign := false, false
	for inode := range listening {
		if owned[inode] {
			target = true
		} else {
			foreign = true
		}
	}
	return target && !foreign, target && foreign
}

func classifyProcessExit(cause error, log *os.File) error {
	if err := log.Sync(); err != nil {
		return err
	}
	contents, err := os.ReadFile(log.Name())
	if err != nil {
		return err
	}
	message := strings.ToLower(string(contents))
	if strings.Contains(message, "address already in use") || strings.Contains(message, "eaddrinuse") {
		return fmt.Errorf("%w: %v", errPortInUse, cause)
	}
	return &startupExit{cause}
}

func killAfterGrace(done <-chan error, kill func() error) error {
	if err := kill(); err != nil && !errors.Is(err, syscall.ESRCH) {
		return err
	}
	<-done
	return nil
}

type startupExit struct{ cause error }

type workloadFailure struct{ status int }

func (e *workloadFailure) Error() string {
	return fmt.Sprintf("application health request returned HTTP %d", e.status)
}

func (e *startupExit) Error() string {
	return fmt.Sprintf("application exited before workload: %v", e.cause)
}

func request(method, url string, body []byte) ([]byte, error) {
	req, err := http.NewRequest(method, url, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("%s %s: HTTP %d: %s", method, url, resp.StatusCode, data)
	}
	return data, nil
}
func sinkEndpoint() (string, error) {
	var ports map[string]json.RawMessage
	if err := json.Unmarshal([]byte(os.Getenv("ASSIGNED_PORTS")), &ports); err != nil {
		return "", err
	}
	for label, raw := range ports {
		if strings.HasSuffix(label, "//harness:otel_sink_service") {
			var p int
			if err := json.Unmarshal(raw, &p); err != nil {
				var s string
				if err := json.Unmarshal(raw, &s); err != nil {
					return "", err
				}
				p, err = strconv.Atoi(s)
				if err != nil {
					return "", err
				}
			}
			return fmt.Sprintf("http://127.0.0.1:%d", p), nil
		}
	}
	return "", fmt.Errorf("telemetry sink missing from ASSIGNED_PORTS")
}
func resolve(path string) string {
	if _, err := os.Stat(path); err == nil {
		return path
	}
	for _, key := range []string{"RUNFILES_DIR", "TEST_SRCDIR"} {
		p := filepath.Join(os.Getenv(key), path)
		if _, err := os.Stat(p); err == nil {
			return p
		}
	}
	return path
}
func fail(err error) { fmt.Fprintln(os.Stderr, err); os.Exit(1) }
