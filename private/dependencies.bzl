load("@bazel_gazelle//:deps.bzl", "go_repository")

def vendor_dependencies():
    print("Generating vendor package for Bazel")
