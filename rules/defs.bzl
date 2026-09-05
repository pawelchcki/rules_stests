"""Public API for rules_stests."""

load("//rules:hurl_test.bzl", _REALWORLD_HURL_CASES = "REALWORLD_HURL_CASES", _realworld_hurl_test_suite = "realworld_hurl_test_suite")
load("//rules:oci_rootfs.bzl", _oci_rootfs = "oci_rootfs")
load("//rules:otel_profile.bzl", _otel_realworld_profile = "otel_realworld_profile", _otel_report_manifest = "otel_report_manifest", _otel_standard_registry = "otel_standard_registry")
load("//rules:realworld_app.bzl", _REALWORLD_APPS = "REALWORLD_APPS", _otel_injection = "otel_injection", _otlp_env = "otlp_env", _python_auto_injection = "python_auto_injection", _otel_variant = "otel_variant", _realworld_app_suite = "realworld_app_suite", _ruby_auto_injection = "ruby_auto_injection")

REALWORLD_APPS = _REALWORLD_APPS
REALWORLD_HURL_CASES = _REALWORLD_HURL_CASES
oci_rootfs = _oci_rootfs
otel_injection = _otel_injection
otel_realworld_profile = _otel_realworld_profile
otel_report_manifest = _otel_report_manifest
otel_standard_registry = _otel_standard_registry
otlp_env = _otlp_env
python_auto_injection = _python_auto_injection
otel_variant = _otel_variant
realworld_app_suite = _realworld_app_suite
realworld_hurl_test_suite = _realworld_hurl_test_suite
ruby_auto_injection = _ruby_auto_injection
