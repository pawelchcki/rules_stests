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
	if len(args) == 0 {
		return errors.New("usage: oci_bundle extract <oci-layout> <rootfs> <single|multi> | app <instance> <rootfs> <command> [arguments...] | app-otel <instance> <rootfs> <otel-rootfs> <command> [arguments...]")
	}
	switch args[0] {
	case "extract":
		if len(args) != 4 || (args[3] != "single" && args[3] != "multi") {
			return errors.New("usage: oci_bundle extract <oci-layout> <rootfs> <single|multi>")
		}
		return extractOCI(args[1], args[2], args[3] == "single")
	case "app":
		if len(args) < 4 {
			return errors.New("usage: oci_bundle app <instance> <rootfs> <command> [arguments...]")
		}
		return runApp(args[1], args[2], "", args[3], args[4:])
	case "app-otel":
		if len(args) < 5 {
			return errors.New("usage: oci_bundle app-otel <instance> <rootfs> <otel-rootfs> <command> [arguments...]")
		}
		return runApp(args[1], args[2], args[3], args[4], args[5:])
	default:
		return fmt.Errorf("unsupported mode %q", args[0])
	}
}

func extractOCI(layoutArg, root string, singlePayload bool) error {
	layout, err := resolveDirectory(layoutArg)
	if err != nil {
		return err
	}
	manifestDigest, layers, err := readLayers(layout)
	if err != nil {
		return err
	}
	if singlePayload {
		layers, err = singlePayloadLayer(layout, layers)
		if err != nil {
			return err
		}
	}
	if err := extractFresh(layout, layers, root); err != nil {
		return err
	}
	if err := removeDanglingSymlinks(root); err != nil {
		return err
	}
	marker := filepath.Join(root, ".rules-stests-manifest")
	if err := os.WriteFile(marker, []byte(manifestDigest+"\n"), 0o444); err != nil {
		return fmt.Errorf("write extraction marker: %w", err)
	}
	return nil
}

func removeDanglingSymlinks(root string) error {
	return filepath.WalkDir(root, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.Type()&os.ModeSymlink == 0 {
			return nil
		}
		if _, err := os.Stat(path); errors.Is(err, os.ErrNotExist) {
			if err := os.Remove(path); err != nil {
				return fmt.Errorf("remove dangling OCI symlink %s: %w", path, err)
			}
			return nil
		} else if err != nil {
			return fmt.Errorf("inspect OCI symlink %s: %w", path, err)
		}
		return nil
	})
}

