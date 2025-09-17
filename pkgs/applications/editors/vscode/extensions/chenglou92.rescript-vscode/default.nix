{
  lib,
  stdenv,
  vscode-utils,
  callPackage,
  buildNpmPackage,
}:
let
  rescript-editor-analysis = callPackage ./rescript-editor-analysis.nix { };
  vsix = callPackage ./vsix.nix { inherit (rescript-editor-analysis) src version; };

  arch =
    if stdenv.hostPlatform.isLinux then
      "linux"
    else if stdenv.hostPlatform.isDarwin then
      "darwin"
    else
      throw "Unsupported system: ${stdenv.system}";

  analysisDir = "server/analysis_binaries/${arch}";

in
vscode-utils.buildVscodeExtension (finalAttrs: {
  inherit (rescript-editor-analysis) version;
  pname = "rescript-vscode";

  vscodeExtPublisher = "chenglou92";
  vscodeExtName = finalAttrs.pname;
  vscodeExtUniqueId = "${finalAttrs.vscodeExtPublisher}.${finalAttrs.pname}";

  src = "${vsix}/rescript-vscode-${finalAttrs.version}.zip";

  postPatch = ''
    rm -r ${analysisDir}
    ln -s ${rescript-editor-analysis}/bin ${analysisDir}
  '';

  # For rescript-language-server
  passthru.rescript-editor-analysis = rescript-editor-analysis;

  meta = {
    description = "Official VSCode plugin for ReScript";
    homepage = "https://github.com/rescript-lang/rescript-vscode";
    maintainers = with lib.maintainers; [
      dlip
      jayesh-bhoot
      RossSmyth
    ];
    platforms = with lib.platforms; linux ++ darwin;
    license = lib.licenses.mit;
  };
})
