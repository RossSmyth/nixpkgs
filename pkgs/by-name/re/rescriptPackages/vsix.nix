{
  lib,
  buildNpmPackage,
  esbuild,
  vsce,
  vscode-src,
  vscode-version,
}:
buildNpmPackage (finalAttrs: {
  inherit src version;
  pname = "rescript-vscode-vsix";

  # Cannot set sourceRoot as we must patch
  # some things out
  postPatch = ''
    # Remove the prepulish script that just builds it, access the internet
    sed -i '248d' package.json

    #Remove the semver dependency, it is only for the server
    sed -i '263d' package.json

    # So we pickup the client deps
    pushd client
  '';

  npmDepsHash = "sha256-jlEObGj4f/CoxGaRZfc10rnX/IHn0ZM3Ik1UX9Aa1uk=";

  strictDeps = true;
  nativeBuildInputs = [
    esbuild
    vsce
  ];

  # Return to top-level for build and install
  preBuild = "popd";

  npmRebuildFlags = [ "--ignore-scripts" ];
  npmBuildScript = "bundle-client";

  installPhase = ''
    mkdir -p $out
    vsce package -o "$out/rescript-vscode-${finalAttrs.version}.zip"
  '';

  meta = {
    description = "VSCode extension archive for ReScript";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = [ lib.maintainers.RossSmyth ];
  };
})
