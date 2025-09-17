{
  lib,
  fetchFromGitHub,
  nix-update-script,
  ocamlPackages,
}:

ocamlPackages.buildDunePackage rec {
  pname = "analysis";
  version = "1.64.0";

  minimalOCamlVersion = "4.10";

  src = fetchFromGitHub {
    owner = "rescript-lang";
    repo = "rescript-vscode";
    tag = version;
    hash = "sha256-bDi5UCgeScH28EW18GqqEuZWF4thbiUt53Aj1yCyRkc=";
  };

  strictDeps = true;
  nativeBuildInputs = [
    ocamlPackages.cppo
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "([0-9]+\.[0-9]+\.[0-9]+)"
    ];
  };

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
