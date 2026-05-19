{
  lib,
  clangStdenv,
  fetchFromGitHub,
  gnustep-make,
  pkg-config,
  gnustep-base,
  SDL_compat,
  libGL,
  libGLU,
  spidermonkey_140,
  gnustep-libobjc,
}:
let
  stdenv = clangStdenv;
  spidermonkey = spidermonkey_140;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "oolite";
  version = "1.92.1.0";

  src = fetchFromGitHub {
    owner = "OoliteProject";
    repo = "oolite";
    tag = finalAttrs.version;
    hash = "sha256-eVprLGcc6E5UXn58zzktityJx+v8G+nCLnfLtjq5XdI=";
  };

  postPatch = ''
    patchShebangs --build ShellScripts

    # Hardcode version so it doesn't call git
    substituteInPlace GNUmakefile \
      --replace-fail '$(shell ./ShellScripts/common/get_version.sh)' '${finalAttrs.version}'
  '';

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [
    gnustep-make
    pkg-config
  ];

  buildInputs = [
    gnustep-base
    SDL_compat
    libGL
    libGLU
    spidermonkey
    gnustep-libobjc
  ];

  makefile = "Makefile";
  buildFlags = [
    "release-deployment"
    "ADDITIONAL_INCLUDE_DIRS+=-Isrc/Core"
    "ADDITIONAL_INCLUDE_DIRS+=-Isrc/Cocoa"
    "ADDITIONAL_INCLUDE_DIRS+=-Isrc/Core/Tables"
    "ADDITIONAL_INCLUDE_DIRS+=-Isrc/Core/Scripting"
  ];

  preBuild = ''
    buildFlagsArray+=(ADDITIONAL_CFLAGS+="$(pkg-config --cflags --libs mozjs-140)")
    buildFlagsArray+=(ADDITIONAL_CFLAGS+="$(pkg-config --cflags --libs sdl)")
    buildFlagsArray+=(ADDITIONAL_OBJCFLAGS+="$(pkg-config --cflags --libs mozjs-140)")
    buildFlagsArray+=(ADDITIONAL_OBJCFLAGS+="$(pkg-config --cflags --libs sdl)")
  '';
})
