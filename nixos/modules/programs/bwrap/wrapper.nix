_:
{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
  pathOrStr = types.coercedTo types.path (x: "${x}") types.str;
  cfg = config.bwrap;
in
{
  _class = "bwrapV1";

  imports = [
    ../../../../modules/generic/meta-maintainers.nix
    ../../misc/assertions.nix
  ];

  options.bwrap = {
    # Always make the options positive, this is more intutive as it will means adding more options
    # adss more capabilities to the sandbox. So rather than transliterating the options that are
    # "unshare-user", a negative option, the options are actually "shareUserNamespace"
    #
    # Do not add options that enable the CLI flags that remove capablities (--cap-drop) as this makes
    # the CLI order-dependent and harder to manage

    package = mkOption {
      type = types.package;
      example = lib.literalMD "pkgs.ripgrep";
      description = "The package that the exectable resides in";
    };

    commandLine = mkOption {
      type = types.listOf types.str;
      description = "The command line arguments passed to bwrap";
      internal = true;
      readOnly = true;
    };

    # Namespace sharing
    shareUserNamespace = mkOption {
      type = types.bool;
      example = true;
      default = false;
      description = ''
        Whether to share the user namespace with the user running the command.
        This changes how UIDs and GIDs are mapped when running.

        By default, unshares the namespace so the program is run in an isolated namespace.
        See {manpage}`user_namepspaces(7)`
      '';
    };
    shareIpcNamespace = mkOption {
      type = types.bool;
      example = true;
      default = false;
      description = ''
        Whether to share the IPC namespace with the user running the command.
        This changes how IPC resources like message quques, semaphores, and shared memory are mapped.

        By default, unshares the namespace so the program is run in an isolated namespace.
        See {manpage}`ipc_namepspaces(7)`
      '';
    };
    sharePidNamespace = mkOption {
      type = types.bool;
      example = true;
      default = false;
      description = ''
        Whether to share the PID namespace with the user running the command.
        This changes how PIDs are mapped within the namespace.

        By default, unshares the namespace so the program is run in an isolated namespace.
        See {manpage}`pid_namepspaces(7)`
      '';
    };
    shareNetworkNamespace = mkOption {
      type = types.bool;
      example = true;
      default = false;
      description = ''
        Whether to share the network namespace with the user running the command.
        This isolates networking resources such as devices, IP protocol stacks, routing tables, and various directories.

        By default, unshares the namespace so the program is run in an isolated namespace.
        See {manpage}`network_namepspaces(7)`
      '';
    };
    shareUtsNamespace = mkOption {
      type = types.bool;
      example = true;
      default = false;
      description = ''
        Whether to share the UTS namespace with the user running the command.
        This provides isolation of the device hostname, and the NIS domain name

        By default, unshares the namespace so the program is run in an isolated namespace.
        See {manpage}`uts_namepspaces(7)`
      '';
    };
    shareCgroupNamespace = mkOption {
      type = types.bool;
      example = true;
      default = false;
      description = ''
        Whether to share the cgroup namespace with the user running the command.
        Isolates cgroup root directories.

        By default, unshares the namespace so the program is run in an isolated namespace.
        See {manpage}`cgroup_namepspaces(7)`
      '';
    };

    enableUserNamespaces = mkOption {
      type = types.bool;
      example = true;
      default = false;
      description = ''
        Enable the process to create further user namespaces.
        This allows namespace modification such as rearranging the filesystem namespace, and more complex modifications.
      '';
    };

    uid = mkOption {
      type = types.nullOr types.int;
      example = 2;
      default = null;
      description = ''
        Set a custom UID within the sandbox.

        Only possible when {option}enableUserNamespaces is `true`.
      '';
    };
    gid = mkOption {
      type = types.nullOr types.int;
      example = 2;
      default = null;
      description = ''
        Set a custom GID within the sandbox

        Only possible when {option}shareUserNamespace is `true`.
      '';
    };
    hostname = mkOption {
      type = types.nullOr types.str;
      example = "nixos";
      default = null;
      description = ''
        Use a custom hostname within the sandbox

        Only possible when {option}shareUtsNamespace is `true`.
      '';
    };

    workingDirectory = mkOption {
      type = types.submodule {
        options = {
          path = lib.mkOption {
            type = types.nullOr types.path;
            example = lib.literalExpression "/home";
            default = null;
            description = ''
              Explict setting of the current working directory of the sandboxed program.

              When null follows bwrap's default logic:
                1. Set CWD to "/"
                2. Set to explicit CWD if present (this option)
                3. If there is none, try to set to parent's CWD if mapped into sandbox
                4. If not mapped, set CWD to calling processes' $HOME variable

              So if unset the CWD will either be "$CWD", "$HOME", or "/".
            '';
          };
          propagateMutable = lib.mkOption {
            type = types.bool;
            example = true;
            default = false;
            description = ''
              Whether to bind the CWD of the caller into the sandbox as a mutable binding.
            '';
          };
          propagate = lib.mkOption {
            type = types.bool;
            example = true;
            default = false;
            description = ''
              Propagates the CWD of the caller to be the CWD of the sandbox.
            '';
          };
        };
      };
      example = lib.literalExpression "";
      default = {
        path = null;
        propagate = false;
        propagateMutable = false;
      };
      description = ''
        Change the current working directory. If null, bwrap's fallback logic will be used:
          1. Set CWD to "/"
          2. Set to explicit CWD if present
          3. If there is none, try to set to parent's CWD if mapped into sandbox
          4. If not mapped, try to set CWD to calling processes' $HOME variable if mapped into sandbox
      '';
    };

    environment = mkOption {
      type = types.attrsOf (
        types.nullOr (
          types.oneOf [
            pathOrStr
            (types.coercedTo types.str toString types.bool)
            (types.coercedTo types.str toString types.int)
          ]
        )
      );
      example = {
        DEBUG = true;
        VERBOSE = 4;
        FILE = "~/out.txt";
        EDITOR = null;
      };
      default = { };
      description = ''
        Environment variables to set in the sandbox.

        If a variable is set to `null`, it is
      '';
    };

    clearEnvironment = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether to clear all environment variables except those explicitly set within the sandbox.
      '';
    };

    newTerminalSession = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether to create a new terminal session for this sandbox or not. This disconnect the sandbox from the controlling terminal,
        so it cannot inject input to the terminal.
      '';
    };

    dieWithParent = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Ensures the child process dies when the parent process dies.
      '';
    };

    capabilities = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "CAP_DAC_READ_SEARCH"
      ];
      description = ''
        Add capabilities to the sandbox.

        See {manpage}capabilities(7)
      '';
    };

    executable = mkOption {
      type = types.str;
      defaultText = lib.literalMD "cfg.package.meta.mainProgram";
      default = cfg.package.meta.mainProgram;
      example = lib.literalMD "binary2";
    };

    #TODO: All the filesystem bindings
    bindMounts = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            source = lib.mkOption {
              type = pathOrStr;
              example = lib.literalExpression "/home/nixos/.config/thing";
              description = ''
                A file or directory path to bind into the sandbox.
              '';
            };
            destination = lib.mkOption {
              type = lib.nullOr pathOrStr;
              example = lib.literalExpression "/thing";
              default = null;
              description = ''
                A file or directory path to bind into the sandbox.

                If null, it binds it "in-place", so the path in the sandbox matches the path outside the sandbox.
              '';
            };
            permissions = lib.mkOption {
              type = types.nullOr types.str;
              example = lib.literalExpression "0700";
              default = null;
              description = ''
                Permissions to set for the file. By default they are "0755" if null.
              '';
            };
            mutable = lib.mkOption {
              type = types.bool;
              example = true;
              default = false;
              description = ''
                Whether the bound path is mutable or not. Defaults to `false`.
              '';
            };
            device = lib.mkOption {
              type = types.bool;
              example = true;
              default = false;
              description = ''
                If the path being bound if a device path or not, such as `/dev/dri/card0`.
              '';
            };
            try = lib.mkOption {
              type = types.bool;
              example = true;
              default = false;
              description = ''
                Ignore if the source path does not exist.
              '';
            };
          };
        }
      );
      default = [ ];
      example = lib.literalExpression "";
      description = ''
        File systme objects to bind into the sandbox, their permissions, and how they are bound.
      '';
    };

    tmpfs = lib.mkOption {
      type = types.listOf (
        types.submodule {
          config = {
            destination = lib.mkOption {
              type = pathOrStr;
              example = lib.literalExpression "/thing";
              description = ''
                Path to create the tmpfs at in the sandbox
              '';
            };
            permissions = lib.mkOption {
              type = types.nullOr types.str;
              example = lib.literalExpression "0700";
              default = null;
              description = ''
                Permissions to set for the tmpfs. By default they are "0755" if null.
              '';
            };
            size = lib.mkOption {
              type = types.nullOr types.int;
              example = lib.literalExpression "10000";
              default = null;
              description = ''
                Size to create the tmpfs as. If null the default size will be used (what is the default)
              '';
            };
          };
        }
      );
      example = lib.literalExpression "[]";
      default = [ ];
      description = ''
        tmpfs to create in the sandbox.
      '';
    };

    enableProcfs = lib.mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether to mount procfs in the sandbox or not (/proc)
      '';
    };
    enableDevfs = lib.mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether to mount devtmpfs in the sandbox or not (/dev)
      '';
    };

    mqueues = lib.mkOption {
      type = types.listOf pathOrStr;
      default = [ ];
      example = lib.literalExpression "[ " /var/thing/queue1 " " /var/thing/queue2 " ]";
      description = ''
        Destinations to mount new mqueues onto.
      '';
    };

    directories = lib.mkOption {
      type = types.listOf (
        types.submodule {
          config = {
            path = lib.mkOption {
              type = types.path;
              example = lib.literalExpression "/home/nixos";
              description = ''
                Path to create the directory.
              '';
            };
            permissions = lib.mkOption {
              type = lib.nullOr lib.str;
              example = lib.literalExpression "0700";
              default = null;
              description = ''
                Permissions to create the new directory with. By default the permissions are 0755.

                If the directory already exists, the permissions will not effects the directory.
              '';
            };
          };
        }
      );
      default = [ ];
      example = lib.literalExpression ''
        [
                  { path = "/home/nix"; permissions = "0711"; }
                  { path = "/var/thing"; }
                ]'';
      description = ''
        New directories to create within the sandbox.
      '';
    };
    symlinks = lib.mkOption {
      type = types.listOf (
        types.submodule {
          config = {
            source = lib.mkOption {
              type = types.path;
              example = lib.literalExpression "lib.getExe pkgs.hello";
              description = ''
                Path to create a symlink from.
              '';
            };
            destination = lib.mkOption {
              type = types.path;
              example = lib.literalExpression "/home/nixos/hello";
              description = ''
                Destination to create the symlink at.
              '';
            };
          };
        }
      );
      default = [ ];
      example = lib.literalExpression ''
        [
                  { source = lib.getExe pkgs.hello; destination = "/home/nixos/hello"; }
                ]'';
      description = ''
        New symlinks to create within the sandbox.
      '';
    };
    changePermissions = lib.mkOption {
      type = types.listOf (
        types.submodule {
          config = {
            path = lib.mkOption {
              type = types.path;
              example = lib.literalExpression "/home/nixos";
              description = ''
                Path to change the permissions of. This path must already exist.
              '';
            };
            permissions = lib.mkOption {
              type = lib.nullOr lib.str;
              example = lib.literalExpression "0700";
              default = null;
              description = ''
                Permissions to set the path to.
              '';
            };
          };
        }
      );
      default = [ ];
      example = lib.literalExpression ''
        [
                  { path = "/home/nix"; permissions = "0711"; }
                ]'';
      description = ''
        Paths to change permissions of.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.enableUserNamespace && cfg.shareUserNamespace;
        message = "To enable user namespaces, the shareUserNamespace must be false";
      }
      {
        assertion = cfg.uid == 1;
        message = "The UID in the sandbox cannot be 1";
      }
      {
        assertion = (cfg.uid != null) && cfg.shareUserNamespace;
        message = "To use a custom UID, shareUserNamespace must be false";
      }
      {
        assertion = cfg.gid == 1;
        message = "The GID in the sandbox cannot be 1";
      }
      {
        assertion = (cfg.gid != null) && cfg.shareUserNamespace;
        message = "To use a custom GID, shareUserNamespace must be false";
      }
      {
        assertion = (cfg.hostname != null) && cfg.shareUtsNamespace;
        message = "To use a custom GID, shareUserNamespace must be false";
      }
      {
        assertion =
          (cfg.workingDirectory != null)
          && (cfg.workingDirectory.path != null)
          && (cfg.workingDirectory.propagate || cfg.workingDirectory.propagateMutable);
        message = ''
          cfg.workingdirectory.path is mutually exclusive with cfg.workingDirectory.propagate and cfg.workingDirectory.propagateMutable.
        '';
      }
    ];

    bwrap = {
      commandLine =
        # Simple flags
        (lib.optionals (!cfg.shareUserNamespace) [ "--unshare-user" ])
        ++ (lib.optionals (!cfg.shareIpcNamespace) [ "--unshare-ipc" ])
        ++ (lib.optionals (!cfg.sharePidNamespace) [ "--unshare-pid" ])
        ++ (lib.optionals (!cfg.shareNetworkNamespace) [ "--unshare-net" ])
        ++ (lib.optionals (!cfg.shareUtsNamespace) [ "--unshare-uts" ])
        ++ (lib.optionals (!cfg.shareCgroupNamespace) [ "--unshare-cgroup" ])
        ++ (lib.optionals (!cfg.enableUserNamespaces) [
          "--disable-userns"
          "--assert-userns-disabled"
        ])
        ++ (lib.optionals (cfg.uid != null) [
          "--uid"
          cfg.uid
        ])
        ++ (lib.optionals (cfg.gid != null) [
          "--gid"
          cfg.gid
        ])
        ++ (lib.optionals (cfg.hostname != null) [
          "--hostname"
          cfg.gid
        ])
        ++ (lib.optionals cfg.newTerminalSession [ "--new-session" ])
        ++ (lib.optionals cfg.dieWithParent [ "--die-with-parent" ])
        ++ (lib.optionals cfg.enableProcfs [
          "--procfs"
          "/proc"
        ])
        ++ (lib.optionals cfg.enableDevfs [
          "--dev"
          "/dev"
        ])
        # Capabilities
        ++ (lib.concatMap (cap: [
          "--cap-add"
          cap
        ]) cfg.capabilities)
        ++ (lib.flatten (
          (lib.mapAttrsToList (key: value: [
            "--setenv"
            (if value == null then lib.escapeShellArg "\${${key}}" else value)
          ]) cfg.environment)
        ))
        # tmpfs
        # Put before bind so that binds can be put into them
        ++ (lib.concatMap (
          tmpfs:
          (lib.optionals (tmpfs.size != null) [
            "--size"
            tmpfs.size
          ])
          ++ (lib.optionals (tmpfs.permissions != null) [
            "--perms"
            tmpfs.permissions
          ])
          ++ [
            "--tmpfs"
            tmpfs.destination
          ]
        ) cfg.tmpfs)
        # Bind-mounts
        ++ (lib.concatMap (
          mount:
          (lib.optionals (mount.permissions != null) [
            "--perms"
            mount.permissions
          ])
          ++ [
            (
              if mount.device && mount.try then
                "--dev-bind-try"
              else if mount.device then
                "--dev-bind"
              else if mount.mutable && mount.try then
                "--bind-try"
              else if mount.mutable then
                "--bind"
              else if mount.try then
                "--ro-bind-try"
              else
                "--ro-bind"
            )
            mount.source
            (if mount.destination == null then mount.source else mount.destination)
          ]
        ) cfg.bindMounts)
        ++ (lib.concatMap (mount: [
          "--mqueue"
          mount
        ]) cfg.mqueues)
        ++ (lib.concatMap (
          mount:
          lib.optionals (mount.permissions != null) [
            "--perms"
            mount.permissions
          ]
          ++ [
            "--dir"
            mount.path
          ]
        ) cfg.directories)
        # Should be after all bind mounts and stuff
        # Symlinks
        ++ (lib.concatMap (link: [
          "--symlink"
          link.source
          link.destination
        ]) cfg.symlinks)
        # Should be after all flags that create mounts or files/dirs
        # chmod
        ++ (lib.concatMap (path: [
          "--chmod"
          path.path
          path.permissions
        ]) cfg.changePermissions)
        # Working dir
        # Must be after all CLI flags that create mounts/dirs
        ++ lib.optionals (cfg.workingDirectory.path != null) [
          "--chdir"
          cfg.workingDirectory.path
        ]
        ++ lib.optionals cfg.workingDirectory.propagate [
          "--ro-bind"
          ("$(pwd)")
          ("$(pwd)")
          "--chdir"
          ("$(pwd)")
        ]
        ++ lib.optionals cfg.workingDirectory.propagateMutable [
          "--bind"
          ("$(pwd)")
          ("$(pwd)")
          "--chdir"
          ("$(pwd)")
        ]
        ++ [
          "--"
          "${cfg.package}/bin/${cfg.executable}"
        ];
    };
  };
}
