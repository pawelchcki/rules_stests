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

const treeArtifactDirectoryMarker = ".rules-stests-tree-artifact"

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "oci_rootfs_extract:", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) != 3 || (args[2] != "single" && args[2] != "multi") {
		return errors.New("usage: oci_rootfs_extract <oci-layout> <rootfs> <single|multi>")
	}
	return extractOCI(args[0], args[1], args[2] == "single")
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
		target, err := os.Stat(path)
		if errors.Is(err, os.ErrNotExist) {
			if err := os.Remove(path); err != nil {
				return fmt.Errorf("remove dangling OCI symlink %s: %w", path, err)
			}
			return nil
		} else if err != nil {
			return fmt.Errorf("inspect OCI symlink %s: %w", path, err)
		}
		if target.IsDir() {
			children, err := os.ReadDir(path)
			if err != nil {
				return fmt.Errorf("inspect OCI symlink directory %s: %w", path, err)
			}
			if len(children) == 0 {
				return preserveEmptySymlinkTarget(path, target)
			}
		}
		return nil
	})
}

func preserveEmptySymlinkTarget(path string, target os.FileInfo) (result error) {
	mode := target.Mode().Perm()
	if mode&0o200 == 0 {
		if err := os.Chmod(path, mode|0o200); err != nil {
			return fmt.Errorf("make empty OCI symlink target writable %s: %w", path, err)
		}
		defer func() {
			if err := os.Chmod(path, mode); err != nil && result == nil {
				result = fmt.Errorf("restore empty OCI symlink target mode %s: %w", path, err)
			}
		}()
	}
	marker := filepath.Join(path, treeArtifactDirectoryMarker)
	if err := os.WriteFile(marker, nil, 0o444); err != nil {
		return fmt.Errorf("preserve empty OCI symlink target %s: %w", path, err)
	}
	return nil
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
