{
  lib,
  clangStdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  devil,
  minizip,
  zlib,
  SDL2,
  freetype,
  curl,
  jsoncpp,
  _7zz,
  openal,
  libvorbis,
  libunwind,
  libglvnd,
  fontconfig,
  expat,
  libX11,
}:
clangStdenv.mkDerivation (finalAttrs: {
  pname = "recoilengine";
  version = "2025.04.11";

  src = fetchFromGitHub {
    owner = "beyond-all-reason";
    repo = "RecoilEngine";
    tag = finalAttrs.version;
    fetchSubmodules = true;
    hash = "sha256-/KrpyJNh9peYY5rKPThyFSlE9xV1gq8N6JOD793HM2E=";
  };

  postPatch = ''
      sed '2,3d' CMakeLists.txt
    '';

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [
    ninja
    cmake
    pkg-config
  ];

  buildInputs = [
    devil
    minizip
    zlib
    SDL2
    freetype
    curl
    jsoncpp
    openal
    libvorbis
    libunwind
    libglvnd
    fontconfig
    expat
    libX11
  ];

  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
    (lib.cmakeFeature "SEVENZIP_BIN" (lib.getExe _7zz))
    (lib.cmakeBool "BUILD_SHARED_LIBS" (!clangStdenv.hostPlatform.isStatic))
    "-Wno-dev"
  ];
})
