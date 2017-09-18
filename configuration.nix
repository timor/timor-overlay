{ config, lib, pkgs, ... }:

{
  imports =
    [
    ./modules/spacemacs-os.nix
    ./modules/mpd-user.nix
  ];

  # example for activating mpd user:
  # mpdUser = {
  #   enable = true;
  # };
  security.pam.services.physlock = { };
}
