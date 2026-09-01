package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"syscall"
)

func main() {
	executable, err := os.Executable()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(126)
	}
	root := filepath.Dir(filepath.Dir(executable))
	imageRoot := filepath.Dir(filepath.Dir(root))
	loader := filepath.Join(imageRoot, "lib64", "ld-linux-x86-64.so.2")
	ruby := filepath.Join(root, "ruby", "bin", "ruby")
	rails := filepath.Join(root, "src", "bin", "rails")
	libraryPath := strings.Join([]string{filepath.Join(imageRoot, "lib", "x86_64-linux-gnu"), filepath.Join(imageRoot, "usr", "lib", "x86_64-linux-gnu"), filepath.Join(root, "ruby", "lib")}, ":")
	prismLibraries, err := filepath.Glob(filepath.Join(root, "bundle", "ruby", "3.3.0", "gems", "prism-*", "lib"))
	if err != nil || len(prismLibraries) != 1 {
		fmt.Fprintf(os.Stderr, "expected exactly one bundled Prism library, got %d\n", len(prismLibraries))
		os.Exit(126)
	}

	environment := make([]string, 0, len(os.Environ())+6)
	for _, entry := range os.Environ() {
		key, _, _ := strings.Cut(entry, "=")
		if key != "GEM_HOME" && key != "GEM_PATH" && key != "BUNDLE_GEMFILE" && key != "BUNDLE_PATH" && key != "DATABASE_PATH" && key != "LD_LIBRARY_PATH" && key != "RUBYLIB" {
			environment = append(environment, entry)
		}
	}
	state := os.Getenv("APP_STATE_DIR")
	if state == "" {
		state = "/data"
	}
	if err := cloneSeed(filepath.Join(root, "seed", "realworld.sqlite3"), filepath.Join(state, "realworld.sqlite3")); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(126)
	}
	environment = append(environment,
		"GEM_HOME="+filepath.Join(root, "ruby", "lib", "ruby", "gems", "3.3.0"),
		"GEM_PATH="+filepath.Join(root, "ruby", "lib", "ruby", "gems", "3.3.0"),
		"BUNDLE_GEMFILE="+filepath.Join(root, "src", "Gemfile"),
		"BUNDLE_PATH="+filepath.Join(root, "bundle"),
		"DATABASE_PATH="+filepath.Join(state, "realworld.sqlite3"),
		"LD_LIBRARY_PATH="+libraryPath,
		"RUBYLIB="+strings.Join([]string{prismLibraries[0], filepath.Join(root, "ruby", "lib", "ruby", "3.3.0"), filepath.Join(root, "ruby", "lib", "ruby", "3.3.0", "x86_64-linux")}, ":"),
	)
	args := []string{loader, "--library-path", libraryPath, ruby, rails}
	args = append(args, os.Args[1:]...)
	if err := syscall.Exec(loader, args, environment); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(126)
	}
}

func cloneSeed(source, destination string) error {
	if err := os.MkdirAll(filepath.Dir(destination), 0o700); err != nil {
		return fmt.Errorf("create application state directory: %w", err)
	}
	input, err := os.Open(source)
	if err != nil {
		return fmt.Errorf("open database seed: %w", err)
	}
	defer input.Close()
	output, err := os.OpenFile(destination, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o600)
	if os.IsExist(err) {
		return nil
	}
	if err != nil {
		return fmt.Errorf("create application database: %w", err)
	}
	if _, err := io.Copy(output, input); err != nil {
		output.Close()
		return fmt.Errorf("clone database seed: %w", err)
	}
	if err := output.Close(); err != nil {
		return fmt.Errorf("close application database: %w", err)
	}
	return nil
}
