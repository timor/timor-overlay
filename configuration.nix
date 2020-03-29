{ config, lib, pkgs, ... }:

{
  imports =
    [
    ./modules/spacemacs-os.nix
    ./modules/mpd-user.nix
    ./modules/opensnitch.nix
    ./modules/nvidia-suspend.nix
    ./modules/xbox360-wireless.nix
  ];

  # example for activating mpd user:
  # services.mpdUser = {
  #   enable = true;
  # };
}
