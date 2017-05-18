self: super:

# self: final fixpoint
# super: immediate predecessor pkgs
let
  callPackage = super.lib.callPackageWith self;
in

{

  # fetchFromGitHub = with (inherit self fetchgit); {
  #   owner, repo, rev, name ? "${repo}-${rev}-src", leaveDotGit ? false,
  #   fetchSubmodules ? false,
  #   ... # For hash agility
  # }@args:
  # let
  #   baseUrl = "https://github.com/${owner}/${repo}";
  #   passthruAttrs = removeAttrs args [ "owner" "repo" "rev" "fetchSubmodules" ];
  # in if (fetchSubmodules then
  #   fetchgit ({
  #     inherit name rev fetchSubmodules;
  #     url = "${baseUrl}.git";
  #   } // passthruAttrs)
  # else
  #   # We prefer fetchzip in cases we don't need submodules as the hash
  #   # is more stable in that case.
  #   fetchzip ({
  #     inherit name;
  #     url = "${baseUrl}/archive/${rev}.tar.gz";
  #     meta.homepage = "${baseUrl}/";
  #   } // passthruAttrs) // { inherit rev; };


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
    patches = oldAttrs.patches ++ [ ./patches/openconnect_helper_path.patch ];
    preConfigure = oldAttrs.preConfigure + ''
    substituteInPlace clients/common/nm-vpn-helpers.c \
      --subst-var-by openconnect ${super.openconnect}
    '';
    enabelParallelBuilding = true;
  });
  openafsClientLocal = callPackage ./pkgs/openafs { kernel = super.linuxPackages.kernel; } ;
}
