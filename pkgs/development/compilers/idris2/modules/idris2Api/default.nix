{
  lib,
  idris2,
  buildIdrisPackage,
}:
buildIdrisPackage {
  pname = "idris2Api";
  inherit (idris2.unwrapped) src version;

  installExecutable = false;
  preBuild = ''
    export IDRIS2_PREFIX=$out/lib
    make src/IdrisPaths.idr
  '';

  meta = {
    description = "Idris2 Compiler API Library";
    homepage = "https://github.com/idris-lang/Idris2";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ mattpolzin ];
  };
}
