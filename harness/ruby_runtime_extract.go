package main

import (
	"debug/elf"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

// Full compiler images exist only for the two oldest Rubies. Unpack into
// temporary storage, then return only Ruby, its headers and shared-library
// closure. Compiler binaries, static libraries and package caches never enter
// the remote action's output tree.
func extractRubyRuntime(layout, output string, zstdTool ...string) error {
	staging, err := os.MkdirTemp("", "ruby-runtime-")
	if err != nil {
		return err
	}
	defer os.RemoveAll(staging)
	if err := extractOCI(layout, staging, false, zstdTool...); err != nil {
		return err
	}
	return trimRubyRuntime(staging, output)
}

func trimRubyRuntime(staging, output string) error {
	if err := os.MkdirAll(output, 0o755); err != nil {
		return err
	}
	var binaries []string
	copyFile := func(source, target string) error {
		if err := os.MkdirAll(filepath.Dir(target), 0o755); err != nil {
			return err
		}
		input, err := os.Open(source)
		if err != nil {
			return err
		}
		defer input.Close()
		info, err := input.Stat()
		if err != nil {
			return err
		}
		out, err := os.OpenFile(target, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, info.Mode().Perm())
		if err != nil {
			return err
		}
		_, copyErr := io.Copy(out, input)
		closeErr := out.Close()
		if copyErr != nil {
			return copyErr
		}
		return closeErr
	}
	for _, prefix := range []string{"usr/local/bin/ruby", "usr/local/include", "usr/local/lib"} {
		err := filepath.WalkDir(filepath.Join(staging, prefix), func(path string, entry fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if entry.IsDir() {
				if entry.Name() == "cache" || entry.Name() == "doc" {
					return filepath.SkipDir
				}
				return nil
			}
			if strings.HasSuffix(path, ".a") {
				return nil
			}
			relative, err := filepath.Rel(staging, path)
			if err != nil {
				return err
			}
			if entry.Type()&os.ModeSymlink != 0 {
				info, err := os.Stat(path)
				if err != nil {
					return err
				}
				if info.IsDir() {
					return fmt.Errorf("unexpected Ruby library directory symlink: %s", relative)
				}
				link, err := os.Readlink(path)
				if err != nil {
					return err
				}
				target := filepath.Clean(filepath.Join(filepath.Dir(relative), link))
				if strings.HasPrefix(target, "usr/local/") {
					destination := filepath.Join(output, relative)
					if err := os.MkdirAll(filepath.Dir(destination), 0o755); err != nil {
						return err
					}
					return os.Symlink(link, destination)
				}
			}
			if strings.Contains(entry.Name(), ".so") || prefix == "usr/local/bin/ruby" {
				binaries = append(binaries, path)
			}
			return copyFile(path, filepath.Join(output, relative))
		})
		if err != nil {
			return err
		}
	}
	loader := "lib64/ld-linux-x86-64.so.2"
	if err := copyFile(filepath.Join(staging, loader), filepath.Join(output, loader)); err != nil {
		return err
	}
	search := []string{"usr/local/lib", "lib/x86_64-linux-gnu", "usr/lib/x86_64-linux-gnu"}
	// glibc loads NSS modules with dlopen, so they are absent from DT_NEEDED.
	// Keep the pinned image's modules to avoid loading the host's newer libc
	// plugins when WEBrick resolves its bind address or server name.
	for _, name := range []string{"libnss_files.so.2", "libnss_dns.so.2"} {
		for _, directory := range search {
			relative := filepath.Join(directory, name)
			path := filepath.Join(staging, relative)
			if info, err := os.Stat(path); err == nil && info.Mode().IsRegular() {
				if err := copyFile(path, filepath.Join(output, relative)); err != nil {
					return err
				}
				binaries = append(binaries, path)
				break
			}
		}
	}
	seen := map[string]bool{}
	for len(binaries) > 0 {
		binary := binaries[0]
		binaries = binaries[1:]
		if seen[binary] {
			continue
		}
		seen[binary] = true
		file, err := elf.Open(binary)
		if err != nil {
			return fmt.Errorf("inspect Ruby ELF %s: %w", binary, err)
		}
		libraries, err := file.ImportedLibraries()
		file.Close()
		if err != nil {
			return err
		}
		for _, library := range libraries {
			found := false
			for _, directory := range search {
				relative := filepath.Join(directory, library)
				path := filepath.Join(staging, relative)
				if info, err := os.Stat(path); err == nil && info.Mode().IsRegular() {
					found = true
					if !seen[path] {
						if err := copyFile(path, filepath.Join(output, relative)); err != nil {
							return err
						}
						binaries = append(binaries, path)
					}
					break
				}
			}
			if !found {
				return fmt.Errorf("Ruby dependency %s is absent from its pinned image", library)
			}
		}
	}
	return copyFile(filepath.Join(staging, ".rules-stests-manifest"), filepath.Join(output, ".rules-stests-manifest"))
}
