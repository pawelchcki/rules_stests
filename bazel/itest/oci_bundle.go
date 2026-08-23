package main

import (
	"archive/tar"
	"compress/gzip"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"syscall"
)

type descriptor struct {
	Digest    string `json:"digest"`
	MediaType string `json:"mediaType"`
}

type index struct {
	Manifests []descriptor `json:"manifests"`
}

type manifest struct {
	Layers []descriptor `json:"layers"`
}

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "oci_bundle:", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) < 3 {
		return errors.New("usage: oci_bundle <prepare|serve|check> <instance> <oci-layout> [app arguments...]")
	}
	mode, instance, layoutArg := args[0], args[1], args[2]
	if mode != "prepare" && mode != "serve" && mode != "check" {
		return fmt.Errorf("unsupported mode %q", mode)
	}
	if !validInstance(instance) {
		return fmt.Errorf("unsafe instance name %q", instance)
	}

	testTmp := os.Getenv("TEST_TMPDIR")
	if testTmp == "" {
		return errors.New("TEST_TMPDIR is not set")
	}
	layout, err := resolveRunfile(layoutArg)
	if err != nil {
		return err
	}
	manifestDigest, layer, err := readSingleLayer(layout)
	if err != nil {
		return err
	}

	root := filepath.Join(testTmp, "rules_stests", instance, "rootfs")
	marker := filepath.Join(root, ".rules-stests-manifest")
	prepared, err := markerMatches(marker, manifestDigest)
	if err != nil {
		return err
	}
	if !prepared {
		if err := extractFresh(layout, layer, root); err != nil {
			return err
		}
		if err := os.WriteFile(marker, []byte(manifestDigest+"\n"), 0o644); err != nil {
			return fmt.Errorf("write extraction marker: %w", err)
		}
	}

	command := "check"
	appArgs := args[3:]
	if mode == "prepare" {
		command = "migrate"
	} else if mode == "serve" {
		command = "serve"
	}
	return execApp(root, command, appArgs)
}

func validInstance(value string) bool {
	if value == "" {
		return false
	}
	for _, r := range value {
		if (r < 'a' || r > 'z') && (r < '0' || r > '9') && r != '-' && r != '_' {
			return false
		}
	}
	return true
}

func resolveRunfile(value string) (string, error) {
	candidates := []string{value}
	if runfiles := os.Getenv("RUNFILES_DIR"); runfiles != "" {
		candidates = append(candidates, filepath.Join(runfiles, value))
	}
	if testSrcdir := os.Getenv("TEST_SRCDIR"); testSrcdir != "" {
		candidates = append(candidates, filepath.Join(testSrcdir, value))
	}
	for _, candidate := range candidates {
		if info, err := os.Stat(candidate); err == nil && info.IsDir() {
			return filepath.Abs(candidate)
		}
	}
	return "", fmt.Errorf("OCI layout %q is not present in runfiles", value)
}

func readJSON(path string, value any) error {
	contents, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	if err := json.Unmarshal(contents, value); err != nil {
		return fmt.Errorf("decode %s: %w", path, err)
	}
	return nil
}

func readSingleLayer(layout string) (string, descriptor, error) {
	var idx index
	if err := readJSON(filepath.Join(layout, "index.json"), &idx); err != nil {
		return "", descriptor{}, fmt.Errorf("read OCI index: %w", err)
	}
	if len(idx.Manifests) != 1 {
		return "", descriptor{}, fmt.Errorf("expected one OCI manifest, got %d", len(idx.Manifests))
	}
	manifestPath, err := blobPath(layout, idx.Manifests[0].Digest)
	if err != nil {
		return "", descriptor{}, err
	}
	if err := verifyBlob(manifestPath, idx.Manifests[0].Digest); err != nil {
		return "", descriptor{}, err
	}
	var imageManifest manifest
	if err := readJSON(manifestPath, &imageManifest); err != nil {
		return "", descriptor{}, fmt.Errorf("read OCI manifest: %w", err)
	}
	if len(imageManifest.Layers) != 1 {
		return "", descriptor{}, fmt.Errorf("portable app images must contain exactly one layer, got %d", len(imageManifest.Layers))
	}
	return idx.Manifests[0].Digest, imageManifest.Layers[0], nil
}

func blobPath(layout, digest string) (string, error) {
	algorithm, encoded, ok := strings.Cut(digest, ":")
	if !ok || algorithm != "sha256" || len(encoded) != 64 {
		return "", fmt.Errorf("unsupported digest %q", digest)
	}
	if _, err := hex.DecodeString(encoded); err != nil {
		return "", fmt.Errorf("invalid digest %q: %w", digest, err)
	}
	return filepath.Join(layout, "blobs", algorithm, encoded), nil
}

func verifyBlob(path, digest string) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()
	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		return err
	}
	actual := "sha256:" + hex.EncodeToString(hash.Sum(nil))
	if actual != digest {
		return fmt.Errorf("blob digest mismatch: expected %s, got %s", digest, actual)
	}
	return nil
}

