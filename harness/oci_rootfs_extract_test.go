package main

import (
	"archive/tar"
	"bytes"
	"crypto/sha256"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestExtractorCLIProducesRootfsAndVerifiesDigest(t *testing.T) {
	layout := t.TempDir()
	if err := os.MkdirAll(filepath.Join(layout, "blobs", "sha256"), 0o755); err != nil {
		t.Fatal(err)
	}
	writeBlob := func(contents []byte, mediaType string) descriptor {
		digest := fmt.Sprintf("sha256:%x", sha256.Sum256(contents))
		path, err := blobPath(layout, digest)
		if err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, contents, 0o644); err != nil {
			t.Fatal(err)
		}
		return descriptor{Digest: digest, MediaType: mediaType, Size: int64(len(contents))}
	}
	var layer bytes.Buffer
	writer := tar.NewWriter(&layer)
	if err := writer.WriteHeader(&tar.Header{Name: "bin/app", Mode: 0o755, Size: 3}); err != nil {
		t.Fatal(err)
	}
	if _, err := writer.Write([]byte("app")); err != nil {
		t.Fatal(err)
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	layerDescriptor := writeBlob(layer.Bytes(), "application/vnd.oci.image.layer.v1.tar")
	manifestJSON, err := json.Marshal(manifest{Layers: []descriptor{layerDescriptor}})
	if err != nil {
		t.Fatal(err)
	}
	manifestDescriptor := writeBlob(manifestJSON, "application/vnd.oci.image.manifest.v1+json")
	indexJSON, err := json.Marshal(index{Manifests: []descriptor{manifestDescriptor}})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(layout, "index.json"), indexJSON, 0o644); err != nil {
		t.Fatal(err)
	}
	for _, mode := range []string{"single", "multi"} {
		root := filepath.Join(t.TempDir(), "rootfs")
		if err := run([]string{layout, root, mode}); err != nil {
			t.Fatal(err)
		}
		for name, want := range map[string]string{"bin/app": "app", ".rules-stests-manifest": manifestDescriptor.Digest + "\n"} {
			if got, err := os.ReadFile(filepath.Join(root, name)); err != nil || string(got) != want {
				t.Errorf("%s: %q, %v; want %q", name, got, err, want)
			}
		}
	}
	path, err := blobPath(layout, layerDescriptor.Digest)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte("corrupt"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := run([]string{layout, filepath.Join(t.TempDir(), "rootfs"), "multi"}); err == nil || !strings.Contains(err.Error(), "digest mismatch") {
		t.Fatalf("corrupt layer error = %v", err)
	}
}

func TestRemoveDanglingSymlinksPreservesEmptyDirectoryTarget(t *testing.T) {
	root := t.TempDir()
	lockDirectory := filepath.Join(root, "run", "lock")
	if err := os.MkdirAll(lockDirectory, 0o755); err != nil {
		t.Fatal(err)
	}
	varDirectory := filepath.Join(root, "var")
	if err := os.MkdirAll(varDirectory, 0o755); err != nil {
		t.Fatal(err)
	}
	lockLink := filepath.Join(varDirectory, "lock")
	if err := os.Symlink("../run/lock", lockLink); err != nil {
		t.Fatal(err)
	}

	if err := removeDanglingSymlinks(root); err != nil {
		t.Fatal(err)
	}
	info, err := os.Lstat(lockLink)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode()&os.ModeSymlink == 0 {
		t.Fatalf("%s is no longer a symlink", lockLink)
	}
	if _, err := os.Stat(filepath.Join(lockDirectory, treeArtifactDirectoryMarker)); err != nil {
		t.Fatalf("empty symlink target has no tree-artifact marker: %v", err)
	}
}

func TestRemoveDanglingSymlinksRemovesMissingTarget(t *testing.T) {
	root := t.TempDir()
	link := filepath.Join(root, "missing")
	if err := os.Symlink("does-not-exist", link); err != nil {
		t.Fatal(err)
	}

	if err := removeDanglingSymlinks(root); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Lstat(link); !os.IsNotExist(err) {
		t.Fatalf("dangling symlink still exists: %v", err)
	}
}

func TestRemoveDanglingSymlinksPreservesReadOnlyEmptyTarget(t *testing.T) {
	root := t.TempDir()
	target := filepath.Join(root, "target")
	if err := os.Mkdir(target, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.Chmod(target, 0o555); err != nil {
		t.Fatal(err)
	}
	link := filepath.Join(root, "link")
	if err := os.Symlink("target", link); err != nil {
		t.Fatal(err)
	}

	if err := removeDanglingSymlinks(root); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(target, treeArtifactDirectoryMarker)); err != nil {
		t.Fatalf("read-only symlink target has no tree-artifact marker: %v", err)
	}
	info, err := os.Stat(target)
	if err != nil {
		t.Fatal(err)
	}
	if got := info.Mode().Perm(); got != 0o555 {
		t.Fatalf("target mode = %o, want 555", got)
	}
	if err := os.Chmod(target, 0o755); err != nil {
		t.Fatalf("make target removable: %v", err)
	}
}

func TestPreserveEmptyDirectoriesRetainsNestedLeavesAndModes(t *testing.T) {
	root := t.TempDir()
	for _, mode := range []os.FileMode{0o555, 0o755, 0o700} {
		leaf := filepath.Join(root, fmt.Sprintf("mode-%o", mode), "tmp", "pids")
		if err := os.MkdirAll(leaf, 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.Chmod(leaf, mode); err != nil {
			t.Fatal(err)
		}
		defer os.Chmod(leaf, 0o755)
	}
	if err := os.WriteFile(filepath.Join(root, "Gemfile"), []byte("source"), 0o444); err != nil {
		t.Fatal(err)
	}
	for attempt := 0; attempt < 2; attempt++ {
		if err := preserveEmptyDirectories(root); err != nil {
			t.Fatal(err)
		}
	}
	for _, mode := range []os.FileMode{0o555, 0o755, 0o700} {
		leaf := filepath.Join(root, fmt.Sprintf("mode-%o", mode), "tmp", "pids")
		marker, err := os.Stat(filepath.Join(leaf, treeArtifactDirectoryMarker))
		if err != nil || marker.Size() != 0 || marker.Mode().Perm() != 0o444 {
			t.Fatalf("leaf marker: %v, %v", marker, err)
		}
		info, err := os.Stat(leaf)
		if err != nil || info.Mode().Perm() != mode {
			t.Fatalf("leaf mode: %v, %v; want %o", info, err, mode)
		}
		if _, err := os.Stat(filepath.Join(filepath.Dir(leaf), treeArtifactDirectoryMarker)); !os.IsNotExist(err) {
			t.Fatalf("nonempty ancestor received a marker: %v", err)
		}
	}
	if _, err := os.Stat(filepath.Join(root, treeArtifactDirectoryMarker)); !os.IsNotExist(err) {
		t.Fatalf("nonempty root received a marker: %v", err)
	}
}

func TestPreserveEmptyDirectoryWithoutSearchPermission(t *testing.T) {
	root := t.TempDir()
	leaf := filepath.Join(root, "empty")
	if err := os.Mkdir(leaf, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.Chmod(leaf, 0o400); err != nil {
		t.Fatal(err)
	}
	defer os.Chmod(leaf, 0o700)
	// This mode was accepted by extraction's existing directory/link walk.
	if err := removeDanglingSymlinks(root); err != nil {
		t.Fatal(err)
	}
	if err := preserveEmptyDirectories(root); err != nil {
		t.Fatal(err)
	}
	info, err := os.Stat(leaf)
	if err != nil || info.Mode().Perm() != 0o400 {
		t.Fatalf("directory mode: %v, %v; want 400", info, err)
	}
	if err := os.Chmod(leaf, 0o700); err != nil {
		t.Fatal(err)
	}
	marker, err := os.Stat(filepath.Join(leaf, treeArtifactDirectoryMarker))
	if err != nil || marker.Size() != 0 || marker.Mode().Perm() != 0o444 {
		t.Fatalf("leaf marker: %v, %v", marker, err)
	}
}

func TestExtractOCIPreservesOnlyEmptyDirectoriesRemainingAfterWhiteouts(t *testing.T) {
	layout := t.TempDir()
	if err := os.MkdirAll(filepath.Join(layout, "blobs", "sha256"), 0o755); err != nil {
		t.Fatal(err)
	}
	writeBlob := func(contents []byte, mediaType string) descriptor {
		digest := fmt.Sprintf("sha256:%x", sha256.Sum256(contents))
		path, err := blobPath(layout, digest)
		if err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, contents, 0o644); err != nil {
			t.Fatal(err)
		}
		return descriptor{Digest: digest, MediaType: mediaType, Size: int64(len(contents))}
	}
	var layers []descriptor
	for _, headers := range [][]tar.Header{
		{
			{Name: "kept/cache", Typeflag: tar.TypeDir, Mode: 0o755},
			{Name: "removed/pids", Typeflag: tar.TypeDir, Mode: 0o755},
			{Name: "after-cleanup/gone", Typeflag: tar.TypeSymlink, Linkname: "../removed/pids"},
		},
		{
			{Name: "kept/.wh..wh..opq", Mode: 0o644},
			{Name: ".wh.removed", Mode: 0o644},
		},
	} {
		var layer bytes.Buffer
		writer := tar.NewWriter(&layer)
		for _, header := range headers {
			if err := writer.WriteHeader(&header); err != nil {
				t.Fatal(err)
			}
		}
		if err := writer.Close(); err != nil {
			t.Fatal(err)
		}
		layers = append(layers, writeBlob(layer.Bytes(), "application/vnd.oci.image.layer.v1.tar"))
	}
	manifestJSON, err := json.Marshal(manifest{Layers: layers})
	if err != nil {
		t.Fatal(err)
	}
	manifestDescriptor := writeBlob(manifestJSON, "application/vnd.oci.image.manifest.v1+json")
	indexJSON, err := json.Marshal(index{Manifests: []descriptor{manifestDescriptor}})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(layout, "index.json"), indexJSON, 0o644); err != nil {
		t.Fatal(err)
	}
	root := filepath.Join(t.TempDir(), "rootfs")
	if err := extractOCI(layout, root, false); err != nil {
		t.Fatal(err)
	}
	for _, path := range []string{"kept", "after-cleanup"} {
		if _, err := os.Stat(filepath.Join(root, path, treeArtifactDirectoryMarker)); err != nil {
			t.Fatalf("empty directory %s lost its marker: %v", path, err)
		}
	}
	for _, path := range []string{"kept/cache", "removed", "after-cleanup/gone"} {
		if _, err := os.Lstat(filepath.Join(root, path)); !os.IsNotExist(err) {
			t.Fatalf("removed entry %s was retained: %v", path, err)
		}
	}
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func declaredZstd(t *testing.T) string {
	t.Helper()
	tool := os.Getenv("ZSTD_TOOL")
	if tool != "" {
		if runfiles := os.Getenv("TEST_SRCDIR"); runfiles != "" && !filepath.IsAbs(tool) {
			if candidate := filepath.Join(runfiles, tool); fileExists(candidate) {
				return candidate
			}
		}
		absolute, err := filepath.Abs(tool)
		if err != nil {
			t.Fatal(err)
		}
		return absolute
	}
	if os.Getenv("TEST_SRCDIR") != "" {
		t.Fatal("Bazel test must declare ZSTD_TOOL")
	}
	tool, err := exec.LookPath("zstd")
	if err != nil {
		t.Fatal("standalone extractor test requires zstd: ", err)
	}
	return tool
}

func TestZstdLayerExtractionAndCorruption(t *testing.T) {
	tool := declaredZstd(t)
	for _, mediaType := range []string{"application/vnd.oci.image.layer.v1.tar+zstd", "application/vnd.datadog.package.layer.v1.tar+zstd"} {
		for _, name := range []string{"sitecustomize.py", "../escape"} {
			t.Run(mediaType+"/"+name, func(t *testing.T) {
				var archive bytes.Buffer
				writer := tar.NewWriter(&archive)
				if err := writer.WriteHeader(&tar.Header{Name: name, Mode: 0o444, Size: 4}); err != nil {
					t.Fatal(err)
				}
				if _, err := writer.Write([]byte("hook")); err != nil {
					t.Fatal(err)
				}
				if err := writer.Close(); err != nil {
					t.Fatal(err)
				}
				command := exec.Command(tool, "--compress", "--stdout", "--quiet", "--check")
				command.Stdin = &archive
				compressed, err := command.Output()
				if err != nil {
					t.Fatal(err)
				}
				for _, corrupt := range []bool{false, true} {
					payload := append([]byte(nil), compressed...)
					if corrupt {
						// Break the checksum, after tar's end marker: extraction
						// must still wait for and reject decoder failure.
						payload[len(payload)-1] ^= 1
					}
					layout := t.TempDir()
					digest := fmt.Sprintf("sha256:%x", sha256.Sum256(payload))
					blob, err := blobPath(layout, digest)
					if err != nil {
						t.Fatal(err)
					}
					if err := os.MkdirAll(filepath.Dir(blob), 0o755); err != nil {
						t.Fatal(err)
					}
					if err := os.WriteFile(blob, payload, 0o444); err != nil {
						t.Fatal(err)
					}
					layer := descriptor{Digest: digest, MediaType: mediaType, Size: int64(len(payload))}
					root := t.TempDir()
					err = extractLayer(layout, layer, root, tool)
					if corrupt || name == "../escape" {
						if err == nil {
							t.Fatalf("accepted unsafe/corrupt layer: name=%s corrupt=%v", name, corrupt)
						}
						continue
					}
					if err != nil {
						t.Fatal(err)
					}
					if got, err := os.ReadFile(filepath.Join(root, name)); err != nil || string(got) != "hook" {
						t.Fatalf("extracted payload = %q, %v", got, err)
					}
					if err := extractLayer(layout, layer, root); err == nil || !strings.Contains(err.Error(), "declared zstd tool") {
						t.Fatalf("undeclared decoder error = %v", err)
					}
				}
			})
		}
	}
}

func rubyRuntimeFixture(t *testing.T) string {
	t.Helper()
	staging := t.TempDir()
	// Minimal inspectable ELF with no dynamic dependencies. This exercises
	// tree trimming without requiring executor-specific binaries or libc.
	contents := make([]byte, 64)
	copy(contents, []byte("\x7fELF\x02\x01\x01"))
	binary.LittleEndian.PutUint16(contents[16:], 2)  // ET_EXEC
	binary.LittleEndian.PutUint16(contents[18:], 62) // EM_X86_64
	binary.LittleEndian.PutUint32(contents[20:], 1)  // EV_CURRENT
	binary.LittleEndian.PutUint16(contents[52:], 64) // ELF header size
	files := map[string][]byte{
		"usr/local/bin/ruby":                             contents,
		"usr/local/lib/libruby.so.4.0.7":                 contents,
		"usr/local/include/ruby-4.0.0/ruby.h":            []byte("header"),
		"usr/local/lib/ruby/4.0.0/json.rb":               []byte("library"),
		"usr/local/lib/libruby-static.a":                 []byte("archive"),
		"usr/local/lib/ruby/gems/4.0.0/cache/bcrypt.gem": []byte("gem cache"),
		"usr/local/lib/ruby/gems/4.0.0/doc/manual":       []byte("documentation"),
		"usr/bin/gcc":                []byte("compiler"),
		"lib64/ld-linux-x86-64.so.2": []byte("loader"),
		".rules-stests-manifest":     []byte("pinned manifest\n"),
	}
	for name, data := range files {
		path := filepath.Join(staging, name)
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, data, 0o755); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.Symlink("libruby.so.4.0.7", filepath.Join(staging, "usr/local/lib/libruby.so")); err != nil {
		t.Fatal(err)
	}
	return staging
}

func TestRubyRuntimeTrimmingKeepsSymlinksAndRemovesBuildPayloads(t *testing.T) {
	staging, output := rubyRuntimeFixture(t), filepath.Join(t.TempDir(), "runtime")
	if err := trimRubyRuntime(staging, output); err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{"usr/local/bin/ruby", "usr/local/include/ruby-4.0.0/ruby.h", "usr/local/lib/ruby/4.0.0/json.rb", "lib64/ld-linux-x86-64.so.2", ".rules-stests-manifest"} {
		if !fileExists(filepath.Join(output, name)) {
			t.Errorf("missing runtime file %s", name)
		}
	}
	for _, name := range []string{"usr/bin/gcc", "usr/local/lib/libruby-static.a", "usr/local/lib/ruby/gems/4.0.0/cache", "usr/local/lib/ruby/gems/4.0.0/doc"} {
		if fileExists(filepath.Join(output, name)) {
			t.Errorf("build payload %s entered the runtime output", name)
		}
	}
	link, err := os.Readlink(filepath.Join(output, "usr/local/lib/libruby.so"))
	if err != nil || link != "libruby.so.4.0.7" {
		t.Fatalf("shared-library alias was duplicated instead of preserved: %q, %v", link, err)
	}
	if !fileExists(filepath.Join(output, "usr/local/lib/libruby.so")) {
		t.Fatal("shared-library alias has a missing target")
	}
}

func TestRubyHeadersAreSeparateAndIndependentOfRuntimePayload(t *testing.T) {
	staging := rubyRuntimeFixture(t)
	output, headers := filepath.Join(t.TempDir(), "runtime"), filepath.Join(t.TempDir(), "headers")
	if err := trimRubyRuntime(staging, output, headers); err != nil {
		t.Fatal(err)
	}
	header := "usr/local/include/ruby-4.0.0/ruby.h"
	data, err := os.ReadFile(filepath.Join(headers, header))
	if err != nil || string(data) != "header" {
		t.Fatalf("missing pinned Ruby header: %q, %v", data, err)
	}
	if fileExists(filepath.Join(output, "usr/local/include")) {
		t.Fatal("build-only headers entered the execution runtime")
	}
	if err := filepath.WalkDir(headers, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		relative, err := filepath.Rel(headers, path)
		if err != nil {
			return err
		}
		if !entry.IsDir() && !strings.HasPrefix(filepath.ToSlash(relative), "usr/local/include/") {
			t.Errorf("runtime payload entered compiler inputs: %s", relative)
		}
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	// Changing interpreter libraries or image metadata must not change the
	// header tree digest, which determines native compilation's cache key.
	for _, path := range []string{"usr/local/lib/ruby/4.0.0/json.rb", ".rules-stests-manifest"} {
		if err := os.WriteFile(filepath.Join(staging, path), []byte("changed"), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	otherOutput, otherHeaders := filepath.Join(t.TempDir(), "runtime"), filepath.Join(t.TempDir(), "headers")
	if err := trimRubyRuntime(staging, otherOutput, otherHeaders); err != nil {
		t.Fatal(err)
	}
	other, err := os.ReadFile(filepath.Join(otherHeaders, header))
	if err != nil || !bytes.Equal(data, other) {
		t.Fatalf("runtime-only change altered compiler inputs: %q, %v", other, err)
	}
}
