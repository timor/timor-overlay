let
  pkgs = import <nixpkgs> {};
in
  pkgs.fetchFromGitHub {
    owner = "zwave-js";
    repo = "zwave-js-ui";
    rev = "b35f7263097148e1f0d8eadc0ae03b0287cdb01f";
    sha256 = "pMf2h/7S5DosxFR6PULdOu1Ioi0RG45vjYrTZREwGLA=";
  }
