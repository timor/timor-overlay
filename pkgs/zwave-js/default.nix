{ pkgs, fetchFromGitHub, nodejs, stdenv, lib, ... }:

let
  src = fetchFromGitHub {
    owner = "zwave-js";
    repo = "zwave-js-server";
    rev = "51d5b2dead65cf3c2d3dafd7232090c8ebafdc61";
    sha256 = "bxXBgJke10HLKe40cag4HIFG5jh0VfNkCCRlspSkZKQ=";
  };

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
