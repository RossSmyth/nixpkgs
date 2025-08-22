#!/usr/bin/env python3

import argparse

def get_args(args: List[str]):
    parser = argparse.ArgumentParser(
        prog = 'installShellCompletions',
        description = 'Install completions for programs to derivation outputs',
        allow_abbrev = False
    )

    parser.add_argument("--cmd", help = "Command that completions are for. This flag indicates that the files must be renamed.")
    parser.add_argument("--bash", help = "Install completion for Bash")
    parser.add_argument("--fish", help = "Install completion for Fish")
    parser.add_argument("--zsh", help = "Install completion for Zsh")
    parser.add_argument("--name", nargs = "2", help = "Set name of file to be installed.")
    parser.add_argument("paths", nargs = "*", help = 'Paths of completions to install')


if __name__ == '__main__':
    main()
