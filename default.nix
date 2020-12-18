self: super:

# self: final fixpoint
# super: immediate predecessor pkgs
let
  lib = self.lib;
  callPackage' = super.lib.callPackageWith self;
  callPackage = super.lib.callPackageWith self;
  callPackageIfNewer = (oldPackage: path: args:
    let newPackage = callPackage path args;
      in
    if lib.versionOlder (lib.getVersion oldPackage) (lib.getVersion newPackage) then
    newPackage
    else
    oldPackage
  );
  # Use this to provide package until attribute is present in super
  replaceUnlessProvided = (attribute: newPackage:
    let attrExists = super ? "${attribute}"; in
    if attrExists then
      let existingPackage = super."${attribute}"; in
      abort "Overlay attribute for '${newPackage.name}' may not override existing definition: '${existingPackage.name}'"
    else
      newPackage
  );
  callPackageUnlessProvided = (attribute: path: args: replaceUnlessProvided attribute (callPackage' path args));
in

{
  amidicat = callPackage ./pkgs/amidicat { };

  bgrep = callPackageUnlessProvided "bgrep" ./pkgs/bgrep { };

  debugify = import ./pkgs/gdbForPackages/debugify.nix;
  gdbForPackages = callPackage ./pkgs/gdbForPackages { };
  gdbForPackage = (pkg: self.gdbForPackages [pkg]);

  colmap-clang = self.libsForQt5.callPackage ./pkgs/colmap {
    stdenv = self.clangStdenv;
    inherit (self.llvmPackages) openmp;
    };

  colmap = self.libsForQt5.callPackage ./pkgs/colmap { };

  # Usage:
  # deployFactor "my-cool-factor-program" /factor/program/sources
  #
  # Output:
  # Derivation whose build product has the following structure:
  # /bin/<my-cool-factor-program> -> /lib/factor/<my-cool-factor-program>/<my-cool-factor-program>
  # /lib/factor/<my-cool-factor-program>/ : Directory (may contain other used resources)
  deployFactor = callPackage ./pkgs/deployFactor { factor-lang = self.factor-lang-live; };
  factor-lang-new = callPackage ./pkgs/factor-lang/scope.nix { stdenv = self.clangStdenv; };

  # FIXME Depends on pdconfig definition at the moment
  factor-lang-live = (self.factor-lang-new.extend (self': super': {interpreter = super'.interpreter.overrideAttrs (oldAttrs:
  rec {
    version = "0.99-pre6";
    name = "factor-lang-${version}";
    bootImage = self.fetchurl {
      url = "https://downloads.factorcode.org/images/build/boot.unix-x86.64.image.e511080c91c884c117edc585e61a9979e11731a8";
      sha256 = "1bgvlssrfgybvm3zs4sx86yzx0hfzk8957brdcs6zhy4igxkjdc7";
    };

    src = self.fetchFromGitHub {
      owner = "factor";
      repo = "factor";
      rev = "6996415cd0e0ba3c4a081b561015bd3c4349013b";
      sha256 = "1gc99rsa0dzy44lrp3jwbcb5g139zw2rbz39ralxa37dfi43phhc";
    };

    # patches = lib.init oldAttrs.patches;
    patches = [
      ./pkgs/factor-lang/staging-command-line-0.98-pre.patch
      # ./pkgs/factor-lang/fuel-dir.patch
    ] ;

    postUnpack = ''
      cp ${bootImage} $sourceRoot/boot.unix-x86.64.image
      chmod 644 $sourceRoot/boot.unix-x86.64.image
    '';});}));

  git-rebase-all = self.runCommand "git-rebase-all" rec {
    src = self.fetchurl {
      url = https://raw.githubusercontent.com/nornagon/git-rebase-all/febe9888a62c6901793353107776c49a42d5fc1e/git-rebase-all ;
      sha256 = "0hlifc1kkk8243jz3igacyj959xwsc4fz9pp5lbpakzflmbw9yw4";
    };
  } ''
    mkdir -p $out/bin
    cp  $src $out/bin/git-rebase-all
    chmod +x $out/bin/git-rebase-all
    patchShebangs $out/bin/git-rebase-all
    '';

  spnav = callPackage ./pkgs/spnav { };

  spacenavd = callPackage ./pkgs/spacenavd { };

  freecad = (super.freecad.overrideAttrs (oldAttrs: {
      buildInputs = oldAttrs.buildInputs ++ [ self.spnav ];
  }));

  hachoir = callPackage ./pkgs/hachoir {};

  kerneldocs = callPackage ./pkgs/kerneldocs {};

  open-zwave = callPackage ./pkgs/open-zwave {};

  esp32 = callPackage ./pkgs/esp32 { };

  mfcl8650cdwlpr = callPackage ./pkgs/mfcl8650cdwlpr { };
  mfcl8650cdwcupswrapper = callPackage ./pkgs/mfcl8650cdwcupswrapper {};

  exwm-ns = callPackage ./pkgs/exwm-ns { };

  frame3dd = callPackage ./pkgs/frame3dd {};

  nux = callPackage ./pkgs/nux {};

  ocrfeeder = callPackage ./pkgs/ocrfeeder { automake = self.automake111x; };

  inherit (callPackage ./pkgs/opensnitch {})
    opensnitchd opensnitch-ui;

  plasma5 = super.plasma5 // {
    plasma-workspace = super.plasma5.plasma-workspace.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches ++ [ ./patches/plasma-lockscreen-suspend-20.03.patch ];
    });
  };

  spacemacs = callPackage ./pkgs/spacemacs/default.nix { emacsPackages = self.emacs26Packages; };

  spacemacs-default =
    self.spacemacs.override {
      dotfile = "${self.spacemacs}/core/templates/.spacemacs.template";
    } ;

  totala = callPackage ./pkgs/totala { };
}
