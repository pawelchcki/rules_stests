package main

import (
	"archive/tar"
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"os"
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
