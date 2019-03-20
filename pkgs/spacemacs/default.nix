{lib, stdenv, fetchFromGitHub, writeScriptBin, callPackage, makeDesktopItem, fetchurl }:

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

  patches = [
    (fetchurl {
      url = "https://github.com/timor/spacemacs/commit/c18587b77f318ccb2fe198f23589e9c0826faa9f.diff";
      sha256 = "0ldsp0kx89iwjn5nymbr6yaj9lfyfsyizj6nlrkry852jll3hdyd";
    })
  ];

  postPatch = ''
    for i in core/info/release-notes/*; do
      substituteInPlace $i --replace ".emacs.d" ".spacemacs.d"
    done
  '';

  configurePhase = "true";

  buildPhase = ''
    ${lib.getBin spacemacs-emacs}/bin/emacs --batch --eval '(batch-byte-recompile-directory 0)' "./"
    # some byte-compiled files don't work due to missing compile-time dependencies
    rm core/core-spacemacs-buffer.elc
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -r . $out
    chmod -R +w $out

    cat > $out/bin/spacemacs <<EOF
    #!/bin/sh
    export EMACS_USER_DIRECTORY="\$HOME/.spacemacs.d/"
    ${lib.getBin spacemacs-emacs}/bin/emacs -q --eval '(setq user-init-file "$out/init.el")' --load $out/init.el $@
    EOF
    chmod +x $out/bin/spacemacs

    mkdir -p $out/share/icons/hicolor/scalable/apps
    ln -s $out/assets/spacemacs.svg $out/share/icons/hicolor/scalable/apps/

    mkdir -p $out/share/applications
    ln -s ${desktopItem}/share/applications/* $out/share/applications/
  '';
}
