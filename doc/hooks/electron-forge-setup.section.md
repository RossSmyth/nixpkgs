# electron.electronForgeSetup {#electron-forge-setup}

This hook setups up `node_modules` for packages that are using `@electron/packager` and `@electron/forge`.
These tools will generally try to download Electron from GitHub, so this hook patches them so that Nixpkgs-vendored Electron is used instead.

This patching occurs in a `preBuild` phase by default.

## Examples {#electron-forge-setup-examples}

```nix
{
  stdenvNoCC,
  electron,
  pnpm,
  pnpmConfigHook,
  nodejs,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "webapp"

  src = ./.;

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [
    pnpmConfigHook
    pnpm
    nodejs
  ];
  buildInputs = [
    electron.electronForgeSetupHook
    electron.electronWrapHook
  ];

  pnpmDeps = pnpmFetchDeps {
    inherit (finalAttrs) src pname version pnpm;
    hash = "...";
  };

  # Specify node_modules explicitly because after config
  electronForgeNodeModules = "path/node_modules";
  doElectronForgeSetup = false;

  # Need to be precise about when patching occurs, so we
  # run the hook manually
  preBuild = ''
    runHook electronForgeSetupHook
    pnpm setup
  '';

  # run electron-forge make for a production-ready archive.
  # explicitly set the arch and platform for better cross
  # compilation support, and only build the zip archive.
  buildPhase = ''
    runHook preBuild

    pnpm make \
      --arch ${stdenvNoCC.hostPlatform.node.arch} \
      --platform ${stdenvNoCC.hostPlatform.node.platform} \
      --targets "@electron-forge/maker-zip"

    runHook postBuild
  '';

  # copy the output resource files to the output. Wrap hook
  # will make the final executable
  installPhase = ''
    mkdir "$out/share/webapp";
    cp -r out/*/resources{,.pak} "$out/share/webapp"
  '';

  meta.mainProgram = "webapp";
})
```

## Variables controlling `electronForgeSetup` {#electron-forge-setup-variables}

### `electronForgeSetup` Exclusive Variables {#electron-forge-setup-exclusive-variables}

#### `electronForgeNodeModules` {#electron-forge-node-modules}

The `node_modules` directory to patch.
This is an optional attribute, and the hook will attempt to detect where `node_modules` is.
But if there are multiple `node_modules` directories, then this attribute will need to be explicitly set.

#### `electronForgeReplace` {#electron-forge-setup-replace}

Whether or not to replace the version string in the `@electron/forge` package.
This is an optional attribute, and should only be set to `false` if the package is using `@electron/packager`
without using `@electron/forge`

#### `doElectronForgeSetup` {#electron-forge-setup-do}

Whether to run the hook automatically or not.
If set to `false`, this hook will not run on its own.
This is useful if the sequencing of when the patching must occur is more strict than just sometime after configuration, and before build.
This is most common if `npm rebuild`, or some other packager command, needs to be run before building.

```nix
{
  buildInputs = [
    electron.electronForgeSetup
  ];

  doElectronForgeSetup = false;
  preBuild = ''
    runHook electronForgeSetup
    npm rebuild
  '';
}
```
