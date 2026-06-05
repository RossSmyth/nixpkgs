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

      bwrapArgs = wrapCfg.commandLine;
      installPhase = ''
        mkdir -p "$out/bin"

        cat << EOF > "$out/bin/${wrapCfg.package.meta.mainProgram}"
        #!/bin/env bash
        exec "${lib.getExe cfg.package}" $(printf '"%s" ' "''${bwrapArgs[@]}") "\$@"
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
