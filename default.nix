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

  freecad = (super.freecad.overrideAttrs (oldAttrs:
    {
      buildInputs = oldAttrs.buildInputs ++ [ self.spnav ];
    }));

}
