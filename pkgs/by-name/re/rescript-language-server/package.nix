{
  lib,
  stdenv,
  buildNpmPackage,
  fetchFromGitHub,
  esbuild,
  nix-update-script,
  versionCheckHook,
  rescript-editor-analysis,
}:
let
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
in
buildNpmPackage (finalAttrs: {
  # These have the same source, and must be the same version.
  inherit (rescript-editor-analysis) src version;
  pname = "rescript-language-server";

  sourceRoot = "source/server";
  npmDepsHash = "sha256-GSlWDOvyqBqDtQWXUkiNVLogeACdQYmqYG0StM0XUq0=";

  strictDeps = true;
  nativeBuildInputs = [ esbuild ];

  # Scripts are in the top-level package.json
  preBuild = "pushd ../";

  npmRebuildFlags = [ "--ignore-scripts" ];
  npmBuildScript = "bundle-server";

  # Restore to the server directory for install
  postBuild = "popd";

  postInstall = ''
    DIR="$out/lib/node_modules/@rescript/language-server/analysis_binaries/${platformDir}"

    mkdir -p "$DIR"
    ln -s ${lib.getExe rescript-editor-analysis} "$DIR"/rescript-editor-analysis
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "([0-9]+\.[0-9]+\.[0-9]+)"
    ];
  };

  meta = {
    description = "ReScript Language Server";
    homepage = "https://github.com/rescript-lang/rescript-vscode/tree/${finalAttrs.version}/server";
    changelog = "https://github.com/rescript-lang/rescript-vscode/releases/tag/${finalAttrs.version}";
    mainProgram = "rescript-language-server";
    license = lib.licenses.mit;
    # https://github.com/rescript-lang/rescript-vscode/blob/1.62.0/CONTRIBUTING.md?plain=1#L186
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ RossSmyth ];
  };
})
