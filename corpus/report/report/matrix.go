package report

import (
	"bufio"
	"fmt"
	"regexp"
	"strings"
	"unicode"
)

var markdownLink = regexp.MustCompile(`^\*{0,2}\[([^]]+)\]\(([^)]+)\)\*{0,2}$`)
var inlineMarkdownLink = regexp.MustCompile(`\[([^]]+)\]\([^)]+\)`)

func ImportMatrix(markdown string, source CatalogSource) ([]Feature, error) {
	if source.Revision == "" || source.URL == "" || source.RawURL == "" || source.SHA256 == "" {
		return nil, fmt.Errorf("catalog source metadata must include revision, URL, raw URL, and SHA256")
	}
	var features []Feature
	seen := map[string]bool{}
	category, group := "", ""
	var headers map[string]int
	lineNumber := 0
	scanner := bufio.NewScanner(strings.NewReader(markdown))
	scanner.Buffer(make([]byte, 4096), 1024*1024)
	for scanner.Scan() {
		lineNumber++
		line := strings.TrimSpace(scanner.Text())
		if strings.HasPrefix(line, "## ") {
			category = strings.TrimSpace(strings.TrimPrefix(line, "## "))
			group, headers = "", nil
			continue
		}
		if !strings.HasPrefix(line, "|") || category == "" {
			continue
		}
		cells := splitMarkdownRow(line)
		if len(cells) < 2 || isSeparatorRow(cells) {
			continue
		}
		if cleanMarkdown(cells[0]) == "Feature" {
			headers = map[string]int{}
			for i, cell := range cells {
				headers[cleanMarkdown(cell)] = i
			}
			if _, ok := headers["Go"]; !ok {
				return nil, fmt.Errorf("line %d: feature table lacks Go column", lineNumber)
			}
			if _, ok := headers["Python"]; !ok {
				return nil, fmt.Errorf("line %d: feature table lacks Python column", lineNumber)
			}
			continue
		}
		if headers == nil {
			continue
		}
		goIndex, pythonIndex := headers["Go"], headers["Python"]
		if goIndex >= len(cells) || pythonIndex >= len(cells) {
			return nil, fmt.Errorf("line %d: row has fewer cells than its header", lineNumber)
		}
		name, href := parseFeatureCell(cells[0])
		if cleanMarkdown(cells[goIndex]) == "Go" && cleanMarkdown(cells[pythonIndex]) == "Python" {
			group = name
			continue
		}
		if name == "" {
			return nil, fmt.Errorf("line %d: empty feature name", lineNumber)
		}
		id := featureID(category, group, name)
		if seen[id] {
			return nil, fmt.Errorf("line %d: duplicate feature id %q", lineNumber, id)
		}
		seen[id] = true
		optional := ""
		if index, ok := headers["Optional"]; ok && index < len(cells) {
			optional = cleanMarkdown(cells[index])
		}
		featureSource := fmt.Sprintf("%s#L%d", source.URL, lineNumber)
		if href != "" {
			featureSource = resolveSourceLink(href, source.Revision)
		}
		features = append(features, Feature{
			ID: id, Category: category, Group: group, Name: name, Optional: optional,
			Support: map[string]string{
				"go":     supportState(cells[goIndex]),
				"python": supportState(cells[pythonIndex]),
			},
			Source: featureSource,
		})
	}
	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("read compliance matrix: %w", err)
	}
	if len(features) == 0 {
		return nil, fmt.Errorf("compliance matrix contains no Go/Python features")
	}
	return features, nil
}

func FeatureID(category, group, name string) string { return featureID(category, group, name) }

func featureID(category, group, name string) string {
	parts := []string{slug(category)}
	if group != "" {
		parts = append(parts, slug(group))
	}
	parts = append(parts, slug(name))
	return strings.Join(parts, ".")
}

func slug(value string) string {
	var out strings.Builder
	dash := false
	for _, r := range strings.ToLower(cleanMarkdown(value)) {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			out.WriteRune(r)
			dash = false
		} else if out.Len() > 0 && !dash {
			out.WriteByte('-')
			dash = true
		}
	}
	return strings.Trim(out.String(), "-")
}

func splitMarkdownRow(line string) []string {
	line = strings.TrimSpace(strings.Trim(line, "|"))
	raw := strings.Split(line, "|")
	for i := range raw {
		raw[i] = strings.TrimSpace(raw[i])
	}
	return raw
}

func isSeparatorRow(cells []string) bool {
	for _, cell := range cells {
		value := strings.Trim(cell, " :-")
		if value != "" {
			return false
		}
	}
	return true
}

func parseFeatureCell(cell string) (string, string) {
	cell = strings.TrimSpace(cell)
	if match := markdownLink.FindStringSubmatch(cell); match != nil {
		return cleanMarkdown(match[1]), match[2]
	}
	return cleanMarkdown(cell), ""
}

func cleanMarkdown(value string) string {
	value = strings.TrimSpace(value)
	if match := markdownLink.FindStringSubmatch(value); match != nil {
		value = match[1]
	}
	value = inlineMarkdownLink.ReplaceAllString(value, "$1")
	value = strings.ReplaceAll(value, "**", "")
	value = strings.ReplaceAll(value, "`", "")
	return strings.TrimSpace(strings.ReplaceAll(value, "\\|", "|"))
}

func supportState(value string) string {
	value = strings.TrimSpace(value)
	switch {
	case value == "+":
		return "supported"
	case value == "N/A":
		return "n/a"
	case value == "-" || strings.HasPrefix(value, "[-]"):
		return "unsupported"
	default:
		return "unknown"
	}
}

func resolveSourceLink(href, revision string) string {
	if strings.HasPrefix(href, "https://") || strings.HasPrefix(href, "http://") {
		return href
	}
	return "https://github.com/open-telemetry/opentelemetry-specification/blob/" + revision + "/" + strings.TrimPrefix(href, "./")
}
