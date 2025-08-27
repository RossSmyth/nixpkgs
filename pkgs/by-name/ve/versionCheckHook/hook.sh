versionCheckHook(){
    runHook preVersionCheck
    echo Executing versionCheckPhase

    @python@ @pythonHook@

    runHook postVersionCheck
    echo Finished versionCheckPhase
}

if [[ -z "${dontVersionCheck-}" ]]; then
    echo "Using versionCheckHook"
    preInstallCheckHooks+=(versionCheckHook)
fi
