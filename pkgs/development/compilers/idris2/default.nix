{
  lib,
  idris2,
  newScope,
}:
lib.makeScope newScope (
  self:
  let
    inherit (self) callPackage;
  in
  {
    inherit idris2;
    idris2Api = callPackage ./modules/idris2Api { };

    lsp-lib = callPackage ./modules/lsp-lib { };
    idris2-lsp = callPackage ./modules/idris2-lsp { };
    idris2Lsp = self.idris2-lsp; # Alias added 2025-09-22

    pack = callPackage ./pack.nix { };

    buildIdrisPackage = callPackage ./build-idris.nix { };
    buildIdris = self.buildIdrisPackage; # Alias added 2025-09-22
  }
)
