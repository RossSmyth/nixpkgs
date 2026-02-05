{
  lib,
  makeSetupHook,
  nodejsInstallManual,
  nodejsInstallExecutables,
  jq,
}:
makeSetupHook {
  name = "pnpm-install-hook";
  propagatedBuildInputs = [
    nodejsInstallManual
    nodejsInstallExecutables
  ];
  substitutions.jq = lib.getExe jq;
} ./pnpm-install-hook.sh
