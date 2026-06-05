{
  evalSystem,
  ripgrep,
  runCommand,
}:
let
  machine = evalSystem (
    { lib, ... }:
    {
      system.bwrap.wrappers = [
        ripgrep.bwrap
      ];

      system.stateVersion = "26.05";
      fileSystems."/" = {
        device = "/test/dummy";
        fsType = "auto";
      };
      boot.loader.grub.enable = false;
    }
  );

  inherit (machine.config.system.build) toplevel;

  rg = "${toplevel}/sw/bin/rg";
in
runCommand "test-bwrap-ripgrep" { } ''
  ${rg} "hi"

  echo "RIPGREP_CWD_TEST" > test.txt
  cat test.txt

  if ! ${rg} RIPGREP; then
    echo "no matches found, CWD probably not bind-mounted"
    exit 1
  fi

  echo "ripgrep sandboxed :)"

  touch "$out"
''
