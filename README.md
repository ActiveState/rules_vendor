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

### Caveats

Ideally this will be paired with an extension to
[Gazelle](https://github.com/bazelbuild/bazel-gazelle) to write the correct
form for the deps to your build files.  For now, though, you will probably find
it useful to post-process Gazelle-maintained build files with something along
these lines:

```
bazel run //:gazelle
find . -name BUILD.bazel | xargs sed -i bak 's/\"\/\/vendor/\"@vendor\/\/vendor/'
find . -name BUILD.bazelbak -delete
```

This is admittedly unwieldy, but it's functional.  A more elegant solution is
on the roadmap.

You will also want to make sure that you exclude your vendor directory from
being processed by Gazelle by placing this in your BUILD file as well.

```
# gazelle:exclude vendor
```
