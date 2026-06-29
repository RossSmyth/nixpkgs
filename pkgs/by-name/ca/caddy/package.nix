{
  lib,
  buildGoModule,
  callPackage,
  fetchFromGitHub,
  nixosTests,
  caddy,
  installShellFiles,
  stdenv,
  writableTmpDirAsHomeHook,
  versionCheckHook,
}:
let
  version = "2.11.2";
  dist = fetchFromGitHub {
    owner = "caddyserver";
    repo = "dist";
    tag = "v${version}";
    hash = "sha256-D1qI7TDJpSvtgpo1FsPZk6mpqRvRharFZ8soI7Mn3RE=";
  };
in
buildGoModule (finalAttrs: {
  pname = "caddy";
  inherit version;

  src = fetchFromGitHub {
    owner = "caddyserver";
    repo = "caddy";
    tag = "v${finalAttrs.version}";
    hash = "sha256-QoGq8+lhaSQuC1VwIYE8h8N/ZC1ozfmIwmsIPk29Jos=";
  };

  proxyVendor = true;
  vendorHash = "sha256-yINMuFstrlOiWZPubCRIpPdrl20AFkjK4Pq186eB1rM=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${finalAttrs.version}"
  ];

  # matches upstream since v2.8.0
  tags = [
    "nobadger"
    "nomysql"
    "nopgx"
  ];

  nativeBuildInputs = [ installShellFiles ];

  nativeCheckInputs = [ writableTmpDirAsHomeHook ];

  __darwinAllowLocalNetworking = true;

  postInstall = ''
    install -Dm644 ${dist}/init/caddy.service ${dist}/init/caddy-api.service -t $out/lib/systemd/system

    substituteInPlace $out/lib/systemd/system/caddy.service \
      --replace-fail "/usr/bin/caddy" "$out/bin/caddy"
    substituteInPlace $out/lib/systemd/system/caddy-api.service \
      --replace-fail "/usr/bin/caddy" "$out/bin/caddy"
  ''
  + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    # Generating man pages and completions fail on cross-compilation
    # https://github.com/NixOS/nixpkgs/issues/308283

    $out/bin/caddy manpage --directory manpages
    installManPage manpages/*

    installShellCompletion --cmd caddy \
      --bash <($out/bin/caddy completion bash) \
      --fish <($out/bin/caddy completion fish) \
      --zsh <($out/bin/caddy completion zsh)
  '';

  passthru = {
    tests = {
      inherit (nixosTests) caddy;
      acme-integration = nixosTests.acme.caddy;

      new-plugins = finalAttrs.passthru.new-plugins {
        pname = "test";
        caddyVersion = finalAttrs.version;
        plugins = [
          "github.com/dunglas/frankenphp/caddy@v1.12.1"
          "github.com/caddy-dns/powerdns@v1.0.1"
        ];
        hash = "sha256-Xfy20UVvhxWOUBvk5RXhCU0cBXYJQKAlunmAwpuawB8=";
      };

      builder = finalAttrs.passthru.builder {
        plugins = [
          "github.com/dunglas/frankenphp/caddy@v1.12.1"
          "github.com/caddy-dns/powerdns@v1.0.1"
        ];
        cachedPlugins = finalAttrs.passthru.tests.new-plugins;
      };
    };
    new-plugins = callPackage ./new-plugins.nix { };
    builder = callPackage ./builder.nix { caddy = finalAttrs.finalPackage; };
    withPlugins = callPackage ./plugins.nix { inherit caddy; };
  };

  nativeInstallCheckInputs = [
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  versionCheckKeepEnvironment = [ "HOME" ];
  doInstallCheck = true;

  meta = {
    homepage = "https://caddyserver.com";
    description = "Fast and extensible multi-platform HTTP/1-2-3 web server with automatic HTTPS";
    changelog = "https://github.com/caddyserver/caddy/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "caddy";
    maintainers = with lib.maintainers; [
      stepbrobd
      techknowlogick
      ryan4yin
    ];
  };
})
