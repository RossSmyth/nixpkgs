{
  lib,
  config,
  options,
  pkgs,
  ...
}:
let
  inherit (lib) types mkOption mkPackageOption;

  cfg = config.system.bwrap;

  bwrapSubmodule = types.submoduleWith {
    class = "bwrapV1";
    modules = [
      (lib.modules.importApply ./wrapper.nix { })
    ];
  };

  makeBwrapper =
    args:
    let
      wrapCfg = args.bwrap;

      storePaths = pkgs.closureInfo {
        rootPaths = [
          wrapCfg.package
        ];
      };
    in
    (pkgs.stdenvNoCC.mkDerivation {
      pname = "${wrapCfg.package.pname}-bwrap";
      inherit (wrapCfg.package) version;

      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;
      dontDist = true;
      strictDeps = true;
      __structuredAttrs = true;

      nativeBuildInputs = [
        pkgs.makeWrapper
      ];

      buildInputs = [
        pkgs.bash
      ];

      # Preserve manpages if they exist
      manOutput = lib.getMan wrapCfg.package;

      storePaths = "${storePaths}/store-paths";

      bwrapArgs = wrapCfg.commandLine;
      installPhase = ''
        mkdir -p "$out/bin"

        # Read store paths from closureInfo file,
        readarray -t storePathsArray < "$storePaths"

        cat << EOF > "$out/bin/${wrapCfg.package.meta.mainProgram}"
        #!/bin/env bash
        exec "${lib.getExe cfg.package}" $(for path in "''${storePathsArray[@]}"; do printf -- '"--ro-bind" "%s" "%s" ' "$path" "$path"; done) $(printf -- '"%s" ' "''${bwrapArgs[@]}")"\$@"
        EOF

        chmod +x "$out/bin/${wrapCfg.package.meta.mainProgram}"

        ln -s "$manOutput/share" "$out/share"
      '';

      inherit (wrapCfg.package.meta) ;
    });
in
{
  options.system = {
    bwrap.package = mkPackageOption pkgs "bwrap" {
      default = [ "bubblewrap" ];
    };
    bwrap.wrappers = mkOption {
      description = "Bubblewrap-sandboxed wrappers to add to system PATH";
      type = types.listOf bwrapSubmodule;
      default = [ ];
      visible = "shallow";
    };
  };
  config.environment.systemPackages = map (wrap: lib.meta.hiPrio (makeBwrapper wrap)) cfg.wrappers;
}
