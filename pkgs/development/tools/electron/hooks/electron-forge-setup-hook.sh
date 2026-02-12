# shellcheck shell=bash

# This hook setups Electron programs that use electron-forge to use
# nixpkg's Electron.
#
# There are a couple things needed:
#
# 1. Tell electron-forge what version we are using
# 2. Patch electron-forge to use the already built Electron
#
# because if we do not, electron-forge will unconditinally query
# GitHub, which fails in the sandbox.

electronForgeSetupHook() {
  echo "Running electronForgeSetupHook..."

  # Find node_modules
  local nodeModules

  if [[ -v electronForgeNodeModules ]]; then
    nodeModules="$electronForgeNodeModules"
  else
    # Try to detect
    # Do not descend into any node_modules within node_modules. This
    # happens occasionally because folks will sometimes vendor their
    # node_modules for some reason
    nodeModules="$(find . -name 'node_modules' -prune -type d -prune)"
  fi

  if [[ -z "${nodeModules-}" ]]; then
    echo "electronForgeSetupHook: node_modules not found!"
    echo "Please set \`electronForgeNodeModules\` to explicitly set."
    exit 1
  fi

  # Turns out there are packages that use electron/packager manually.
  # So let this be able to be turned off.
  if [[ -z "${electronForgeReplace+x}" ]] || [[ "$electronForgeReplace" == 1 ]]; then
    # https://github.com/electron/forge/blob/eb0a845a922c841219c3a2e43bd99dae7ba89a90/packages/utils/core-utils/src/electron-version.ts#L138
    # replace it with the specified Nixpkg's Electron version.
    substituteInPlace "$nodeModules/@electron-forge/core-utils/dist/electron-version.js" \
      --replace-fail "return version" "return \"@ELECTRON_VERSION@\""
  fi

  # Copy Electron dist to a working directory so we can make an archive
  local -r electronTemp="$(mktemp -d)"
  cp -r "@ELECTRON_DIST@" "$electronTemp/electron-dist"
  chmod -R u+w "$electronTemp/electron-dist"

  # Create a zip archive for electron-packager to use
  pushd "$electronTemp/electron-dist"
  zip -0Xqr "../electron.zip" .
  popd

  # Delete dir once we are done with it
  rm -r "$electronTemp/electron-dist"

  # Replace the GitHub download call with a local file path.
  # https://github.com/electron/packager/blob/73a74db5eb793c4418badcdb43de413fa78a6db1/src/packager.ts#L257
  substituteInPlace "$nodeModules/@electron/packager/dist/packager.js" \
    --replace-fail "await this.getElectronZipPath(downloadOpts)" "\"$electronTemp/electron.zip\""

  echo "electronForgeSetupHook finished."
}

if [[ -z "${doElectronForgeSetup+x}" ]] || [[ "$doElectronForgeSetup" == 1 ]]; then
  preBuild+=(electronForgeSetupHook)
fi
