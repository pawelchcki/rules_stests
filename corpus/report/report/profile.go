package report

import (
	"encoding/json"
	"fmt"
	"sort"
	"strings"
)

type registryDocument struct {
	Features []struct {
		ID      string `json:"id"`
		Binding string `json:"binding"`
	} `json:"features"`
}

// CompileNormalizedProfile converts the readable Scheme authoring form to the
// deterministic data contract consumed by validation receipts and reporting.
func CompileNormalizedProfile(profileSource string, implementationSources []string, registryJSON, proofRuleSource, captureShapeSource []byte, scenarios []string) (NormalizedProfilePlan, error) {
	var registry registryDocument
	if err := json.Unmarshal(registryJSON, &registry); err != nil {
		return NormalizedProfilePlan{}, fmt.Errorf("decode standard registry: %w", err)
	}
	featureByBinding, knownIDs := map[string]string{}, map[string]bool{}
	for _, feature := range registry.Features {
		if feature.ID == "" || feature.Binding == "" || knownIDs[feature.ID] || featureByBinding[feature.Binding] != "" {
			return NormalizedProfilePlan{}, fmt.Errorf("standard registry contains duplicate or empty feature")
		}
		knownIDs[feature.ID], featureByBinding[feature.Binding] = true, feature.ID
	}
	knownShapes, err := parseKnownShapes(string(captureShapeSource))
	if err != nil {
		return NormalizedProfilePlan{}, err
	}
	rules, err := parseProofRules(string(proofRuleSource), knownShapes)
	if err != nil {
		return NormalizedProfilePlan{}, err
	}
	sources, implementationBindings := map[string]string{}, map[string]bool{}
	for _, source := range implementationSources {
		forms, parseErr := parseSource(source)
		if parseErr != nil {
			return NormalizedProfilePlan{}, parseErr
		}
		if collectErr := collectImplementationDefinitions(forms, implementationBindings, sources); collectErr != nil {
			return NormalizedProfilePlan{}, collectErr
		}
	}
	knownScenarios := stringSet(scenarios)
	forms, err := parseSource(profileSource)
	if err != nil {
		return NormalizedProfilePlan{}, err
	}
	var expression *sexpr
	for i := range forms {
		if found := findDefinition(&forms[i], "profile"); found != nil {
			expression = found
			break
		}
	}
	if expression == nil || head(*expression) != "realworld-profile" {
		return NormalizedProfilePlan{}, fmt.Errorf("profile definition must use realworld-profile")
	}
	plan := NormalizedProfilePlan{SchemaVersion: 1, Sources: map[string]string{}}
	seenClaims := map[string]bool{}
	for _, clause := range expression.list[1:] {
		switch head(clause) {
		case "id":
			if len(clause.list) != 2 {
				return plan, fmt.Errorf("profile id clause is malformed")
			}
			plan.Profile = atomValue(unquote(clause.list[1]))
		case "display-name":
			if len(clause.list) != 2 || !clause.list[1].str {
				return plan, fmt.Errorf("profile display-name clause is malformed")
			}
			plan.DisplayName = clause.list[1].atom
		case "language":
			if len(clause.list) != 2 {
				return plan, fmt.Errorf("profile language clause is malformed")
			}
			plan.Language = atomValue(unquote(clause.list[1]))
		case "framework":
			if len(clause.list) != 2 || !clause.list[1].str {
				return plan, fmt.Errorf("profile framework clause is malformed")
			}
			plan.Framework = clause.list[1].atom
		case "service-name":
			if len(clause.list) != 2 || !clause.list[1].str {
				return plan, fmt.Errorf("profile service-name clause is malformed")
			}
			plan.ServiceName = clause.list[1].atom
		case "signals":
			for _, signal := range clause.list[1:] {
				plan.Signals = append(plan.Signals, atomValue(unquote(signal)))
			}
		case "implementation":
			if len(clause.list) != 2 || head(clause.list[1]) != "compose" {
				return plan, fmt.Errorf("profile implementation must use compose")
			}
			for _, item := range clause.list[1].list[1:] {
				binding := atomValue(item)
				if !implementationBindings[binding] {
					return plan, fmt.Errorf("unknown implementation binding %q", binding)
				}
				plan.Implementations = append(plan.Implementations, binding)
			}
		case "all", "scenario":
			proofs, parseErr := parseProfileClaim(clause, featureByBinding, sources, rules, knownScenarios)
			if parseErr != nil {
				return plan, parseErr
			}
			for _, proof := range proofs {
				if seenClaims[proof.FeatureID] {
					return plan, fmt.Errorf("duplicate feature claim %q", proof.FeatureID)
				}
				seenClaims[proof.FeatureID] = true
				plan.Proofs = append(plan.Proofs, proof)
				for _, name := range proof.Sources {
					plan.Sources[name] = sources[name]
				}
			}
		}
	}
	if plan.Profile == "" || plan.DisplayName == "" || plan.Language == "" || plan.Framework == "" || plan.ServiceName == "" || len(plan.Signals) == 0 || len(plan.Implementations) == 0 || len(plan.Proofs) == 0 {
		return plan, fmt.Errorf("profile metadata is incomplete")
	}
	if plan.Language != "go" && plan.Language != "python" {
		return plan, fmt.Errorf("unsupported profile language %q", plan.Language)
	}
	for _, signal := range plan.Signals {
		if signal != "traces" && signal != "metrics" && signal != "logs" {
			return plan, fmt.Errorf("unknown signal %q", signal)
		}
	}
	sort.Slice(plan.Proofs, func(i, j int) bool { return plan.Proofs[i].FeatureID < plan.Proofs[j].FeatureID })
	return plan, nil
}