func runApp(instance, rootArg, otelRootArg, command string, args []string) error {
	if !validInstance(instance) {
		return fmt.Errorf("unsafe instance name %q", instance)
	}
	root, err := resolveDirectory(rootArg)
	if err != nil {
		return err
	}
	if err := prepareAppState(root, instance); err != nil {
		return err
	}
	otelRoot := ""
	if otelRootArg != "" {
		otelRoot, err = resolveDirectory(otelRootArg)
		if err != nil {
			return fmt.Errorf("resolve OpenTelemetry rootfs: %w", err)
		}
	}
	return execApp(root, otelRoot, instance, command, args)
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

func resolveDirectory(value string) (string, error) {
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
	return "", fmt.Errorf("directory %q is not present in runfiles", value)
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
		target := root
		if directory != "." {
			var err error
			target, err = safePath(root, directory)
			if err != nil {
				return err
			}
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

func execApp(root, otelRoot, instance, command string, args []string) error {
	appRoot := filepath.Join(root, "opt", "app")
	loader := filepath.Join(root, "lib64", "ld-linux-x86-64.so.2")
	python := filepath.Join(appRoot, "python", "bin", "python3")
	entrypoint := filepath.Join(appRoot, "entrypoint.py")
	libraryPath := strings.Join([]string{
		filepath.Join(root, "lib", "x86_64-linux-gnu"),
		filepath.Join(appRoot, "python", "lib"),
	}, ":")
	pythonPath := []string{
		filepath.Join(appRoot, "site-packages"),
		filepath.Join(appRoot, "src"),
	}
	if otelRoot != "" {
		instrumentation := filepath.Join(otelRoot, "autoinstrumentation")
		autoInstrumentation := filepath.Join(instrumentation, "opentelemetry", "instrumentation", "auto_instrumentation")
		if _, err := os.Stat(filepath.Join(autoInstrumentation, "sitecustomize.py")); err != nil {
			return fmt.Errorf("OpenTelemetry OCI rootfs has no Python activation hook: %w", err)
		}
		pythonPath = append([]string{autoInstrumentation}, pythonPath...)
		pythonPath = append(pythonPath, instrumentation)
	}

	environment := make([]string, 0, len(os.Environ())+7)
	present := make(map[string]bool)
	for _, entry := range os.Environ() {
		key, _, _ := strings.Cut(entry, "=")
		if key != "PYTHONHOME" && key != "PYTHONPATH" && key != "REALWORLD_BUNDLE_ROOT" {
			environment = append(environment, entry)
			present[key] = true
		}
	}
	environment = append(environment,
		"PYTHONHOME="+filepath.Join(appRoot, "python"),
		"PYTHONPATH="+strings.Join(pythonPath, ":"),
		"REALWORLD_BUNDLE_ROOT="+appRoot,
	)
	if otelRoot != "" {
		environment = appendDefaultEnvironment(environment, present, "OTEL_SERVICE_NAME", instance)
		environment = appendDefaultEnvironment(environment, present, "OTEL_TRACES_EXPORTER", "console")
		environment = appendDefaultEnvironment(environment, present, "OTEL_METRICS_EXPORTER", "none")
		environment = appendDefaultEnvironment(environment, present, "OTEL_LOGS_EXPORTER", "none")
		if _, err := os.Stat(filepath.Join(appRoot, "src", "manage.py")); err == nil {
			environment = appendDefaultEnvironment(environment, present, "DEBUG", "True")
			environment = appendDefaultEnvironment(environment, present, "DJANGO_SETTINGS_MODULE", "config.settings")
			database := filepath.Join(os.Getenv("APP_STATE_DIR"), "realworld.sqlite3")
			environment = appendDefaultEnvironment(environment, present, "DATABASE_URL", "file:"+database)
		}
		fmt.Fprintf(os.Stderr, "oci_bundle: activating OpenTelemetry Python instrumentation for %s from %s\n", instance, otelRoot)
	}
	arguments := []string{loader, "--library-path", libraryPath, python, entrypoint, command}
	arguments = append(arguments, args...)
	if err := syscall.Exec(loader, arguments, environment); err != nil {
		return fmt.Errorf("execute app with bundled glibc: %w", err)
	}
	return nil
}

func appendDefaultEnvironment(environment []string, present map[string]bool, key, value string) []string {
	if present[key] {
		return environment
	}
	return append(environment, key+"="+value)
}

func prepareAppState(root, instance string) error {
	state := os.Getenv("APP_STATE_DIR")
	if state == "" {
		testTmp := os.Getenv("TEST_TMPDIR")
		if testTmp == "" {
			return errors.New("TEST_TMPDIR or APP_STATE_DIR is required")
		}
		state = filepath.Join(testTmp, "rules_stests", instance, "state")
		if err := os.Setenv("APP_STATE_DIR", state); err != nil {
			return fmt.Errorf("set APP_STATE_DIR: %w", err)
		}
	}
	if err := os.MkdirAll(state, 0o755); err != nil {
		return fmt.Errorf("create app state: %w", err)
	}
	seed := filepath.Join(root, "opt", "app", "seed", "realworld.sqlite3")
	if _, err := os.Stat(seed); errors.Is(err, os.ErrNotExist) {
		return nil
	} else if err != nil {
		return fmt.Errorf("inspect app seed: %w", err)
	}
	database := filepath.Join(state, "realworld.sqlite3")
	if _, err := os.Stat(database); err == nil {
		return nil
	} else if !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("inspect app database: %w", err)
	}
	method, err := cloneOrCopyFile(seed, database)
	if err != nil {
		return fmt.Errorf("materialize app database seed: %w", err)
	}
	fmt.Fprintf(os.Stderr, "oci_bundle: materialized writable state via %s: %s\n", method, database)
	return nil
}

func cloneOrCopyFile(source, destination string) (string, error) {
	input, err := os.Open(source)
	if err != nil {
		return "", err
	}
	defer input.Close()
	temporary, err := os.CreateTemp(filepath.Dir(destination), ".realworld.sqlite3-")
	if err != nil {
		return "", err
	}
	temporaryPath := temporary.Name()
	committed := false
	defer func() {
		temporary.Close()
		if !committed {
			os.Remove(temporaryPath)
		}
	}()

	const ficlone = 0x40049409
	_, _, cloneErr := syscall.Syscall(syscall.SYS_IOCTL, temporary.Fd(), uintptr(ficlone), input.Fd())
	method := "reflink"
	if cloneErr != 0 {
		method = "copy fallback"
		if err := temporary.Truncate(0); err != nil {
			return "", err
		}
		if _, err := temporary.Seek(0, io.SeekStart); err != nil {
			return "", err
		}
		if _, err := input.Seek(0, io.SeekStart); err != nil {
			return "", err
		}
		if _, err := io.Copy(temporary, input); err != nil {
			return "", err
		}
	}
	if err := temporary.Chmod(0o600); err != nil {
		return "", err
	}
	if err := temporary.Close(); err != nil {
		return "", err
	}
	if err := os.Rename(temporaryPath, destination); err != nil {
		return "", err
	}
	committed = true
	return method, nil
}
