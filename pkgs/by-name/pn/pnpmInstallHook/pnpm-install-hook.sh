# shellcheck shell=bash

pnpmInstallHook() {
    echo "Executing pnpmInstallHook"

    runHook preInstall

    # Get the package name from the package.json file and create a path
    local -r packageOut="$out/lib/node_modules/$(@jq@ --raw-output '.name' package.json)"

    # Run pnpm pack so we can get a list of files to look at
    local -a packFlagsArray=("--json" "--dry-run" "--loglevel=warn" "--no-foreground-scripts")

    # No concating the `*Array` flags, this hook only
    # supports structuredAttrs if you want that.
    concatTo packFlagsArray pnpmFlags pnpmPackFlags

    # Run pnpm pack
    local packJson
    packJson="$(pnpm pack "${packFlagsArray[@]}")"

    while IFS= read -r file; do
        local dest="$packageOut/$(dirname "$file")"
        mkdir -p "$dest"
        cp "$file" "$dest"
    done < <(@jq@ --raw-output '.[0].files | map(.path | select(. | startswith("node_modules/") | not)) | join("\n")' <<< echo "$packJson")

    # Craft the path we will place the node_modules
    local -r nodeModulesPath="$packageOut/node_modules"

    # If the directory already exists (from manual intervention)
    # skip this hook installing the node_modules
    if [ ! -d "$nodeModulesPath" ]; then
        # Allow the user to skip this hook
        if [ -z "${dontPnpmPrune-}" ]; then
            # Prune the files to reduce file size from dev deps
            local -a pruneFlagsArray=("--prod")
            concatTo pruneFlagsArray npmFlags npmPruneFlags

            if ! CI=true pnpm prune "${pruneFlagsArray[@]}"; then
              echo
              echo
              echo "ERROR: pnpm prune step failed"
              echo
              echo 'If pnpm tried to download additional dependencies above, try setting `dontPnpmPrune = true`.'
              echo

              exit 1
            fi
        fi

        # Clean up broken symlinks left behind by `pnpm prune`
        # https://github.com/pnpm/pnpm/issues/3645
        find node_modules -xtype l -delete

        # remove non-deterministic files
        rm "node_modules/.modules.yaml" "node_modules/.pnpm-workspace-state-v1.json"

        # Deletes empty directories in the node_modules
        find node_modules -maxdepth 1 -type d -empty -delete

        # Install the node_modules
        cp -r node_modules "$nodeModulesPath"
    fi

    # Create a wrapped for executables based upon package.json containing an executable type
    nodejsInstallExecutables "package.json"

    # Install man pages based upon a man type in the package.json
    nodejsInstallManuals "package.json"

    runHook postInstall

    echo "Finished pnpmInstallHook"
}

if [ -z "${dontPnpmInstall-}" ] && [ -z "${installPhase-}" ]; then
    installPhase=pnpmInstallHook
fi
