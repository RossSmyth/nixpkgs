{
  lib,
  xcaddy,
  caddy,
  go,
}:
{
  plugins,
  cachedPlugins,
}:
let
  # If attrs, then just read them. Attrs = user is using a vendored plugin dir
  # If list, set to null. Null means we need to download them
  plugins' = if lib.isAttrs plugins then plugins else lib.genAttrs plugins (_: null);
in
caddy.overrideAttrs (
  finalAttrs: prevAttrs: {
    pname = "${prevAttrs.pname}-with-plugins";

    proxyVendor = true;

    strictDeps = true;
    __structuredAttrs = true;

    nativeBuildInputs = [
      xcaddy
      go
    ];

    # Filter to plugins we must download
    cachePlugins = lib.pipe plugins' [
      (lib.filterAttrs (_: isNull))
      lib.attrNames
    ];

    pathPlugins = lib.filterAttrs (_: d: !(isNull d)) plugins';

    inherit cachedPlugins;

    buildPhase = ''
      runHook preBuild

      export GOPROXY="file://${cachedPlugins}/pkg/mod/cache/download,$GOPROXY"
      xcaddy build v${finalAttrs.version} ''${cachePlugins[*]/#/--with } --replace "github.com/caddyserver/caddy/v2=./."

      runHook postBuild
    '';
  }
)
