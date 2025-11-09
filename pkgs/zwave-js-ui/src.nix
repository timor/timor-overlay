let
  pkgs = import <nixpkgs> {};
in
  pkgs.fetchFromGitHub {
    owner = "zwave-js";
    repo = "zwave-js-ui";
    rev = "v2.8.6";
    sha256 = "pMf2h/7S5DosxFR6PULdOu1Ioi0RG65vjYrTZREwGLA=";
  }