type parsedRule struct{ assertion, policy string }

func parseKnownShapes(source string) (map[string]bool, error) {
	forms, err := parseSource(source)
	if err != nil {
		return nil, err
	}
	var value *sexpr
	for i := range forms {
		if found := findDefinition(&forms[i], "known-shapes"); found != nil {
			value = found
			break
		}
	}
	if value == nil {
		return nil, fmt.Errorf("known-shapes definition is missing")
	}
	shapes := map[string]bool{}
	for _, item := range unquote(*value).list {
		name := atomValue(item)
		if name == "" || shapes[name] {
			return nil, fmt.Errorf("duplicate or empty capture shape %q", name)
		}
		shapes[name] = true
	}
	if len(shapes) == 0 {
		return nil, fmt.Errorf("known-shapes definition is empty")
	}
	return shapes, nil
}

func parseProofRules(source string, knownShapes map[string]bool) (map[string]parsedRule, error) {
	forms, err := parseSource(source)
	if err != nil {
		return nil, err
	}
	var values []sexpr
	var visit func(sexpr)
	visit = func(expr sexpr) {
		if head(expr) == "define" && len(expr.list) == 3 {
			name := atomValue(expr.list[1])
			if name == "proof-rules" || strings.HasSuffix(name, "-proof-rules") {
				values = append(values, unquote(expr.list[2]))
			}
		}
		for _, child := range expr.list {
			visit(child)
		}
	}
	for _, form := range forms {
		visit(form)
	}
	if len(values) == 0 {
		return nil, fmt.Errorf("proof-rules definition is missing")
	}
	rules := map[string]parsedRule{}
	for _, list := range values {
		for _, item := range list.list {
			if len(item.list) != 3 || !item.list[0].str {
				return nil, fmt.Errorf("malformed proof rule")
			}
			id := item.list[0].atom
			if rules[id].assertion != "" {
				return nil, fmt.Errorf("duplicate proof rule %q", id)
			}
			assertion, policy := atomValue(item.list[1]), atomValue(item.list[2])
			if !knownShapes[assertion] {
				return nil, fmt.Errorf("proof rule %q references unknown capture shape %q", id, assertion)
			}
			if policy != "wire-sufficient" && policy != "requires-immutable-source" {
				return nil, fmt.Errorf("proof rule %q has invalid evidence policy %q", id, policy)
			}
			rules[id] = parsedRule{assertion, policy}
		}
	}
	return rules, nil
}

