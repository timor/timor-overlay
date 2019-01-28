{lib, stdenv, fetchFromGitHub, writeScriptBin, callPackage, makeDesktopItem }:

let
  spacemacs-emacs = callPackage ./spacemacs-emacs.nix { };
  name = "spacemacs-${version}";
  version = "0.300-rc1";
  desktopItem = makeDesktopItem {
    name = "spacemacs";
    genericName = "Text Editor";
    exec = "spacemacs %F";
    icon = "spacemacs";
    comment = "A community-driven Emacs distribution - The best editor is neither Emacs nor Vim, it's Emacs *and* Vim!";
    desktopName = "Spacemacs";
    categories = "Development;TextEditor;";
  };
in
stdenv.mkDerivation rec {
  inherit name version;

  src = fetchFromGitHub {
    owner = "timor";
    repo = "spacemacs";
    rev = "5a5b0a7940664ec79d5fd2b67665239f8fdab461";
    sha256 = "0z6pr065y462rasgrm74i6bbpl7g9zz4nbf66szn7xa35q847xl7";
  };

  startScript = writeScriptBin "start-spacemacs" ''
    #!/bin/sh
    export EMACS_USER_DIRECTORY="$HOME/.spacemacs.d/"
    ${lib.getBin spacemacs-emacs}/bin/emacs -q --load ${src}/init.el $@
  '';

  configurePhase = "true";
  buildPhase = ''
    mkdir -p $out/bin
    cp -r $src/* $src/*.* $out/
    chmod -R +w $out
    ${lib.getBin spacemacs-emacs}/bin/emacs --batch --eval '(batch-byte-recompile-directory 0)' "$out/"
  '';
  installPhase = ''
    ln -s ${startScript}/bin/start-spacemacs $out/bin/spacemacs

    mkdir -p $out/share/icons/hicolor/scalable/apps
    ln -s $out/assets/spacemacs.svg $out/share/icons/hicolor/scalable/apps/

    mkdir -p $out/share/applications
    ln -s ${desktopItem}/share/applications/* $out/share/applications/
  '';
}
