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
    rev = "f2fe8fe313b4dbf39516b404726d4195e3e39f0c";
    sha256 = "02zachx65c6wkpsl89h8khpjjvcqg3mic26bzlpqi0c21429c34j";
  };

  patches = [
    (fetchurl {
      url = "https://patch-diff.githubusercontent.com/raw/syl20bnr/spacemacs/pull/12072.diff";
      sha256 = "1g0zh4i2a4raxq3m0p3igm4qd35p964589dwck4glzp765abiqs2";
    })
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
    rm -rf $out/.circleci $out/.travisci
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
