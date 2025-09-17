{
  lib,
  stdenv,
  vscode-utils,
  buildNpmPackage,
  # rescript packages
  vscode-src,
  vscode-version,
  rescript-vsix,
  rescript-editor-analysis,
  platformDir,
}:
let
  analysisDir = "server/analysis_binaries/${platformDir}";
in
vscode-utils.buildVscodeExtension (finalAttrs: {
  pname = "rescript-vscode";
  version = vscode-version;

  vscodeExtPublisher = "chenglou92";
  vscodeExtName = finalAttrs.pname;
  vscodeExtUniqueId = "${finalAttrs.vscodeExtPublisher}.${finalAttrs.pname}";

  src = "${rescript-vsix}/rescript-vscode-${finalAttrs.version}.zip";

  postPatch = ''
    rm -r ${analysisDir}
    ln -s ${rescript-editor-analysis}/bin ${analysisDir}
  '';

  # For rescript-language-server
  passthru.rescript-editor-analysis = rescript-editor-analysis;

  meta = {
    description = "Official VSCode plugin for ReScript";
    homepage = "https://github.com/rescript-lang/rescript-vscode";
    changelog = "https://github.com/rescript-lang/rescript-vscode/releases/tag/${finalAttrs.version}";
    downloadPage = "https://marketplace.visualstudio.com/items?itemName=chenglou92.rescript-vscode";
    maintainers = with lib.maintainers; [
      dlip
      jayesh-bhoot
      RossSmyth
    ];
    platforms = lib.platforms.all;
    license = lib.licenses.mit;
  };
})
