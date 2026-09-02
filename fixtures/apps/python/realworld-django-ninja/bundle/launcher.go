package main

import (
	"fmt"
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
	python := filepath.Join(root, "python", "bin", "python3")
	entrypoint := filepath.Join(root, "entrypoint.py")

	environment := make([]string, 0, len(os.Environ())+3)
	for _, entry := range os.Environ() {
		key, _, _ := strings.Cut(entry, "=")
		if key != "PYTHONHOME" && key != "PYTHONPATH" && key != "REALWORLD_BUNDLE_ROOT" {
			environment = append(environment, entry)
		}
	}
	environment = append(environment,
		"PYTHONHOME="+filepath.Join(root, "python"),
		"PYTHONPATH="+filepath.Join(root, "site-packages")+":"+filepath.Join(root, "src"),
		"REALWORLD_BUNDLE_ROOT="+root,
	)
	arguments := append([]string{python, entrypoint}, os.Args[1:]...)
	if err := syscall.Exec(python, arguments, environment); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(126)
	}
}
