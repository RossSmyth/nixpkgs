{
  lib,
  makeSetupHook,
  zip,
}:
makeSetupHook {
  name = "navidrome-plugin-install-hook";
  __structuredAttrs = true;

  propagatedBuildInputs = [
    zip
  ];

  meta.maintainers = [ lib.maintainers.RossSmyth ];
} ./install-hook.sh
