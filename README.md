# Bazel Rules for Golang Vendored Dependencies

### Overview

This repository contains a set of rules which allow you to build Go [vendor
directories](https://golang.org/cmd/go/#hdr-Vendor_Directories) as a native,
labelled [Bazel](https://bazel.build) package instead of building them inline
from your project repository

With this rule, your `BUILD.bazel` deps for vendor packages will change from:

```
//vendor/github.com/organization/repo:tag:go_default_library
```

to this form:

```
@vendor//vendor/github.com/organization/repo:tag:go_default_library
```

This moves all the vendored dependencies to a Bazel label so that they can
referenced identically even across multiple packages within your Bazel build
workspace.  This is particularly useful for packaged, generated code like when
using [go-swagger](https://goswagger.io) where it's necessary to share a common
set of vendor dependencies across the Bazel package boundaries.

This allows the generated code and the main project code to identically import
deps from a consistent Bazel import path, which is necesary to keep Bazel
consistent and caching effectively.  It also prevents errors arising from
structures being passed across package boundaries introducing namespace
conflicts.

Building the vendor package is driven by your `Gopkg.lock` file, so unnecessary
rebuilds will be avoided until the lock file is updated.

### Setup

Add the following to your `WORKSPACE` file to load the rules and track your
vendor directory:

```python
http_archive(
    name = "com_activestate_rules_vendor",
    urls = ["https://github.com/ActiveState/rules_vendor/archive/v0.1.3.tar.gz"],
    sha256 = "2f87901be842aac9d1327299dd3016d05752351498ab1b26f132c1a592ee4946",
    strip_prefix = "rules_vendor-0.1.3",
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

This should also work fine exporting `go.mod` and `go.sum` if you are using
Go Modules instead of dep.  Just change the corresponding `src` label in your
WORKSPACE `vendor_generate` to match.

### Caveats

Ideally this will be paired with an extension to
[Gazelle](https://github.com/bazelbuild/bazel-gazelle) to write the correct
form for the deps to your build files.  For now, though, you will probably find
it useful to post-process Gazelle-maintained build files with something along
these lines:

```
bazel run //:gazelle
find . -name BUILD.bazel | xargs sed -ibak 's%"//vendor%"@vendor//vendor%'
find . -name BUILD.bazelbak -delete
```

This is admittedly unwieldy, but it's functional.  A more elegant solution is
on the roadmap.

You will also want to make sure that you exclude your vendor directory from
being processed by Gazelle by placing this in your BUILD file as well.

```
# gazelle:exclude vendor
```
