{lib, runCommandNoCC, fetchFromGitHub, writeScriptBin, callPackage }:

let
  spacemacsSrc = fetchFromGitHub {
    owner = "timor";
    repo = "spacemacs";
    rev = "5a5b0a7940664ec79d5fd2b67665239f8fdab461";
    sha256 = "0z6pr065y462rasgrm74i6bbpl7g9zz4nbf66szn7xa35q847xl7";
  };
  spacemacs-emacs = callPackage ./spacemacs-emacs.nix { };
  name = "spacemacs-${version}";
  version = "0.300-rc1";
  startScript = writeScriptBin "start-spacemacs" ''
    #!/bin/sh
    export EMACS_USER_DIRECTORY="$HOME/.spacemacs.d/"
    ${lib.getBin spacemacs-emacs}/bin/emacs -q --load ${spacemacsSrc}/init.el $@
  '';
in
runCommandNoCC "spacemacs" {inherit name version;} ''
  mkdir -p $out/bin
  ln -s ${startScript}/bin/start-spacemacs $out/bin/spacemacs
''
