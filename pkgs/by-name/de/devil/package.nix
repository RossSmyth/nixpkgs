{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  cmake,
  ninja,
  zlib,
  libpng,
  libtiff,
  libjpeg,
  jasper,
  libsquish,
  lcms,
  cppunit,
  validatePkgConfig,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "devil";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "DentonW";
    repo = "DevIL";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ITGAEeZAtjTdyWJWrqQJo9EJNpXvmMTRj8sx9Y7cJvQ=";
  };

  patches = [
    # Fix int -> const int conversion error
    (fetchpatch {
      url = "https://github.com/DentonW/DevIL/commit/42a62648e727e9a0217280474546de3ac69cbff1.patch";
      hash = "sha256-qxlk+3bV9zYEeMqBBwfRsfZN7iF7EzbbGwnKjyleHaI=";
    })
    (fetchpatch {
      url = "https://patch-diff.githubusercontent.com/raw/DentonW/DevIL/pull/102.patch";
      hash = "sha256-L8/b6KgHWVTKgnic7H8qLTXHgxPdxsK/6G1q7Ueg9K8=";
    })
  ];

  postPatch = ''
      cd DevIL
    '';

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [
    cmake
    ninja
    validatePkgConfig
  ];

  buildInputs = [
    zlib
    libpng
    libtiff
    libjpeg
    jasper
    libsquish
    lcms
  ];

  doCheck = true;

  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
    (lib.cmakeBool "IL_TESTS" finalAttrs.doCheck)
  ];

  nativeCheckInputs = [
    cppunit
  ];

  passthru.tests.pkg-config = testers.hasPkgConfigModules {
    package = finalAttrs.finalPackage;
  };

  meta = {
    homepage = "https://openil.sourceforge.net/";
    description = "cross-platform image library utilizing a simple syntax to load, save, convert, manipulate, filter, and display a variety of images";
    license = with lib.licenses; [ lgpl2Only ];
    maintainers = with lib.maintainers; [ RossSmyth ];
    pkgConfigModules = [ "IL" "ILU" "ILUT" ];
  };
})
