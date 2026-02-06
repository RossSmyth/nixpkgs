# shellcheck shell=bash

electronBuildHook() {
  echo "Running electronBuildHook..."

  # electron dist need to be mutable
  local electronDist
  electronDist=$(mktemp -du)
  cp -r "@ELECTRON_DIST@" "$electronDist"
  chmod -R u+w "$electronDist"

  # Use the package-wide npm flags if set
  local -a npmFlagsArray
  concatTo npmFlagsArray npmFlags

  local -a electronBuildArgsArray=(
    # Support the package-wide npm flags
    "${npmFlagsArray[@]}"
    # Support the package-wide workspace
    ${npmWorkspace+--workspace=$npmWorkspace}
    "--"
    # Do not build a .exe or .appimage
    "--dir"
    # Never try to upload anything to Github
    "--publish" "never"
    # Use the mutable electron-dist directory
    "-c.electronDist=$electronDist"
    # inform electron-build what the electron version is
    "-c.electronVersion=@ELECTRON_VERSION@"
    # Skip signing
    "-c.mac.identity=null"
    # Compress as much as we can
    "-c.compression=maximum"
  )

  # Add the user args to the array
  concatTo electronBuildArgsArray electronBuildArgs

  echo "Running builder:"
  echo "npm exec electron-builder ${electronBuildArgsArray[@]}"

  npm_config_nodedir="@ELECTRON_HEADERS@" npm exec electron-builder "${electronBuildArgsArray[@]}"

  echo "electronBuildHook finished"
}

electronBuilder() {
  runHook preBuild

  runHook electronBuildHook

  runHook postbuild
}

if [ -z "${dontElectronBuild-}" ] && [ -z "${buildPhase-}" ]; then
    buildPhase=electronBuilder
fi
