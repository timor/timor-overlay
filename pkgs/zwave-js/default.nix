{ pkgs, fetchFromGitHub, nodejs, stdenv, lib, ... }:

let

  nodePackages = pkgs.callPackage ./node-composition.nix {
  inherit pkgs nodejs;
  inherit (stdenv.hostPlatform) system;
  };
  nodeDeps = nodePackages.nodeDependencies;
  nodePkgs = nodePackages // { 
    "zwave-js-server" = nodePackages."@zwave-js/server".override { 
      buildInputs = [ nodejs.pkgs.node-gyp-build ];
    };
  };
in
nodePkgs."zwave-js-server"
