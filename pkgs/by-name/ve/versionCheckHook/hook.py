#!/usr/bin/env nix-shell
#! nix-shell -p python3Minimal
#! nix-shell -i python3

import os
import re
import sys
import subprocess
import argparse
import shlex

from pathlib import Path
from typing import List, Iterable

def get_parser() -> argparse.ArgumentParser:
    """
    Get argument parser
    """
    parser = argparse.Parser(
        prog = "versionCheckHook"
    )

    parser.add_argument("--version")
    parser.add_argument("--output-bin")
    parser.add_argument("--script")
    parser.add_argument("--keep-env")

def _handle_cmd_output(keep_environment: Iterable[str], *command: str) -> bool:
    """
    Executes a command and processes its output.
    """
    cmd = list(command)
    version = os.environ.get("version", "")

    # Set up environment variables
    env_vars = {key : os.environ[key] for key in keep_environment}

    try:
        # Use subprocess to run the command, capturing stdout and stderr
        process = subprocess.run(
            cmd,
            env=env_vars,
            capture_output=True,
            text=True,
            check=False,
        )
        version_output = process.stdout + process.stderr

        # Use re.sub() instead of sed for in-Python string replacement
        filtered_output = re.sub(r"@storeDir@/[^/ ]*/", "{{storeDir}}/", version_output)

    except FileNotFoundError:
        filtered_output = f"Command not found: {command[0]}"
        return False

    # Print debugging information to stderr
    print(
        f"{echo_prefix} find version {version!r} in the output of the command {' '.join(command)}",
        file=sys.stderr,
    )
    print(filtered_output, file=sys.stderr)

    if re.search(re.escape(version), filtered_output):
        return True
    else:
        return False

def main(args: List[str]):
    """
    Main hook for performing version checks.
    """
    print("Executing versionCheckPhase")

    version_check_keep_environment = shlex.split(os.environ.get("versionCheckKeepEnvironment", ""))
    echo_prefix = ""

    version_check_script = os.environ.get("versionCheckScript")
    if version_check_script:
        echo_prefix = _handle_cmd_output(version_check_keep_environment, "@bash@", "-c", version_check_script)
    else:
        cmd_program = None
        output_bin = os.environ.get("outputBin")
        pname = os.environ.get("pname")

        if os.environ.get("versionCheckProgram"):
            cmd_program = os.environ.get("versionCheckProgram")
        elif os.environ.get("NIX_MAIN_PROGRAM") and output_bin:
            cmd_program = f"{os.environ[output_bin]}/bin/{os.environ['NIX_MAIN_PROGRAM']}"
        elif pname:
            print(
                f"versionCheckHook: Package `{pname}` does not have the `meta.mainProgram` attribute. "
                "We'll assume that the main program has the same name for now, but this behavior is deprecated, "
                "because it leads to surprising errors when the assumption does not hold. "
                "If the package has a main program, please set `meta.mainProgram` in its definition to make this warning go away. "
                "Should the binary that outputs the intended version differ from `meta.mainProgram`, consider setting `versionCheckProgram` instead.",
                file=sys.stderr,
            )
            cmd_program = f"{os.environ[output_bin]}/bin/{pname}" if output_bin else None
        else:
            print(
                "versionCheckHook: $NIX_MAIN_PROGRAM, $versionCheckProgram and $pname are all empty, so "
                "we don't know how to run the versionCheckPhase. "
                "To fix this, set one of `meta.mainProgram` or `versionCheckProgram`.",
                file=sys.stderr,
            )
            sys.exit(2)

        if cmd_program and (not os.path.exists(cmd_program) or not os.access(cmd_program, os.X_OK)):
            print(f"versionCheckHook: {cmd_program} was not found, or is not an executable", file=sys.stderr)
            sys.exit(2)

        version_check_program_arg = os.environ.get("versionCheckProgramArg")
        if not version_check_program_arg:
            for cmd_arg in ["--help", "--version"]:
                if _handle_cmd_output(version_check_keep_environment, cmd_program, cmd_arg):
                    break
                else:
                    sys.exit(2)
        else:
            if not _handle_cmd_output(version_check_keep_environment, cmd_program, version_check_program_arg):
                sys.exit(2)

    print("Finished versionCheckPhase")

if __name__ == "__main__":
    main(sys.argv[1:])
