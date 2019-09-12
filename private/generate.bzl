"""This module constructs a vendor package built from a supplied vendor directory."""

_VENDOR_GENERATED_ROOT_BUILD_FILE = """
load("@bazel_gazelle//:def.bzl", "gazelle")

package(default_visibility = ["//visibility:public"])

gazelle(
    name = "gazelle",
    external = "vendored",
)

"""

def _vendor_generate_impl(ctx):
    gazelle_bin = ctx.path(ctx.attr._gazelle)
    lock_file = ctx.path(ctx.attr.src)

    # Location for generated package
    importpath = ctx.attr.importpath

    # GOPATH environment variable is set to this during generation to make Go tools happy
    gopath = ctx.path("")

    # Locate the nearest vendor directory (if one exists) starting from the
    # location of the vendor spec file.  This is sort of awful from a Bazel
    # perspective, because we're groping through the local host's filesystem.
    #
    # It would be better if there were a Bazel way to expose the vendor directory
    # in a way that we can access the files for our `cp` command down below.
    vendor_dir = locate_vendor_dir(lock_file)

    if ctx.attr.debug:
        print("Import path of package will be %s" % importpath)
        print("Vendor pacakges are at %s" % vendor_dir)

    # Gimme a vendor directory!
    if vendor_dir != "":
        cmds = ["cp", "-a", vendor_dir, "."]
        result = env_execute(ctx, cmds, environment = {"GOPATH": gopath})
        if result.return_code:
            fail("Can't copy vendor directory: %s" % result.stderr)

    # Don't do this for now:
    # ctx.file("vendor/BUILD.bazel", content=_VENDOR_GENERATED_VENDOR_BUILD_FILE, executable = False)

    ctx.file("BUILD.bazel", content = _VENDOR_GENERATED_ROOT_BUILD_FILE, executable = False)

    cmds = [
        gazelle_bin,
        "--go_prefix",
        importpath,
        "--mode",
        "fix",
        "--repo_root",
        gopath,
        "--external",
        "vendored",
    ]

    if ctx.attr.disable_protobuf_generation:
        cmds += [
            "--proto",
            "disable_global",
        ]

    result = env_execute(ctx, cmds)
    if result and result.return_code:
        fail("gazelle failed to generate BUILD files for: %s" % result.stderr)

    if ctx.attr.debug:
        print("Gazelle generated BUILD.bazel files for vendor package")

vendor_generate = repository_rule(
    implementation = _vendor_generate_impl,
    attrs = {
        "importpath": attr.string(
            doc = "Go prefix of import paths in the current workspace",
            mandatory = True,
        ),
        "src": attr.label(
            doc = "Label location for Gopkg.lock or go.mod",
            mandatory = True,
            allow_single_file = True,
        ),
        "_gazelle": attr.label(
            default = Label("@bazel_gazelle_go_repository_tools//:bin/gazelle"),
            allow_single_file = True,
            executable = True,
            cfg = "host",
        ),
        "debug": attr.bool(
            doc = "Toggle debugging output to console during build",
            default = False,
        ),
        "disable_protobuf_generation": attr.bool(
            doc = "Disable autogeneration of protobufs when running gazelle",
            default = False,
        ),
    },
)

def scan_dir(d):
    """Look in the supplied directory for a vendor or WORKSPACE entry.

    Args:
      d: full path to directory to be scanned.

    Returns:
      Success (boolean) and Full Path.
    """
    success = False
    path = ""

    if d.get_child("vendor").exists:
        # vendor exists, this is our match.  Return it to the caller as success
        path = d.get_child("vendor")
        success = True
    elif d.get_child("WORKSPACE").exists:
        # We should stop looking if we've reached the workspace root
        path = ""
        success = True

    return (success, path)

def locate_vendor_dir(d):
    """Walk backwards through the filesystem looking for a vendor directory.

    Args:
      d: full path to directory to be scanned.

    Returns:
      Full Path if successful, empty string if not.
    """

    # Bazel does not allow unbounded loops, so we fake it by iterating through
    # a list.  The length of our list is the effective "max depth" we will
    # crawl looking for our vendor directory.
    for _ in ["", "", "", "", "", "", "", "", "", "", "", ""]:
        (ok, path) = scan_dir(d)
        if ok:
            return path

        # remove the top level from our search path and iterate
        d = d.dirname

    # No vendor directory found
    return ""

def env_execute(ctx, arguments, environment = None, **kwargs):
    """Execute a shell command with the ability to set environment variables.

    Args:
      ctx: Current context
      arguments: Command line to run (list of strings)
      environment: Environment variables to be created (optional)
      **kwargs: Additional arguments passed directly to ctx.execute

    Returns:
      Returns the return code of ctx.execute called.
    """

    env_args = ["env", "-i"]

    if environment:
        for k, v in environment.items():
            env_args += ["%s=%s" % (k, v)]
        return ctx.execute(env_args + arguments, **kwargs)
    else:
        return ctx.execute(arguments, **kwargs)
