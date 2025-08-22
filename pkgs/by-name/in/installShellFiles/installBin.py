#!/usr/bin/env nix-shell
#! nix-shell -i python3
#! nix-shell -p python3Minimal
from typing import List
import argparse
import sys
import os
import pathlib
import logging
import re
import shutil

from enum import Enum

logger = logging.getLogger(__file__)

class NixLogLevel(Enum):
    ERROR = 0
    WARN = 1
    NOTICE = 2
    INFO = 3
    TALKATIVE = 4
    CHATTY = 5
    DEBUG = 6
    VOMIT = 7


def setup_logger() -> logging.Logger:
    """
        Trying to recreate _nixLogWithLEvel
    """
    log_fd = os.getenv("NIX_LOG_FD")
    nix_level = int(os.getenv("NIX_DEBUG", default = "0"))

    if not log_fd and nix_level < 1:
        # By requiring NIX_LOG_FD be set, we avoid dumping logging inside of nix-shell.
        dummy = logging.getLogger("dummy")
        dummy.setLevel(logging.DEBUG)
        dummy.addHandler(logging.NullHandler())
        return dummy

    log_stream = open(log_fd, 'a')

    log_level = None
    match nix_level:
        case NixLogLevel.ERROR:
            log_level = logging.ERROR
        case NixLogLevel.WARN:
            log_level = logging.WARNING
        case NixLogLevel.NOTICE | NixLogLevel.INFO:
            log_level = logging.INFO
        case NixLogLevel.TALKATIVE | NixLogLevel.CHATTY | NixLogLevel.DEBUG:
            log_level = logging.DEBUG
        case NixLogLevel.VOMIT:
            log_level = logging.NOTSET
        case _:
            log_stream.write(f"invalid log level: {nix_level}")
            raise f"invalid log level: {nix_level}"

    return logging.basicConfig(
            stream = log_stream,
            level = log_level,
        )

def strip_hash(path: str) -> str:
    """Return the base of a given path without the hash

    bash stripHash()

    """
    stripped_name = os.path.basename(path)

    if re.match("[a-z0-9]{32}-", stripped_name) != None:
        return stripped_name[33:]
    else:
        return stripped_name

def get_args(args: List[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="installBin",
        description = "Install executables to the output bin path",
        add_help = False
    )

    parser.add_argument("path",
        action = 'append',
        help = 'Paths of completions to install',
        # Cannot have the type as "pathlib.Path" because it
        # implicitly converts empty strings to "."
        type = str,
    )

    return parser.parse_known_args(args)[0]

def indirect_bash(var: str) -> str:
    """Try to recreate bash indirect variables
    outRoot=${!outputBin:?}
    """
    ref = os.getenv(var)
    if not ref:
        logger.error(f"environment variable '{var}' does not exist")

    var = os.getenv(ref)
    if not var:
        logger(f"environment variable '{var}' does not exist")

    return var


def main(args: List[str]):
    args = get_args(args)

    for path in args.path:
        if path == "":
            logger.error("path cannot be empty")
            exit(1)

        logger.info(f"installing {path}")
        basename = strip_hash(path)

        out_root = indirect_bash("outputBin")

        in_path = pathlib.Path(path)
        out_path = pathlib.Path(out_root) / 'bin' / basename

        out_path.parent.mkdir(parents = True, exist_ok = True)
        shutil.copy(path, out_path)
        out_path.chmod(0o755)



if __name__ == '__main__':
    setup_logger()
    main(sys.argv[1:])
