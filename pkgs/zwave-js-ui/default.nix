{ pkgs, fetchFromGitHub, nodejs, stdenv, lib, ... }:

let

  nodePackages = pkgs.callPackage ./node-composition.nix {
    inherit pkgs nodejs;
    inherit (stdenv.hostPlatform) system;
  };
  nodeDeps = nodePackages.nodeDependencies;
  nodePkgs = nodePackages // { 
    # "zwave-js-server" = nodePackages."@zwave-js/server".override {
    #   buildInputs = [ nodejs.pkgs.node-gyp-build ];
    # };
    # "@serialport/bindings-cpp-10.8.0" = nodePackages."@serialport/bindings-cpp-10.8.0".override {
    #   buildInputs = [ nodejs.pkgs.node-gyp-build ];
    # };
  };
in
nodePkgs.package.overrideAttrs (oa:
  { buildInputs = oa.buildInputs ++ [ nodejs.pkgs.node-gyp-build ]; }
)
