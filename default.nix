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

  mfcl8650cdwlpr = callPackage ./pkgs/mfcl8650cdwlpr { };
  mfcl8650cdwcupswrapper = callPackage ./pkgs/mfcl8650cdwcupswrapper {};

  vlc = super.vlc.overrideAttrs(oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [ self.libnotify self.gtk2 ];
    configureFlags = oldAttrs.configureFlags ++ [ "--enable-notify" ];
  });

  emacsPackagesNg = super.emacsPackagesNg.override (superEpkgs: selfEpkgs: {
    exwm = callPackage ({elpaBuild, fetchurl, lib, xelb}: elpaBuild {
      pname = "exwm";
      version = "0.15";
      src = fetchurl {
        url = "https://elpa.gnu.org/packages/exwm-0.15.tar";
        sha256 = "1y7nqry9y0a99bsdqkk9f554vczfw4sz6raadw3138835qy697jg";
      };
      packageRequires = [ xelb ];
      meta = {
        homepage = "https://elpa.gnu.org/packages/exwm.html";
        license = lib.licenses.free;
      };
    }) {elpaBuild = selfEpkgs.elpaBuild; xelb = selfEpkgs.xelb; };
  });

  exwm-ns = callPackage ./pkgs/exwm-ns { };

  slic3r = super.slic3r.overrideAttrs(oldAttrs: {
    buildPhase = ''
      export LD=g++
    '' +
    oldAttrs.buildPhase;
    patches = [
      (self.fetchpatch {
        name = "fix-deserialize-return-values";
        url = "https://github.com/alexrj/Slic3r/commit/6e5938c8330b5bdb6b85c3ca8dc188605ee56b98.diff";
	sha256 = "1m125lajsm2yhacwvb3yxsz63jy9k2zzfaprnc4nkfcz0hs5vbpq";
	})];
  });

  # physlock = super.physlock.overrideAttrs(oldAttrs: rec {
  #   version = "11-git";
  #   name = "physlock-${version}";
  #   src = self.fetchFromGitHub {
  #   owner = "muennich";
  #     repo = "physlock";
  #     rev = "31cc383afc661d44b6adb13a7a5470169753608f";
  #     sha256 = "0j6v8li3vw9y7vwh9q9mk1n1cnwlcy3bgr1jgw5gcv2am2yi4vx3";
  #   };
  #   buildInputs = [ self.pam self.systemd.dev ];
  #   buildPhase = ''
  #     make SESSION=systemd
  #   '';
  # });

}