func parseProfileClaim(clause sexpr, featureByBinding, sources map[string]string, rules map[string]parsedRule, knownScenarios map[string]bool) ([]ProofPlanProof, error) {
	var scenarios []string
	var body sexpr
	if head(clause) == "all" {
		if len(clause.list) != 2 {
			return nil, fmt.Errorf("all claim is malformed")
		}
		body = clause.list[1]
	} else {
		if len(clause.list) != 3 {
			return nil, fmt.Errorf("scenario claim is malformed")
		}
		name := atomValue(unquote(clause.list[1]))
		if name == "" {
			return nil, fmt.Errorf("scenario claim has empty scope")
		}
		if !knownScenarios[name] {
			return nil, fmt.Errorf("scenario claim has unknown scope %q", name)
		}
		scenarios = []string{name}
		body = clause.list[2]
	}
	basis := head(body)
	var featureExprs []sexpr
	var sourceNames []string
	if basis == "observed" {
		if len(body.list) < 2 {
			return nil, fmt.Errorf("observed claim is malformed")
		}
		featureExprs = body.list[1:]
	} else if basis == "corroborated" {
		if len(body.list) < 3 || head(body.list[1]) != "sources" {
			return nil, fmt.Errorf("corroborated claim is malformed")
		}
		featureExprs = body.list[2:]
		for _, source := range body.list[1].list[1:] {
			name := atomValue(source)
			href := sources[name]
			if href == "" {
				return nil, fmt.Errorf("unknown source anchor %q", name)
			}
			if err := validateImmutableSource(href); err != nil {
				return nil, fmt.Errorf("source anchor %q: %w", name, err)
			}
			sourceNames = append(sourceNames, name)
		}
	} else {
		return nil, fmt.Errorf("invalid claim basis %q", basis)
	}
	proofs := make([]ProofPlanProof, 0, len(featureExprs))
	for _, featureExpr := range featureExprs {
		proof := ProofPlanProof{Basis: basis, Scenarios: append([]string(nil), scenarios...), Sources: append([]string(nil), sourceNames...)}
		binding := atomValue(featureExpr)
		proof.FeatureID = featureByBinding[binding]
		if proof.FeatureID == "" {
			return nil, fmt.Errorf("unknown feature binding %q", binding)
		}
		rule, ok := rules[proof.FeatureID]
		if !ok {
			return nil, fmt.Errorf("feature %q has no proof rule", proof.FeatureID)
		}
		proof.Assertion, proof.EvidencePolicy = rule.assertion, rule.policy
		if rule.policy == "requires-immutable-source" && len(proof.Sources) == 0 {
			return nil, fmt.Errorf("feature %q requires immutable source", proof.FeatureID)
		}
		if rule.policy == "wire-sufficient" && proof.Basis != "observed" {
			return nil, fmt.Errorf("feature %q must use observed basis", proof.FeatureID)
		}
		proofs = append(proofs, proof)
	}
	return proofs, nil
}

func parseSource(source string) ([]sexpr, error) {
	tokens, err := tokenizeScheme(source)
	if err != nil {
		return nil, err
	}
	return parseScheme(tokens)
}

func collectImplementationDefinitions(forms []sexpr, bindings map[string]bool, sources map[string]string) error {
	var result error
	var visit func(sexpr)
	visit = func(expr sexpr) {
		if result != nil {
			return
		}
		if head(expr) == "define" && len(expr.list) == 3 {
			name := atomValue(expr.list[1])
			if name != "" {
				if bindings[name] {
					result = fmt.Errorf("duplicate implementation binding %q", name)
					return
				}
				bindings[name] = true
				if expr.list[2].str {
					sources[name] = expr.list[2].atom
				}
			}
		}
		for _, child := range expr.list {
			visit(child)
		}
	}
	for _, form := range forms {
		visit(form)
	}
	return result
}
