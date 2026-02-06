{
  lib,
  stdenv,
  makeSetupHook,
  replaceVars,
  targetPackages,
  makeBinaryWrapper,
  electron,
  # Test packages
  mattermost-desktop,
  rocketchat-desktop,
  signal-desktop,
  bitwarden-desktop,
  mqtt-explorer,
}:
# These must be in buildInputs so that the correct Electron is used, which is the
# Electron for the host, not the Electron for the build machine, which would be the
# one passed if this hook was in `nativeBuildInputs`. This is similar to how shebangs
# are only patched if a dependency is in `buildInputs`
#
# We could pull Electron out of targetPackages, but it would be nice to support
# overriding Electron and using the hook on the overidden electron.
{
  electronWrapHook =
    makeSetupHook
      {
        name = "electron-wrap-hook";
        # Has to be in nativeBuildInputs so that it
        # goes back 1 offset from buildInputs to nativeBuildInputs since the
        # wrapper must be build->host
        propagatedNativeBuildInputs = [
          makeBinaryWrapper
        ];

        passthru.tests = {
          inherit mattermost-desktop rocketchat-desktop signal-desktop;
        };
      }
      (
        replaceVars ./electron-wrap-hook.sh {
          ELECTRON_PACKAGE = electron;
        }
      );
  electronBuildHook =
    makeSetupHook
      {
        name = "electron-build-hook";

        passthru.tests = {
          inherit
            mattermost-desktop
            signal-desktop
            mqtt-explorer
            bitwarden-desktop
            ;
        };
      }
      (
        replaceVars ./electron-build-hook.sh {
          ELECTRON_DIST = electron.dist;
          ELECTRON_VERSION = electron.version;
          ELECTRON_HEADERS = electron.headers;
        }
      );
}
