{
  lib,
  fetchFromGitHub,
  idris2,
  buildIdrisPackage,
  idris2Api,
  lsp-lib,
}:

let
  globalLibraries =
    let
      idrName = "idris2-${idris2.version}";
    in
    lib.makeSearchPath idrName (
      [
        "\\$HOME/.nix-profile/lib"
        "/run/current-system/sw/lib"
        "${idris2}"
      ]
      ++ idris2.prelude
    );
in

buildIdrisPackage {
  pname = "idris2-lsp";
  version = "0-2024-01-21";

  src = fetchFromGitHub {
    owner = "idris-community";
    repo = "idris2-lsp";
    rev = "a77ef2d563418925aa274fa29f06880dde43f4ec";
    hash = "sha256-zjfVfkpiQS9AdmTfq0hYRSelJq5Caa9VGTuFLtSvl5o=";
  };

  dependencies = [
    idris2Api
    lsp-lib
  ];

  shellHook = ''
    export="$IDRIS2_PACKAGE_PATH:${globalLibraries}"
  '';

  meta = {
    description = "Language Server for Idris2";
    mainProgram = "idris2-lsp";
    homepage = "https://github.com/idris-community/idris2-lsp";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ mattpolzin ];
  };
}
