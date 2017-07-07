self: super:

# self: final fixpoint
# super: immediate predecessor pkgs
let
  callPackage = super.lib.callPackageWith self;
in

{

  factor-lang = callPackage ./pkgs/factor-lang {
    inherit (self.gnome2) gtkglext;
  };

  spnav = callPackage ./pkgs/spnav { };

  spacenavd = callPackage ./pkgs/spacenavd { };

  freecad = (super.freecad.overrideAttrs (oldAttrs: {
      buildInputs = oldAttrs.buildInputs ++ [ self.spnav ];
  }));

  alsaTools = (super.alsaTools.overrideAttrs (oldAttrs: rec {
      name = "alsa-tools-${version}";
      version = "1.1.3";

      src = self.fetchurl {
        urls = [
          "ftp://ftp.alsa-project.org/pub/tools/${name}.tar.bz2"
          "http://alsa.cybermirror.org/tools/${name}.tar.bz2"
        ];
      sha256 = "02b75fyfmm9m2iz59d3xa97cas4f697a4pzdxn1i64kjd36iv3yq";
      };
  }));

  networkmanagerOC = super.networkmanager.overrideAttrs (oldAttrs: {
    name = "network-manager-ocpatch-${oldAttrs.version}";
    patches = oldAttrs.patches ++ [ ./patches/openconnect_helper_path.patch ];
    preConfigure = oldAttrs.preConfigure + ''
    substituteInPlace clients/common/nm-vpn-helpers.c \
      --subst-var-by openconnect ${super.openconnect}
    '';
    enableParallelBuilding = true;
  });
  openafsClientLocal = callPackage ./pkgs/openafs { kernel = super.linuxPackages.kernel; } ;
  workcraft = callPackage ./pkgs/workcraft {};

  unp = callPackage ./pkgs/unp { };

  esp32 = callPackage ./pkgs/esp32 { };
}
