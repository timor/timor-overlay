{lib, stdenv, fetchgit, writeScriptBin, callPackage, makeDesktopItem, fetchurl, git}:

let
  spacemacs-emacs = callPackage ./spacemacs-emacs.nix { };
  name = "spacemacs-${version}";
  version = "0.300-rc4";
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

  src = fetchgit {
    url = "https://github.com/timor/spacemacs.git";
    rev = "a414609e706cb6885e7f762fb987a9daa2df653c";
    sha256 = "1clmsbswji0qg4qr3innsksdzldbk54bg98bw2w6q42rjalm441d";
  };

  patches = [

    # preempt outshine/outorg layer PR
    ../../patches/spacemacs-outorg.diff
  ];

  postPatch = ''
    for i in core/info/release-notes/*; do
      substituteInPlace $i --replace ".emacs.d" ".spacemacs.d"
    done
  '';

  configurePhase = "true";

  dontBuild = true;

  buildPhase = ''
    loadArgs="-L $PWD/core -L $PWD/layers -l ./core/core-load-paths.el -l ./core/core-versions.el"
    export EMACS_USER_DIRECTORY=$PWD
    ${lib.getBin spacemacs-emacs}/bin/emacs --batch $loadArgs --eval '(batch-byte-recompile-directory 0)' "./core"

    # ${lib.getBin spacemacs-emacs}/bin/emacs --batch --eval '(batch-byte-recompile-directory 0)' "./layers"
    # ${lib.getBin spacemacs-emacs}/bin/emacs --batch --eval '(batch-byte-compile)' "./init.el"
    # some byte-compiled files don't work due to missing compile-time dependencies
    # rm -f core/core-spacemacs-buffer.elc
    rm -f core/libs/mocker.elc
  '';

  installPhase = ''
    cp -r . $out
    mkdir -p $out/bin
    rm -rf $out/.circleci $out/.travisci
    chmod -R +w $out

    cat > $out/bin/spacemacs <<EOF
    #!/bin/sh
    export EMACS_USER_DIRECTORY="\$HOME/.spacemacs.d/"
    ${lib.getBin spacemacs-emacs}/bin/emacs -q \
      --eval '(setq invocation-name "spacemacs")' \
      --eval '(setq invocation-directory "$out/bin")' \
      --eval '(setq user-init-file "$out/init.el")' \
      --load $out/init.el "\$@"
    EOF
    chmod +x $out/bin/spacemacs

    mkdir -p $out/share/icons/hicolor/scalable/apps
    ln -s $out/assets/spacemacs.svg $out/share/icons/hicolor/scalable/apps/

    mkdir -p $out/share/applications
    ln -s ${desktopItem}/share/applications/* $out/share/applications/
  '';

  postFixup = ''
    ln -s $out/share/doc $out/doc
  '';

  passthru = {
    inherit spacemacs-emacs;
  };
}
