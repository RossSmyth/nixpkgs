{
  buildGoModule,
  lib,
  navidrome,
  navidromeInstallPluginsHook,
}:
lib.extendMkDerivation {
  constructDrv = buildGoModule;

  excludeDrvArgNames = [
    "meta"
    "passthru"
  ];

  extendDrvArgs =
    finalAttrs:
    {
      pname,
      version,
      src,
      vendorHash,
      meta,
      env ? { },
      passthru ? { },
      ...
    }@args:
    {
      __structuredAttrs = true;

      env = {
        CGO_ENABLED = "0";
      }
      // env;

      buildFlags = [
        "-buildmode=c-shared"
      ];

      preInstall = ''
        navidromePlugins="$GOPATH/bin/*"
      '';

      passthru = {
        isNavidromePlugin = true;
      }
      // passthru;

      meta = meta // {
        platforms = navidrome.meta.platforms;
        maintainers = navidrome.meta.maintainers ++ meta.maintainers or [ ];
      };
    };
}
