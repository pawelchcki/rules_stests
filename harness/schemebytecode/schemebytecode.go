// Package schemebytecode compiles Scheme programs with the telemetry sink once,
// at build time, so tests post cached bytecode instead of recompiling source.
//
// Every compilation recompiles the VM prelude, which costs seconds regardless
// of program size. A bundle maps program names to bytecode and records the
// source digest it was compiled from, so a stale bundle is rejected rather
// than silently validating a different program.
package schemebytecode

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"sync"
)

// Program is one named Scheme program.
type Program struct {
	Name   string
	Source []byte
}

// Compiled is the bytecode of one program and the digest of its source.
type Compiled struct {
	SourceSHA256 string `json:"sourceSha256"`
	Bytecode     []byte `json:"bytecode"`
}

// Bundle holds the compiled programs of one test.
type Bundle struct {
	Programs map[string]Compiled `json:"programs"`
}

// Digest is the hex SHA-256 of data.
func Digest(data []byte) string { return fmt.Sprintf("%x", sha256.Sum256(data)) }

// CompileAll compiles every program with `compiler --compile`, in parallel.
func CompileAll(compiler string, programs []Program) (map[string][]byte, error) {
	compiler, err := filepath.Abs(compiler)
	if err != nil {
		return nil, err
	}
	scratch, err := os.MkdirTemp("", "scheme-bytecode-")
	if err != nil {
		return nil, err
	}
	defer os.RemoveAll(scratch)
	results := make([][]byte, len(programs))
	failures := make([]error, len(programs))
	work := make(chan int)
	var group sync.WaitGroup
	for worker := 0; worker < runtime.NumCPU(); worker++ {
		group.Add(1)
		go func() {
			defer group.Done()
			for index := range work {
				results[index], failures[index] = compileOne(compiler, scratch, index, programs[index])
			}
		}()
	}
	for index := range programs {
		work <- index
	}
	close(work)
	group.Wait()
	compiled := make(map[string][]byte, len(programs))
	for index, program := range programs {
		if failures[index] != nil {
			return nil, failures[index]
		}
		if _, duplicate := compiled[program.Name]; duplicate {
			return nil, fmt.Errorf("duplicate Scheme program %q", program.Name)
		}
		compiled[program.Name] = results[index]
	}
	return compiled, nil
}

func compileOne(compiler, scratch string, index int, program Program) ([]byte, error) {
	source := filepath.Join(scratch, fmt.Sprintf("%d.scm", index))
	output := filepath.Join(scratch, fmt.Sprintf("%d.sbc", index))
	if err := os.WriteFile(source, program.Source, 0600); err != nil {
		return nil, err
	}
	if result, err := exec.Command(compiler, "--compile", source, "--output", output).CombinedOutput(); err != nil {
		return nil, fmt.Errorf("compile %s: %w: %s", program.Name, err, result)
	}
	return os.ReadFile(output)
}

// WriteBundle compiles programs and writes their bundle to path.
func WriteBundle(path, compiler string, programs []Program) error {
	compiled, err := CompileAll(compiler, programs)
	if err != nil {
		return err
	}
	bundle := Bundle{Programs: map[string]Compiled{}}
	for _, program := range programs {
		bundle.Programs[program.Name] = Compiled{SourceSHA256: Digest(program.Source), Bytecode: compiled[program.Name]}
	}
	data, err := json.Marshal(bundle)
	if err != nil {
		return err
	}
	return os.WriteFile(path, append(data, '\n'), 0644)
}

// ReadBundle loads a bundle written by WriteBundle.
func ReadBundle(path string) (*Bundle, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var bundle Bundle
	if err := json.Unmarshal(data, &bundle); err != nil {
		return nil, fmt.Errorf("decode Scheme bytecode bundle %s: %w", path, err)
	}
	return &bundle, nil
}

// Bytecode returns the program's bytecode if it was compiled from source.
func (bundle *Bundle) Bytecode(name string, source []byte) ([]byte, error) {
	compiled, ok := bundle.Programs[name]
	if !ok {
		return nil, fmt.Errorf("Scheme program %q was not precompiled", name)
	}
	if compiled.SourceSHA256 != Digest(source) || len(compiled.Bytecode) == 0 {
		return nil, fmt.Errorf("precompiled Scheme program %q is stale", name)
	}
	return compiled.Bytecode, nil
}

// Shard selects the programs of shard "k/n" (program index modulo n), so a
// probe's programs can compile in n parallel Bazel actions.
func Shard(programs []Program, spec string) ([]Program, error) {
	if spec == "" {
		return programs, nil
	}
	index, count, ok := strings.Cut(spec, "/")
	shard, indexErr := strconv.Atoi(index)
	shards, countErr := strconv.Atoi(count)
	if !ok || indexErr != nil || countErr != nil || shards < 1 || shard < 0 || shard >= shards {
		return nil, fmt.Errorf("invalid shard %q", spec)
	}
	var selected []Program
	for position, program := range programs {
		if position%shards == shard {
			selected = append(selected, program)
		}
	}
	return selected, nil
}

// Paths is a repeatable flag naming bundle files.
type Paths []string

func (paths *Paths) String() string         { return strings.Join(*paths, ",") }
func (paths *Paths) Set(value string) error { *paths = append(*paths, value); return nil }

// ReadBundles merges the bundles at paths; nil when there are none.
func ReadBundles(paths []string) (*Bundle, error) {
	if len(paths) == 0 {
		return nil, nil
	}
	merged := &Bundle{Programs: map[string]Compiled{}}
	for _, path := range paths {
		bundle, err := ReadBundle(path)
		if err != nil {
			return nil, err
		}
		for name, compiled := range bundle.Programs {
			if _, duplicate := merged.Programs[name]; duplicate {
				return nil, fmt.Errorf("Scheme program %q is in more than one bundle", name)
			}
			merged.Programs[name] = compiled
		}
	}
	return merged, nil
}

// Names lists the bundled programs.
func (bundle *Bundle) Names() []string {
	names := make([]string, 0, len(bundle.Programs))
	for name := range bundle.Programs {
		names = append(names, name)
	}
	sort.Strings(names)
	return names
}
