{
  lib,
  callPackage,
  makeSetupHook,
  replaceVars,
  python3Minimal,
}:

# See the header comment in ./setup-hook.sh for example usage.
makeSetupHook {
  name = "install-shell-files";
  passthru = {
    tests = lib.packagesFromDirectoryRecursive {
      inherit callPackage;
      directory = ./tests;
    };
  };
} (replaceVars ./setup-hook.sh {
  PYTHON3 = python3Minimal.interpreter;
  INSTALL_BIN = ./installBin.py;
})