func markerMatches(path, digest string) (bool, error) {
	contents, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return false, nil
	}
	if err != nil {
		return false, fmt.Errorf("read extraction marker: %w", err)
	}
	return strings.TrimSpace(string(contents)) == digest, nil
}

func extractFresh(layout string, layer descriptor, root string) error {
	blob, err := blobPath(layout, layer.Digest)
	if err != nil {
		return err
	}
	if err := verifyBlob(blob, layer.Digest); err != nil {
		return err
	}
	if err := os.RemoveAll(root); err != nil {
		return fmt.Errorf("clear old bundle root: %w", err)
	}
	if err := os.MkdirAll(root, 0o755); err != nil {
		return fmt.Errorf("create bundle root: %w", err)
	}

	file, err := os.Open(blob)
	if err != nil {
		return err
	}
	defer file.Close()

	var reader io.Reader = file
	switch layer.MediaType {
	case "application/vnd.oci.image.layer.v1.tar+gzip", "application/vnd.docker.image.rootfs.diff.tar.gzip":
		compressed, err := gzip.NewReader(file)
		if err != nil {
			return fmt.Errorf("open gzip layer: %w", err)
		}
		defer compressed.Close()
		reader = compressed
	case "application/vnd.oci.image.layer.v1.tar", "application/vnd.docker.image.rootfs.diff.tar":
	default:
		return fmt.Errorf("unsupported layer media type %q", layer.MediaType)
	}

	tarReader := tar.NewReader(reader)
	for {
		header, err := tarReader.Next()
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			return fmt.Errorf("read layer: %w", err)
		}
		if err := extractEntry(root, header, tarReader); err != nil {
			return err
		}
	}
	return nil
}

func safePath(root, name string) (string, error) {
	clean := filepath.Clean(filepath.FromSlash(name))
	if clean == "." || filepath.IsAbs(clean) || clean == ".." || strings.HasPrefix(clean, ".."+string(filepath.Separator)) {
		return "", fmt.Errorf("unsafe layer path %q", name)
	}
	path := filepath.Join(root, clean)
	relative, err := filepath.Rel(root, path)
	if err != nil || relative == ".." || strings.HasPrefix(relative, ".."+string(filepath.Separator)) {
		return "", fmt.Errorf("layer path escapes root: %q", name)
	}
	return path, nil
}

func extractEntry(root string, header *tar.Header, reader io.Reader) error {
	name := strings.TrimPrefix(header.Name, "./")
	if name == "" || name == "." {
		return nil
	}
	if strings.HasPrefix(filepath.Base(name), ".wh.") {
		return fmt.Errorf("whiteouts are not supported in single-layer bundles: %q", name)
	}
	destination, err := safePath(root, name)
	if err != nil {
		return err
	}

	switch header.Typeflag {
	case tar.TypeDir:
		if err := os.MkdirAll(destination, os.FileMode(header.Mode)&0o777); err != nil {
			return err
		}
		return os.Chmod(destination, os.FileMode(header.Mode)&0o777)
	case tar.TypeReg, tar.TypeRegA:
		if err := os.MkdirAll(filepath.Dir(destination), 0o755); err != nil {
			return err
		}
		output, err := os.OpenFile(destination, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, os.FileMode(header.Mode)&0o777)
		if err != nil {
			return err
		}
		_, copyErr := io.Copy(output, reader)
		closeErr := output.Close()
		if copyErr != nil {
			return copyErr
		}
		if closeErr != nil {
			return closeErr
		}
		return os.Chmod(destination, os.FileMode(header.Mode)&0o777)
	case tar.TypeSymlink:
		if filepath.IsAbs(header.Linkname) {
			return fmt.Errorf("absolute symlink is not portable: %q -> %q", name, header.Linkname)
		}
		linkTarget := filepath.Clean(filepath.Join(filepath.Dir(name), filepath.FromSlash(header.Linkname)))
		if _, err := safePath(root, linkTarget); err != nil {
			return fmt.Errorf("unsafe symlink %q -> %q: %w", name, header.Linkname, err)
		}
		if err := os.MkdirAll(filepath.Dir(destination), 0o755); err != nil {
			return err
		}
		return os.Symlink(header.Linkname, destination)
	case tar.TypeLink:
		target, err := safePath(root, strings.TrimPrefix(header.Linkname, "./"))
		if err != nil {
			return fmt.Errorf("unsafe hardlink %q -> %q: %w", name, header.Linkname, err)
		}
		if err := os.MkdirAll(filepath.Dir(destination), 0o755); err != nil {
			return err
		}
		return os.Link(target, destination)
	case tar.TypeXGlobalHeader:
		return nil
	default:
		return fmt.Errorf("unsupported tar entry type %d for %q", header.Typeflag, name)
	}
}

func execApp(root, command string, args []string) error {
	executable := filepath.Join(root, "opt", "app", "bin", "app")
	arguments := append([]string{executable, command}, args...)
	if err := syscall.Exec(executable, arguments, os.Environ()); err != nil {
		return fmt.Errorf("execute extracted app: %w", err)
	}
	return nil
}
