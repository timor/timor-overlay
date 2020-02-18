self: super:

# self: final fixpoint
# super: immediate predecessor pkgs
let
  lib = self.lib;
  callPackage = super.lib.callPackageWith self;
  callPackageIfNewer = (oldPackage: path: args:
    let newPackage = callPackage path args;
      in
    if lib.versionOlder (lib.getVersion oldPackage) (lib.getVersion newPackage) then
    newPackage
    else
    oldPackage
  );
in

{
  bgrep = callPackage ./pkgs/bgrep { };

  gdbForPackages = callPackage ./pkgs/gdbForPackages {pkgs = self;};
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
  deployFactor = callPackage ./pkgs/deployFactor { };

  # FIXME Depends on pdconfig definition at the moment
  factor-lang-live = (self.factor-lang.extend (self': super': {interpreter = super'.interpreter.overrideAttrs (oldAttrs:
  rec {
    version = "0.99-pre4";
    name = "factor-lang-${version}";
    bootImage = self.fetchurl {
      url = http://downloads.factorcode.org/images/build/boot.unix-x86.64.image.f7e4774d3f591b8b3f548cdd44cf0df1978f7f10;
      sha256 = "1k74w2zla8ryk1r6gwqc82ndj13mk0xsnxfy4q1ch601hvx1cgv2";
    };

    src = self.fetchFromGitHub {
      owner = "factor";
      repo = "factor";
      rev = "3aa71bcb848caf4ea2a9187ab3aab19f4c39fd24";
      sha256 = "1jfz2kz1j33lgjifxsryfp6q9ka3ppbcfnxfsyjcvkfmr00pb83f";
    };

    # patches = lib.init oldAttrs.patches;
    patches = [
      ./pkgs/factor-lang/staging-command-line-0.98-pre.patch
      ./pkgs/factor-lang/fuel-dir.patch
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

  spacemacs = callPackage ./pkgs/spacemacs/default.nix { };

  totala = callPackage ./pkgs/totala { };
}
