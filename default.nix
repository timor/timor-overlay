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
  deployFactor = scriptName: scriptSource: super.runCommand scriptName {
    factorCmd = "${self.factor-lang}/bin/factor " + ./pkgs/deployFactor/deploy-me.factor;
    SRC = scriptSource;
    NAME = scriptName;
  } ''
    mkdir -p $out/bin "$NAME" tmp-cache
    export XDG_CACHE_HOME=$PWD/tmp-cache

    cp -r $SRC/* "$NAME"
    $factorCmd ./"$NAME" $out/lib/factor
    ln -sf $out/lib/factor/"$NAME"/"$NAME" $out/bin/"$NAME"
  '';

  factor-lang = callPackageIfNewer super.factor-lang ./pkgs/factor-lang {
    inherit (self.gnome2) gtkglext;
    mesa = self.mesa_noglu;
  };

  spnav = callPackage ./pkgs/spnav { };

  spacenavd = callPackage ./pkgs/spacenavd { };

  freecad = (super.freecad.overrideAttrs (oldAttrs: {
      buildInputs = oldAttrs.buildInputs ++ [ self.spnav ];
  }));

  kerneldocs = callPackage ./pkgs/kerneldocs {};

  open-zwave = callPackage ./pkgs/open-zwave {};
  workcraft = callPackage ./pkgs/workcraft {};

  unp = callPackage ./pkgs/unp { };

  esp32 = callPackage ./pkgs/esp32 { };

  mfcl8650cdwlpr = callPackage ./pkgs/mfcl8650cdwlpr { };
  mfcl8650cdwcupswrapper = callPackage ./pkgs/mfcl8650cdwcupswrapper {};

  # vlc = super.vlc.overrideAttrs(oldAttrs: {
  #   buildInputs = oldAttrs.buildInputs ++ [ self.libnotify self.gtk2 ];
  #   configureFlags = oldAttrs.configureFlags ++ [ "--enable-notify" ];
  # });

  exwm-ns = callPackage ./pkgs/exwm-ns { };

  frame3dd = callPackage ./pkgs/frame3dd {};

  ocrfeeder = callPackage ./pkgs/ocrfeeder { automake = self.automake111x; };

  spacemacs = callPackage ./pkgs/spacemacs/default.nix { };

  perlPackages = super.perlPackages // (with super.perlPackages;{
    ExtUtilsCppGuess = buildPerlModule rec {
    name = "ExtUtils-CppGuess-0.07";
    src = self.fetchurl {
      url = "mirror://cpan/modules/by-module/ExtUtils/${name}.tar.gz";
      sha256 = "1a77hxf2pa8ia9na72rijv1yhpn2bjrdsybwk2dj2l938pl3xn0w";
    };
    propagatedBuildInputs = [ CaptureTiny ];
    perlPreHook = "unset LD";
  };});

  # notmuch = super.notmuch.overrideAttrs (oldAttrs: rec {
  #   version = "0.24.2";
  #   name = "notmuch-${version}";
  #   src = self.fetchurl {
  #     url = "http://notmuchmail.org/releases/${name}.tar.gz";
  #     sha256 = "0lfchvapk11qazdgsxj42igp9mpp83zbd0h1jj6r3ifmhikajxma";
  #   };
  #   doCheck = false;
  # });
  notmuch = callPackage ./pkgs/notmuch { };

  totala = callPackage ./pkgs/totala { };

  # pijul = callPackage ./pkgs/pijul { }; will only work once rust stuff has been sorted out

  xcircuit = callPackage ./pkgs/xcircuit { };

  zotero = callPackage ./pkgs/zotero { };
}
