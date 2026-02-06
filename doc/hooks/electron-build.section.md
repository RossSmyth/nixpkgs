# electron.electronBuildHook {#electron-build-hook}

Hook for building Electron-based packages.
This hook is for packages that use [electron-builder](https://www.electron.build/), and should work for any package manager: npm, yarn, or pnpm have been tested.

## Examples {#electron-build-hook-examples}

If being used with [`npmBuildPackage`]{#javascript-buildNpmPackage}, or other builders, this hook will have to be called explicitly because builders often set the `buildPhase` explicitly, overriding this hook.
In such cases this hook will need to be called explicitly in [`postBuild`](#var-stdenv-postBuild) like in [](#electron-wrap-hook-example-snipper).

This hook by default will set the `buildPhase`, so if used without `npmBuildPackage` or any other builder that sets the build phase, this hook will run without any configuration.
If any setup is needed in those cases, the [`preBuild`](#var-stdenv-preBuild) attribute will have to be used.

```nix
{
  #...
  buildInputs = [
    electron.electronWrapHook
    electron.electronBuildHook
  ];

  preBuild = ''
    npm run buildElectronStuff
  '';
  #...
}
```

## Variables controlling `electronBuildHook` {#electron-build-hook-variables}

### `electronBuildHook` Exclusive Variables {#electron-build-hook-exclusive-variables}

#### `electronBuildArgs` {#electron-build-hook-args}

Controls the arguments to {command}`npm exec electron-builder`

Default flags (cannot be disabled):
- `$npmFlags`, if any are provided
- If `npmWorkspace` is provided, `--workspace=$npmWorkspace`
- `--`
- `--publish never`
- `"-c.electronDist=${electron.dist}"`, the provided Electron's dist folder
- `-c.electronVersion=${electron.version}`, the provided Electron's version
- `-c.man.identity=null`, skip signing on Darwin
- `-c.compression=maximum`, compress the archive as much as possible

Any addtional flags provided by the `electronBuildArgs` attribute will be appended.
If this attribute is used, it is recommended to set `__structuredAttrs = true` in the derivation so that more precise argument splitting can be done.

```nix
{
  __structuredAttrs = true;
  buildInputs = [
    electron.electronBuildHook
  ];

  electronBuildArgs = [
    "--config"
    "some-file.json"
  ];
}
```

### `electronBuildHook` Honored Variables {#electron-build-hook-honored-variables}

- [npmWorkspace](#javascript-buildNpmPackage-npmWorkspace)
- [npmFlags](#javascript-buildNpmPackage-npmFlags)
