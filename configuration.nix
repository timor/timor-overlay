{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./modules/spacemacs-os.nix
      ./modules/mpd-user.nix
    ];

  security.pam.services.physlock = { };
}
