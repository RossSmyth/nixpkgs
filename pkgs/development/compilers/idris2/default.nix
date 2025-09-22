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
    idris2Lsp = callPackage ./idris2-lsp.nix { };

    pack = callPackage ./pack.nix { };

    buildIdrisPackage = callPackage ./build-idris.nix { };
    buildIdris = self.buildIdrisPackage; # Alias added 2025-09-22
  }
)
