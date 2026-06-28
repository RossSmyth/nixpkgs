{
  lib,
  stdenv,
  go,
  git,
  writableTmpDirAsHomeHook,
}:
lib.extendMkDerivation {
  constructDrv = stdenv.mkDerivation;

  excludeDrvArgNames = [
    "plugins"
  ];

  extendDrvArgs =
    finalAttrs:
    {
      pname,
      plugins,
      caddyVersion,
      hash ? lib.fakeHash,
    }:
    let
      pluginsWithoutVersion = lib.filter (p: !lib.hasInfix "@" p) (lib.attrNames plugins');

      # If attrs, then just read them. Attrs = user is using a vendored plugin dir
      # If list, set to null. Null means we need to download them
      plugins' = if lib.isAttrs plugins then plugins else lib.genAttrs plugins (_: null);

      # Filter to plugins we must download
      toDownload = lib.filterAttrs (_: isNull) plugins';
    in
    # eval barrier: user provided plugins must have tags
    # the go module must either be tagged in upstream repo
    # or user must provide commit sha or a pseudo-version number
    # https://go.dev/doc/modules/version-numbers#pseudo-version-number
    assert lib.assertMsg (
      lib.length pluginsWithoutVersion == 0
    ) "Plugins must have tags present (e.g. ${lib.elemAt pluginsWithoutVersion 0}@x.y.z)!";
    {
      pname = "${pname}-plugins";
      version = "none";

      # FOD
      outputHashMode = "recursive";
      outputHash = finalAttrs.hash;
      outputHashAlgo = "sha256";

      strictDeps = true;
      __structuredAttrs = true;

      dontUnpack = true;
      dontConfigure = true;
      dontFixup = true;

      nativeBuildInputs = [
        go
        git
        writableTmpDirAsHomeHook
      ];

      plugins = (lib.attrNames toDownload);

      buildPhase = ''
        runHook preBuild

        export GOPATH="$(mktemp -d)"

        pushd "$(mktemp -d)"

        go mod init caddy-plugins

        for plugin in "''${plugins[@]}"; do
          go mod edit -require="$plugin"
        done

        # 3. Create the dummy code file to establish the baseline root dependency
        echo "package main" > main.go
        echo "import (" >> main.go
        for plugin in "''${plugins[@]}"; do
            mod_path=$(echo "$plugin" | cut -d'@' -f1)
            echo "  _ \"$mod_path\"" >> main.go
        done
        echo ")" >> main.go
        echo "func main() {}" >> main.go

        go mod tidy

        go mod download -json "''${plugins[@]}"

        runHook postBuild
      '';
      installPhase = ''
        runHook preInstall

        mkdir -p "$out"
        cp -r "$GOPATH/." "$out"

        runHook postInstall
      '';
    };
}
