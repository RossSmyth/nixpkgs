{
  stdenv,
  lib,
  idris2,
  makeBinaryWrapper,
}:
let
  # Idris library paths
  idrName = "idris2-${idris2.version}";
  libSuffix = "lib/${idrName}";
  libDirs = libs: (lib.makeSearchPath libSuffix libs) + ":${idris2}/${idrName}";
  supportDir = "${idris2.libidris2_support}/lib";
in
lib.extendMkDerivation {
  constructDrv = stdenv.mkDerivation;

  excludeDrvArgNames = [
    "ipkgName"
    "idrisLibraries"
    "dependencies"
    "buildTarget"
    "buildFlags"
    "installExecutable"
    "installLibrary"
    "withSource"
    "wrapperArgs"
  ];

  extendDrvArgs =
    finalAttrs:
    {
      dependencies ? [ ],
      buildTarget ? null,
      buildFlags ? [ "--wp" ],
      installExecutable ? true,
      installLibrary ? true,
      withSource ? false,
      wrapperArgs ? [ ],
      meta ? { },
      ...
    }@args:
    assert lib.assertMsg (
      installLibrary || installExecutable
    ) "Must install an executable, library, or both";
    {
      # or patterns will show the other case in the error message, so instead explicitly check
      pname =
        if args ? ipkgName then
          lib.warn "'ipkgName' is deprecated, please use 'pname' instead" args.ipkgName
        else
          args.pname;

      # If building lib and exe, make two outputs. Otherwise just one.
      outputs = args.outputs or ([ "out" ] ++ lib.optional (installExecutable && installLibrary) "lib");

      strictDeps = true;
      nativeBuildInputs = [
        idris2
        makeBinaryWrapper
      ]
      ++ args.nativeBuildInputs or [ ];

      dependencies = lib.map lib.getLib (
        lib.concatMap (dep: [
          dep
          (
            if dep ? idrisLibraries then
              lib.warn "'idrisLibraries' has been deprecated, please use 'dependencies' instead" dep.idrisLibraries
            else
              dep.dependencies
          )
        ]) dependencies
      );

      env.IDRIS2_PACKAGE_PATH = libDirs finalAttrs.dependencies;

      __structuredAttrs = true;
      buildPhase =
        args.buildPhase or ''
          runHook preBuild

          idris2 --build ${args.buildTarget or finalAttrs.pname}.ipkg --verbose ''${buildFlags}

          runHook postBuild
        '';

      passthru = {
        inherit propagatedIdrisLibraries;
      }
      // (attrs.passthru or { });

      shellHook = ''
        export IDRIS2_PACKAGE_PATH="${finalAttrs.env.IDRIS2_PACKAGE_PATH}"
      '';
    };
}
