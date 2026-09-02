package report

import (
	_ "embed"
	"strings"
)

// The front end lives in web/ as ordinary reviewable files. They are embedded
// and stitched into one self-contained page: the published report is inlined by
// the CI toolkit, so it must never reference an external asset.

//go:embed web/index.html
var indexHTML string

//go:embed web/style.css
var styleCSS string

//go:embed web/app.js
var appJS string

// reportHTML is the page skeleton with the stylesheet and script inlined and
// __REPORT_DATA__ still waiting for the serialized model.
var reportHTML = stitch()

func stitch() string {
	page := strings.Replace(indexHTML, "__STYLE__", styleCSS, 1)
	return strings.Replace(page, "__SCRIPT__", appJS, 1)
}
