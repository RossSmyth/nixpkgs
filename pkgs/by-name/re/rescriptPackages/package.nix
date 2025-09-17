{
  lib,
  stdenv,
  generateSplicesForMkScope,
  makeScopeWithSplicing',
  fetchFromGitHub,
}:
let
  # Internal packages
  toRemove = [
    "vscode-version"
    "vscode-src"
    "vsix"
    "platformDir"
  ];
in
lib.removeAttrs (makeScopeWithSplicing' {
  otherSplices = generateSplicesForMkScope "rescript";
  f = (
    self:
    let
      inherit (self) callPackage;
    in
    {
      platformDir =
        if stdenv.hostPlatform.isLinux then
          "linux"
        else if stdenv.hostPlatform.isDarwin then
          "darwin"
        else if stdenv.hostPlatform.isFreeBSD then
          "freebsd"
        else if stdenv.hostPlatform.isWindows then
          "win32"
        else
          throw "Unsupported system: ${stdenv.system}";

      vscode-version = "1.64.0";
      vscode-src = fetchFromGitHub {
        owner = "rescript-lang";
        repo = "rescript-vscode";
        tag = self.vscode-version;
        hash = "sha256-bDi5UCgeScH28EW18GqqEuZWF4thbiUt53Aj1yCyRkc=";
      };

      rescript-editor-analysis = callPackage ./editor-analysis.nix { };
      rescript-language-server = callPackage ./language-server.nix { };
      rescript-vsix = callPackage ./vsix.nix { };
      rescript-vscode = callPackage ./vscode.nix { };
      rewatch = callPackage ./rewatch.nix { };
    }
  );
}) toRemove
