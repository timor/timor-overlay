{lib, stdenv, fetchFromGitHub, writeScriptBin, callPackage, makeDesktopItem
, fetchurl, git, writeText, extraPackages ? null, dotfile ? null }:


let
  haveDotfile = (dotfile != null);
  customized = (extraPackages != null);
  extraPackages' = if customized then extraPackages else p: [];
  dotfilePath = if haveDotfile then
    writeText "imported-dotfile" (builtins.readFile dotfile)
  else null;
  name = "spacemacs-${version}";
  version = "0.300-rc5";
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

stdenv.mkDerivation rec{
  inherit name version;

  src = fetchFromGitHub {
    owner = "timor";
    repo = "spacemacs";
    rev = "nix-adjustments-${version}";
    sha256 = "1ncwq7cpay2g38i4k25fq040alc67z16w76n0k6bsgkj488hmdvv";
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

  spacemacs-emacs = callPackage ./spacemacs-emacs.nix {
    extraPackages = extraPackages';
  };
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
    ${lib.optionalString haveDotfile ''
      export NIX_DOTSPACEMACS="${dotfilePath}"
    ''}
    ${lib.getBin spacemacs-emacs}/bin/emacs -q \
      --eval '(setq invocation-name "spacemacs")' \
      --eval '(setq invocation-directory "$out/bin")' \
      --eval '(setq user-init-file "$out/init.el")' \
      -l '${./elisp/nix-spacemacs.el}' \
      --load $out/init.el "\$@"
    EOF
    chmod +x $out/bin/spacemacs

    mkdir -p $out/share/icons/hicolor/scalable/apps
    ln -s $out/assets/spacemacs.svg $out/share/icons/hicolor/scalable/apps/

    mkdir -p $out/share/applications
    ln -s ${desktopItem}/share/applications/* $out/share/applications/
    ${lib.optionalString customized ''
      cat >> $out/.lock <<EOF
      (defconst nix-spacemacs-storepath "$out")
      (setq configuration-layer-elpa-subdirectory (substring nix-spacemacs-storepath 1))
      EOF
    ''}
  '';

  postFixup = ''
    ln -s $out/share/doc $out/doc
  '';

  passthru = {
    inherit spacemacs-emacs;
    packagesFromDotfile = callPackage ./packages-from-dotfile.nix {};
  };
}
