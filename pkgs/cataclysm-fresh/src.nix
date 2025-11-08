let
  pkgs = import <nixpkgs> {};
in
  pkgs.fetchFromGitHub {
    owner = "CleverRaven";
    repo = "Cataclysm-DDA";
    rev = "98b100c2cec1fc92a409d5ab9295bfda1737e259";
    hash = "sha256-R/10Jk1ETV0qkHfa/dxWwRZOESCM04zQ3qnIE/UF0RY=";
  }

