{
  buildGoModule,
  lib,
  navidrome,
  zip,
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

      nativeBuildInputs = [
        zip
      ];

      env = {
        CGO_ENABLED = "0";
      }
      // env;

      buildFlags = [
        "-buildmode=c-shared"
      ];

      installPhase = ''
        runHook preInstall

        mkdir -p "$out/share/plugins"
        buildDir="$(mktemp -d)"

        # There should be a single file
        cp "$GOPATH/bin/"* "$buildDir/plugin.wasm"
        cp manifest.json "$buildDir"

        pushd "$buildDir"

        zip "$out/share/plugins/${finalAttrs.pname}.ndp" \
          plugin.wasm \
          manifest.json

        popd

        runHook postInstall
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
