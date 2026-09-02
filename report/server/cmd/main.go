package main

import (
	"context"
	"flag"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
	"time"

	reportserver "github.com/pawelchcki/rules_stests/report/server"
)

func main() {
	listen := flag.String("listen", "127.0.0.1:8765", "HTTP listen address")
	reportFile := flag.String("file", "", "explicitly assembled report HTML (required)")
	cloudflared := flag.String("cloudflared", "", "cloudflared executable for an ephemeral public tunnel")
	flag.Parse()

	if *reportFile == "" {
		fmt.Fprintln(os.Stderr, "feature parity HTTP server: --file is required")
		os.Exit(1)
	}
	if err := reportserver.ValidateReport(*reportFile); err != nil {
		fmt.Fprintln(os.Stderr, "feature parity HTTP server:", err)
		os.Exit(1)
	}
	listener, err := net.Listen("tcp", *listen)
	if err != nil {
		fmt.Fprintln(os.Stderr, "feature parity HTTP server:", err)
		os.Exit(1)
	}
	server := &http.Server{Handler: reportserver.NewHandler(*reportFile)}
	localURL := "http://" + listener.Addr().String()
	fmt.Printf("feature parity report: %s%s\n", localURL, reportserver.ReportPath)

	if *cloudflared == "" {
		if err := server.Serve(listener); err != nil && err != http.ErrServerClosed {
			fmt.Fprintln(os.Stderr, "feature parity HTTP server:", err)
			os.Exit(1)
		}
		return
	}

	go func() {
		if err := server.Serve(listener); err != nil && err != http.ErrServerClosed {
			fmt.Fprintln(os.Stderr, "feature parity HTTP server:", err)
		}
	}()
	if err := runQuickTunnel(server, *cloudflared, localURL); err != nil {
		fmt.Fprintln(os.Stderr, "feature parity public tunnel:", err)
		os.Exit(1)
	}
}

func runQuickTunnel(server *http.Server, cloudflared, localURL string) error {
	config, err := os.CreateTemp("", "feature-parity-cloudflared-*.yml")
	if err != nil {
		return fmt.Errorf("create empty cloudflared config: %w", err)
	}
	configPath := config.Name()
	defer os.Remove(configPath)
	if _, err := config.WriteString("{}\n"); err != nil {
		_ = config.Close()
		return fmt.Errorf("write empty cloudflared config: %w", err)
	}
	if err := config.Close(); err != nil {
		return fmt.Errorf("close empty cloudflared config: %w", err)
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	cmd := exec.CommandContext(
		ctx,
		cloudflared,
		"--config", configPath,
		"tunnel",
		"--no-autoupdate",
		"--url", localURL,
	)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	fmt.Println("starting public quick tunnel; use the trycloudflare.com URL printed below")
	err = cmd.Run()

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_ = server.Shutdown(shutdownCtx)
	if ctx.Err() != nil {
		return nil
	}
	if err != nil {
		return fmt.Errorf("cloudflared exited: %w", err)
	}
	return nil
}
