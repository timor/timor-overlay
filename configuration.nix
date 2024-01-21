{ config, lib, pkgs, ... }:

{
  imports =
    [
    ./modules/easyeffects.nix
    ./modules/spacemacs-os.nix
    ./modules/mpd-user.nix
    # collides with (more basic) upstream module, disable for now
    # ./modules/opensnitch.nix
    ./modules/nvidia-suspend.nix
    ./modules/systemd-notify.nix
    ./modules/xbox360-wireless.nix
    ./modules/zwave-js.nix
  ];

  # example for activating mpd user:
  # services.mpdUser = {
  #   enable = true;
  # };
}
