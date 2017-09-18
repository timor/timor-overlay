{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./modules/spacemacs-os.nix
    ];

  security.pam.services.physlock = { };
}
