# Bazel Rules for Golang Vendored Dependencies

### Overview

### Setup

Add the following to your `WORKSPACE` file to load the rules and track your
vendor directory:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

git_repository(
    name = "com_activestate_rules_vendor",
    remote = "https://github.com/activestate/rules_vendor.git",
    tag = "v0.1.1",
)
load("@com_activestate_rules_vendor//:def.bzl", "vendor_dependencies", "vendor_generate")
vendor_dependencies()

vendor_generate(
    name = "vendor",
    src = "//:Gopkg.lock",
    importpath = "github.com/orgname/repo",
) 
```

In the `BUILD.bazel` file at your project root, add the following:

```python
exports_files(["Gopkg.lock", "Gopkg.yaml"])
```
