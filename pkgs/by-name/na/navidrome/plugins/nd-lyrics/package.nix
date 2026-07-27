{
  lib,
  rustPlatform,
  fetchFromGitHub,
  navidromePluginInstallHook,
  lld,
  breakpointHook,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "nd-lyrics";
  version = "7.1.0";

  src = fetchFromGitHub {
    owner = "J0R6IT0";
    repo = "navidrome-lyrics-plugin";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Ef07UYAA3Bjshy53VGaaOVgAob0kPlexUEVsvq62VCU=";
  };

  cargoHash = "sha256-fUI7aFG/tiO9jU+f2T8JX2ZjSYuuYBLiq7tmUbIdygY=";

  __structuredAttrs = true;
  nativeBuildInputs = [
    navidromePluginInstallHook
    lld
    breakpointHook
  ];

  env.RUSTFLAGS = "-C linker=wasm-ld";

  navidromePlugin = "target/wasm32-wasip1/release/navidrome_lyrics_plugin.wasm";
})
