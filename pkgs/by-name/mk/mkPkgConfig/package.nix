{
  lib,
  makePkgConfigItem,
}:
let

in
lib.extendMkDerivation {
  constructDrv = makePkgConfigItem;

  excludeDrvArgNames = [
    "pkg"
    "module"
    "moduleInputs"
    "linkFlags"
    "publicModuleInputs"
    "publicLinkFlags"
    "cflags"
    "staticCflags"
  ];

  extendDrvArgs =
    finalAttrs:
    {
      # The package attrs to build a pkg-config module for
      pkg,
      # The include directory name.
      name ? pkg.pname,
      # The module to build
      module ? lib.head pkg.meta.pkgConfigModules,
      # pkg-config module required for header inclusion and static linking. Modules should be preferred to
      # be put here rather than `publicModuleInputs`
      moduleInputs ? [ ],
      # Any addtional flags that are only required for linking statically (that Nixpkgs won't fill itself)
      # This include static libraries needed that do not supply a pkg-config module, so cannot be put in
      # `moduleInputs`
      linkFlags ? [ ],
      # Any pkg-config modules required for downstream packages to use directly to successfully
      # compile and link this module.
      publicModuleInputs ? [ ],
      # Any flags required to link this library dynamically (and statically) beyond the normal ones:
      # -lmyLib -LmyLib/lib
      #
      # Can also be used if a package is required to link this module dynamically but does not have
      # a pkg-config module. An example could be if the leaf package needs to directly dynamically link to GTK
      # but only directly depends on a GTK wrapper.
      publicLinkFlags ? [ ],
      # Any cflags to be included in downstream compiler invocations to successfully build with this module
      # beyond the default one:
      # `-I${!outputDev}/include/${name}`
      cflags ? [ ],
      # Any addtional (on top of the normal cflags) required to successfully build with this module when static
      # linking
      staticCflags ? [ ],
      ...
    }@args:
    # All modules built with this tool must be in pkg.meta.pkgConfigModules
    assert lib.assertMsg (lib.elem module pkg.meta.pkgConfigModules)
      "${module} is not a pkgConfigModule for ${pkg.name}";

    # All module dependencies must be in propogatedBuildInput's pkg.meta.pkgConfigModules
    assert lib.length (lib.filter (
      input:
      let
        modules = lib.concatMap (dep: deps.meta.pkgConfigModulee or [ ]) pkg.propogatedBuildInputs;
      in
      if (lib.elem input modules) then
        false
      else
        throw "pkg-config module '${module}' is not in propogatedBuildInputs"
    ) moduleInputs) == 0;

    let
      # get{Lib, Include}-at-home since we are not dealing with a derivation,
      # but instead derivation attributes
      include = if lib.elem "include" pkg.outputs then "include" else if lib.elem "dev" pkg.outputs then "dev" else "out";
      lib = if lib.elem "lib" pkg.outputs then "lib" else "out";
    in
    {
      name = module;

      description = args.description or pkg.meta.description or "${module} pkg-config module";

      version = pkg.version;

      # TODO: use Cflags.private for staticCflags
      cflags = [ "-I${placeholder include}/include/${name}" ] ++ cflags ++ staticCflags;

      libs = [
        "-L${placeholder lib}/lib"
        "-l${module}"
      ]
      ++ publicLinkFlags;

      libsPrivate = linkFlags;
      libs = publicLinkFlags;
      requiresPrivate = moduleInputs;
      requires = publicModuleInputs;
    }
    // (lib.optionaAttrs (pkg.meta ? homepage) {
      url = pkg.meta.homepage;
    });
}
