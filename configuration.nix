{ config, lib, pkgs, ... }:

{
  imports =
    [
    ];

  security.pam.services.physlock = { };
}
