
# Installs the plugin to the plugin install path
#
# 1 = path to plugin
#
# Manifest is assumed to be in the CWD and named "manifest.json"
navidromePluginInstall() {
  local -r plugin="$1"

  local -r workingDir="$(mktemp -d)"

  cp "$plugin" "$workingDir/plugin.wasm"
  cp "manifest.json" "$workingDir"

  pushd "$workingDir"

  mkdir -p "$out/share/plugins"

  zip "$out/share/plugins/${pname}.ndp" \
    plugin.wasm \
    manifest.json

  popd
}

navidromePluginInstallPhase() {
  echo "starting navidromePluginInstall..."

  runHook preInstall

  if [[ -v navidromePlugin ]]; then
    navidromePluginInstall "$navidromePlugin"
  else
    echo "navidrome plugin not found, please define 'navidromePlugin' to the plugin path"
    exit 1
  fi

  runHook postInstall

  echo "navidromePluginInstall finished."
}

if [ -z "${dontInstallNavidromePlugin-}" ]; then
  installPhase=navidromePluginInstallPhase
fi
