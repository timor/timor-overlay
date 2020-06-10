{lib, stdenv, fetchgit, writeScriptBin, callPackage, makeDesktopItem, fetchurl, git, supportCheckPhase ? false, runAllTests ? false }:

let
  spacemacs-emacs = callPackage ./spacemacs-emacs.nix { };
  name = "spacemacs-${version}";
  version = "0.300-rc3";
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
    rev = "2b3a85d3f66dde246901293df656f20f6a996397";
    sha256 = if supportCheckPhase then "00w6x9rg36sxviyr4na1q2q6drbh4lkq3sr6rjrzi8n4zpldlmsy"
      else "a414609e706cb6885e7f762fb987a9daa2df653c";
    leaveDotGit = supportCheckPhase; # for checkPhase, and also for blaming in final store path...
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

  doCheck = supportCheckPhase;

  checkInputs = [ git ];

  checkPhase = let
    testListCmd = if runAllTests then
        "find ./tests -type f -name Makefile"
      else
        "echo ./tests/core/Makefile";
    in
    ''
      (
        set -e
        export EMACS_USER_DIRECTORY=$PWD
        export PATH=${lib.getBin spacemacs-emacs}/bin:$PATH
        export HOME=$TMPDIR/fakehome
        mkdir -p $HOME/.spacemacs/private
        cp core/templates/.spacemacs.template $HOME/.spacemacs

        # ensure that remote points to origin for testing
        set +e
        git remote remove origin
        set -e
        git remote add origin https://github.com/syl20bnr/spacemacs.git
        for p in $(${testListCmd}); do
          ( cd $(dirname $p); make; )
        done
        rm -rf $HOME/.spacemacs
      )
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
