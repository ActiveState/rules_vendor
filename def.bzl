load(
    "@com_activestate_rules_vendor//private:dependencies.bzl",
    _vendor_dependencies = "vendor_dependencies"
)

load(
    "@com_activestate_rules_vendor//private:generate.bzl",
    _vendor_generate = "vendor_generate"
)

vendor_dependencies = _vendor_dependencies
vendor_generate = _vendor_generate
