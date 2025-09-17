{
  lib,
  nix-update-script,
  ocamlPackages,
  vscode-src,
  vscode-version,
}:

ocamlPackages.buildDunePackage rec {
  pname = "analysis";
  version = vscode-version;

  minimalOCamlVersion = "4.10";
  src = vscode-src;

  strictDeps = true;
  nativeBuildInputs = [
    ocamlPackages.cppo
  ];

  meta = {
    description = "Analysis binary for the ReScript VSCode plugin";
    homepage = "https://github.com/rescript-lang/rescript-vscode";
    changelog = "https://github.com/rescript-lang/rescript-vscode/releases/tag/${version}";
    maintainers = with lib.maintainers; [
      dlip
      jayesh-bhoot
      RossSmyth
    ];
    license = lib.licenses.mit;
    mainProgram = "rescript-editor-analysis";
  };
}
