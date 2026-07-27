{ pkgs, ... }:
{
  name = "navidrome";

  nodes.machine =
    { config, pkgs, ... }:
    {
      # Need a user+group to own the lib dir
      users.groups.libOwner = { };
      users.users = {
        libOwner = {
          isNormalUser = true;
          extraGroups = [ "libOwner" ];
        };
        # Add navidrome to the group so it can read the lib dir
        navidrome.extraGroups = [ "libOwner" ];
      };

      systemd.tmpfiles.settings."10-lib"."/media".d = {
        mode = "0744"; # Perms so that navidrome can read the dir
        user = "libOwner";
        group = "libOwner";
      };

      services.navidrome = {
        enable = true;
        settings.MusicFolder = "/media";
      };
    };
  testScript = ''
    machine.wait_for_unit("navidrome")
    machine.wait_for_file("/run/navidrome/media")
    machine.wait_for_console_text("Scanner: Finished scanning all libraries")
  '';
}
