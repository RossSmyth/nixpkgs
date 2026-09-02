#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p "python3.withPackages(ps: with ps; [ python-magic pytablewriter ])"
import json
import pathlib
import re
import subprocess

import magic
import pytablewriter

# Use this file to anchor when Chromium is vendored.
DETECTION_FILE = "v8_context_snapshot.bin"

# User-agent line. Most reliable method of getting the Electron version
ELECTRON_VERSION_DETECT = re.compile(rb"Electron/[0-9]*\.[0-9]*\.[0-9]")

# Chrome user-agent version regex
CEF_VERSION_DETECT = re.compile(rb"Chrome/[0-9]*\.[0-9]*\.[0-9]*(\.[0-9]*)?")


def get_electron_packages() -> List[str]:
    """List of packages with the detection anchor file within it"""
    return (
        subprocess.check_output(["nix-locate", "--minimal", DETECTION_FILE])
        .decode()
        .splitlines()
    )


def build_derivation(attr: str) -> Optional[str]:
    """Builds an attribute, and returns the outpath"""
    try:
        output = subprocess.check_output(["nix", "build", "-f.", "--quiet", "--json", attr])
        return json.loads(output)[0]["outputs"]["out"]
    except:
        # Outdated nix-index or something
        return None

def get_version(attr: str) -> str:
    return json.loads(subprocess.check_output(
        ["nix", "eval", "-f.", "--quiet", "--json", attr + ".version"]
    ))


def find_electron_bin(path: str) -> Optional[pathlib.Path]:
    """Takes in a path, should be a Nix store path, and returns any files with an Electron version string in it."""
    # Use libmagic/find to get mime
    find = magic.Magic(mime=True, uncompress=True)

    for dir, dirnames, filenames in pathlib.Path(path).walk(on_error=print):
        for file in filenames:
            real_file = dir / file

            # Ignore symlinks as they may point to a proper version
            if real_file.is_symlink():
                continue

            mime = find.from_file(real_file)

            # Some are detected as sharedlibs. That's fine.
            if "-sharedlib" not in mime and "-executable" not in mime:
                continue

            # These are ELF files so they must be opened as bytes
            with open(real_file, "rb") as f:
                content = f.read()

            # Just directly output the match.
            needle = ELECTRON_VERSION_DETECT.search(content)
            if needle:
                return needle.group(0)

    return None


def cef_fallback(path: str) -> Optional[str]:
    """Fallback for if it is Chromium-shaped, but not using Electron
    Directly returns the matched string.
    """
    # Libmagic again.
    find = magic.Magic(mime=True, uncompress=True)

    for dir, dirnames, filenames in pathlib.Path(path).walk(on_error=print):
        for file in filenames:
            real_file = dir / file
            if real_file.is_symlink():
                # Ignore symlinks
                continue

            mime = find.from_file(real_file)

            if "-sharedlib" not in mime and "-executable" not in mime:
                continue

            with open(real_file, "rb") as f:
                content = f.read()

            # Just directly output the match.
            needle = CEF_VERSION_DETECT.search(content)
            if needle:
                return needle.group(0)

    return None


def main():

    # Gather the package metadata we discover
    packages = {}

    items = get_electron_packages()

    print(f"Will be processing: {items}\n")

    for package in items:
        print(f"Building package: {package}")
        outpath = build_derivation(package)
        if outpath is None:
            # Failed to build, not much we can do.
            continue
        print(f"Built package: {package}, {outpath}")

        print(f"Searching for Electron in {package}")
        possible_electron = find_electron_bin(outpath)

        type = "Electron"

        if possible_electron:
            match = possible_electron.decode()
            print(f"Electron version: {match}")
        else:
            print(
                "Did not find Electron. Possibly a CEF package, will try CEF fallback."
            )
            type = "CEF"

            cef_match = cef_fallback(outpath)

            if cef_match:
                match = cef_match.decode()
                print(f"CEF version: {match}")
            else:
                print("Did not find CEF. Possible improperly devendored Electron?")
                type = "Unknown"
                match = "Unknown"
        print()

        packages[package] = [
            package,
            get_version(package),
            type,
            match.replace("/", " "),
        ]

    table = pytablewriter.MarkdownTableWriter(
        table_name="Vendored Electron/Chromium Packages",
        headers=["attribute", "Version", "Electron/CEF", "CEF/Electron Version"],
        value_matrix=list(packages.values()),
    )

    print(table.write_table())


if __name__ == "__main__":
    main()
