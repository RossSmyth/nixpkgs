{
  lib,
  stdenv,
  fetchFromGitHub,
  buildIdrisPackage,
  gmp,
  clang,
  chez,
  zsh,
  idris2Api,
  toml-idr,
  idris-filepath,
}:
buildIdrisPackage {
  ipkgName = "idris2-pack";
  version = "0-2024-02-07";

  src = fetchFromGitHub {
    owner = "stefan-hoeck";
    repo = "idris2-pack";
    rev = "305123401a28a57b02f750c589c35af628b2a5eb";
    hash = "sha256-IPAkwe6fEYWT3mpyKKkUPU0qFJX9gGIM1f7OeNWyB9w=";
  };

  dependencies = [
    idris2Api
    toml-idr
    idris-filepath
  ];

  wrapperArgs = [
    "--suffix C_INCLUDE_PATH : ${lib.makeIncludePath [ gmp ]}"
    "--suffix PATH : ${
      lib.makeBinPath (
        [
          clang
          chez
        ]
        ++ lib.optionals stdenv.hostPlatform.isDarwin [ zsh ]
      )
    }"
  ];

  meta = {
    description = "Idris2 Package Manager with Curated Package Collections";
    mainProgram = "pack";
    homepage = "https://github.com/stefan-hoeck/idris2-pack";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ mattpolzin ];
  };
}
