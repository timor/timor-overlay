{lib, stdenv, fetchFromGitHub, writeScriptBin, callPackage, makeDesktopItem
, fetchurl, git, writeText, emacsPackages, extraPackages ? null, dotfile ? null }:


let
  packagesFromDotfile = callPackage ./packages-from-dotfile.nix { inherit emacsPackages; };
  haveDotfile = (dotfile != null);
  haveExtraPackages = (extraPackages != null);
  extraPackages' = if haveExtraPackages then extraPackages else p: [];
  dotfilePath = if haveDotfile then
    writeText "imported-dotfile" (builtins.readFile dotfile)
    else null;
  dotfilePackages = if haveDotfile then (import "${packagesFromDotfile dotfile}")
    else p: [];
  finalPackages = p: (extraPackages' p) ++ (dotfilePackages p) ;
  name = "spacemacs-${version}";
  version = "0.300-rc7";
  desktopItem = makeDesktopItem {
    name = "spacemacs";
    genericName = "Text Editor";
    exec = "spacemacs %F";
    icon = "spacemacs";
    comment = "A community-driven Emacs distribution - The best editor is neither Emacs nor Vim, it's Emacs *and* Vim!";
    desktopName = "Spacemacs";
    categories = "Development;TextEditor;";
  };
  spacemacs-emacs = callPackage ./spacemacs-emacs.nix {
    inherit emacsPackages;
    extraPackages = finalPackages;
  };
  spacemacs-emacs-bin = "${lib.getBin spacemacs-emacs}/bin";
in

stdenv.mkDerivation rec{
  inherit name version;

  src = fetchFromGitHub {
    owner = "timor";
    repo = "spacemacs";
    rev = "nix-adjustments-${version}";
    sha256 = "0jsyax1mxh8i5ni2s23niq70n85si7mp4yhih46vay8qdanqf1z4";
  };

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
    ${spacemacs-emacs-bin}/emacs --batch $loadArgs --eval '(batch-byte-recompile-directory 0)' "./core"

    # ${spacemacs-emacs-bin}/emacs --batch --eval '(batch-byte-recompile-directory 0)' "./layers"
    # ${spacemacs-emacs-bin}/emacs --batch --eval '(batch-byte-compile)' "./init.el"
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
      export NIX_SPACEMACS_SUFFIX=$(echo $out | cut -d'/' -f4 | cut -d'-' -f1)
    ''}
    ${spacemacs-emacs-bin}/emacs -q \
      --eval '(setq invocation-name "spacemacs")' \
      --eval '(setq invocation-directory "$out/bin")' \
      --eval '(setq user-init-file "$out/init.el")' \
      -l '${./elisp/nix-spacemacs.el}' \
      --load $out/init.el "\$@"
    EOF
    chmod +x $out/bin/spacemacs

    mkdir -p $out/share/icons/hicolor/scalable/apps
    ln -s $out/assets/spacemacs.svg $out/share/icons/hicolor/scalable/apps/

    ln -s ${spacemacs-emacs-bin}/emacsclient $out/bin/

    mkdir -p $out/share/applications
    ln -s ${desktopItem}/share/applications/* $out/share/applications/
  '';

  postFixup = ''
    ln -s $out/share/doc $out/doc
  '';

  passthru = {
    inherit emacsPackages;
    inherit spacemacs-emacs;
    inherit packagesFromDotfile;
    inherit finalPackages;
  };
}
