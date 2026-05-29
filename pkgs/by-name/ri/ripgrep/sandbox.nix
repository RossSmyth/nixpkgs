{ }:
{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.ripgrep;
in
{
  _class = "bwrapV1";

  options.ripgrep = {
    package = mkOption {
      description = "Package to use for ripgrep";
      defaultText = lib.literalMD "The `ripgrep` package to provide the binary";
      type = types.package;
    };
  };

  config.bwrap = {
    package = cfg.package;
    workingDirectory.propagate = true;
  };
}
