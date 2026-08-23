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
	Size      int64  `json:"size"`
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
		return errors.New("usage: oci_bundle <prepare|serve|check|hurl> <instance> <oci-layout> [arguments...]")
	}
	mode, instance, layoutArg := args[0], args[1], args[2]
	if mode != "prepare" && mode != "serve" && mode != "check" && mode != "hurl" {
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
	manifestDigest, layers, err := readLayers(layout)
	if err != nil {
		return err
	}
	if mode != "hurl" {
		layers, err = singlePayloadLayer(layout, layers)
		if err != nil {
			return err
		}
	}

	root := filepath.Join(testTmp, "rules_stests", instance, "rootfs")
	marker := filepath.Join(root, ".rules-stests-manifest")
	prepared, err := markerMatches(marker, manifestDigest)
	if err != nil {
		return err
	}
	if !prepared {
		if err := extractFresh(layout, layers, root); err != nil {
			return err
		}
		if err := os.WriteFile(marker, []byte(manifestDigest+"\n"), 0o644); err != nil {
			return fmt.Errorf("write extraction marker: %w", err)
		}
	}
	if mode == "hurl" {
		return execHurl(root, args[3:])
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

func readLayers(layout string) (string, []descriptor, error) {
	var idx index
	if err := readJSON(filepath.Join(layout, "index.json"), &idx); err != nil {
		return "", nil, fmt.Errorf("read OCI index: %w", err)
	}
	if len(idx.Manifests) != 1 {
		return "", nil, fmt.Errorf("expected one OCI manifest, got %d", len(idx.Manifests))
	}
	manifestPath, err := blobPath(layout, idx.Manifests[0].Digest)
	if err != nil {
		return "", nil, err
	}
	if err := verifyBlob(manifestPath, idx.Manifests[0].Digest); err != nil {
		return "", nil, err
	}
	var imageManifest manifest
	if err := readJSON(manifestPath, &imageManifest); err != nil {
		return "", nil, fmt.Errorf("read OCI manifest: %w", err)
	}
	if len(imageManifest.Layers) == 0 {
		return "", nil, errors.New("OCI manifest has no layers")
	}
	return idx.Manifests[0].Digest, imageManifest.Layers, nil
}

func singlePayloadLayer(layout string, layers []descriptor) ([]descriptor, error) {
	payloadLayers := make([]descriptor, 0, 1)
	for _, layer := range layers {
		if layer.Size > 1024 {
			payloadLayers = append(payloadLayers, layer)
			continue
		}
		if err := verifyEmptyLayer(layout, layer); err != nil {
			return nil, err
		}
	}
	if len(payloadLayers) != 1 {
		return nil, fmt.Errorf("portable app images must contain exactly one non-empty payload layer, got %d", len(payloadLayers))
	}
	return payloadLayers, nil
}

func verifyEmptyLayer(layout string, layer descriptor) error {
	blob, err := blobPath(layout, layer.Digest)
	if err != nil {
		return err
	}
	if err := verifyBlob(blob, layer.Digest); err != nil {
		return err
	}
	file, err := os.Open(blob)
	if err != nil {
		return err
	}
	defer file.Close()
	reader, closeReader, err := layerReader(file, layer.MediaType)
	if err != nil {
		return err
	}
	defer closeReader()
	if _, err := tar.NewReader(reader).Next(); !errors.Is(err, io.EOF) {
		if err == nil {
			return fmt.Errorf("small OCI layer %s is not empty", layer.Digest)
		}
		return fmt.Errorf("read small OCI layer %s: %w", layer.Digest, err)
	}
	return nil
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

func extractFresh(layout string, layers []descriptor, root string) error {
	if err := os.RemoveAll(root); err != nil {
		return fmt.Errorf("clear old bundle root: %w", err)
	}
	if err := os.MkdirAll(root, 0o755); err != nil {
		return fmt.Errorf("create bundle root: %w", err)
	}
	for _, layer := range layers {
		if err := extractLayer(layout, layer, root); err != nil {
			return err
		}
	}
	return nil
}

func extractLayer(layout string, layer descriptor, root string) error {
	blob, err := blobPath(layout, layer.Digest)
	if err != nil {
		return err
	}
	if err := verifyBlob(blob, layer.Digest); err != nil {
		return err
	}

	file, err := os.Open(blob)
	if err != nil {
		return err
	}
	defer file.Close()

	reader, closeReader, err := layerReader(file, layer.MediaType)
	if err != nil {
		return err
	}
	defer closeReader()

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

func layerReader(file *os.File, mediaType string) (io.Reader, func() error, error) {
	switch mediaType {
	case "application/vnd.oci.image.layer.v1.tar+gzip", "application/vnd.docker.image.rootfs.diff.tar.gzip":
		compressed, err := gzip.NewReader(file)
		if err != nil {
			return nil, nil, fmt.Errorf("open gzip layer: %w", err)
		}
		return compressed, compressed.Close, nil
	case "application/vnd.oci.image.layer.v1.tar", "application/vnd.docker.image.rootfs.diff.tar":
		return file, func() error { return nil }, nil
	default:
		return nil, nil, fmt.Errorf("unsupported layer media type %q", mediaType)
	}
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
	base := filepath.Base(name)
	if strings.HasPrefix(base, ".wh.") {
		return applyWhiteout(root, name)
	}
	destination, err := safePath(root, name)
	if err != nil {
		return err
	}

	switch header.Typeflag {
	case tar.TypeDir:
		if info, statErr := os.Lstat(destination); statErr == nil && !info.IsDir() {
			if err := os.RemoveAll(destination); err != nil {
				return err
			}
		}
		if err := os.MkdirAll(destination, os.FileMode(header.Mode)&0o777); err != nil {
			return err
		}
		return os.Chmod(destination, os.FileMode(header.Mode)&0o777)
	case tar.TypeReg, tar.TypeRegA:
		if err := os.RemoveAll(destination); err != nil {
			return err
		}
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
		linkName := filepath.FromSlash(header.Linkname)
		if filepath.IsAbs(header.Linkname) {
			rootTarget := strings.TrimPrefix(filepath.Clean(linkName), string(filepath.Separator))
			if _, err := safePath(root, rootTarget); err != nil {
				return fmt.Errorf("unsafe absolute symlink %q -> %q: %w", name, header.Linkname, err)
			}
			linkName, err = filepath.Rel(filepath.Dir(filepath.FromSlash(name)), rootTarget)
			if err != nil {
				return fmt.Errorf("rewrite absolute symlink %q -> %q: %w", name, header.Linkname, err)
			}
		}
		linkTarget := filepath.Clean(filepath.Join(filepath.Dir(name), linkName))
		if _, err := safePath(root, linkTarget); err != nil {
			return fmt.Errorf("unsafe symlink %q -> %q: %w", name, header.Linkname, err)
		}
		if err := os.RemoveAll(destination); err != nil {
			return err
		}
		if err := os.MkdirAll(filepath.Dir(destination), 0o755); err != nil {
			return err
		}
		return os.Symlink(linkName, destination)
	case tar.TypeLink:
		target, err := safePath(root, strings.TrimPrefix(header.Linkname, "./"))
		if err != nil {
			return fmt.Errorf("unsafe hardlink %q -> %q: %w", name, header.Linkname, err)
		}
		if err := os.MkdirAll(filepath.Dir(destination), 0o755); err != nil {
			return err
		}
		if err := os.RemoveAll(destination); err != nil {
			return err
		}
		return os.Link(target, destination)
	case tar.TypeXGlobalHeader:
		return nil
	default:
		return fmt.Errorf("unsupported tar entry type %d for %q", header.Typeflag, name)
	}
}

func applyWhiteout(root, name string) error {
	base := filepath.Base(name)
	directory := filepath.Dir(name)
	if base == ".wh..wh..opq" {
		target, err := safePath(root, directory)
		if err != nil {
			return err
		}
		entries, err := os.ReadDir(target)
		if errors.Is(err, os.ErrNotExist) {
			return nil
		}
		if err != nil {
			return err
		}
		for _, entry := range entries {
			if err := os.RemoveAll(filepath.Join(target, entry.Name())); err != nil {
				return err
			}
		}
		return nil
	}
	target, err := safePath(root, filepath.Join(directory, strings.TrimPrefix(base, ".wh.")))
	if err != nil {
		return err
	}
	return os.RemoveAll(target)
}

func execApp(root, command string, args []string) error {
	executable := filepath.Join(root, "opt", "app", "bin", "app")
	arguments := append([]string{executable, command}, args...)
	if err := syscall.Exec(executable, arguments, os.Environ()); err != nil {
		return fmt.Errorf("execute extracted app: %w", err)
	}
	return nil
}

func execHurl(root string, args []string) error {
	loader := filepath.Join(root, "lib", "ld-musl-x86_64.so.1")
	executable := filepath.Join(root, "usr", "bin", "hurl")
	libraryPath := strings.Join([]string{filepath.Join(root, "lib"), filepath.Join(root, "usr", "lib")}, ":")
	arguments := append([]string{loader, "--library-path", libraryPath, executable}, args...)
	if err := syscall.Exec(loader, arguments, os.Environ()); err != nil {
		return fmt.Errorf("execute extracted Hurl: %w", err)
	}
	return nil
}
