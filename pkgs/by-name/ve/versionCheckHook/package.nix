{
  lib,
  makeSetupHook,
  replaceVars,
  python3Minimal,
  bash
}:

makeSetupHook {
  name = "version-check-hook";
  substitutions = {
    python = python3Minimal.interpreter;
    pythonHook = replaceVars ./hook.py {
      storeDir = builtins.storeDir;
      bash = lib.getExe bash;
    };
  };
  meta = {
    description = "Lookup for $version in the output of --help and --version";
    maintainers = with lib.maintainers; [ doronbehar ];
  };
} ./hook.sh
