{ config, lib, pkgs, ... }:

{
  imports =
    [
    ./modules/spacemacs-os.nix
    ./modules/mpd-user.nix
    ./modules/opensnitch.nix
  ];

  # example for activating mpd user:
  # services.mpdUser = {
  #   enable = true;
  # };
  # security.pam.services.physlock = { };
}
