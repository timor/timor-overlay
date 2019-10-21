{emacs, emacsPackagesNgGen, lib, fetchFromGitHub, fetchurl, texinfo }:
let patched-emacs = emacs.overrideAttrs(oldAttrs: rec {
      # patches = oldAttrs.patches ++ [ ./spacemacs.d.patch ];
      buildInputs = oldAttrs.buildInputs ++ [ texinfo ];
      patches = oldAttrs.patches ++ [ ./emacs-user-directory.patch ];
      versionModifier = "spacemacs";
      name = "emacs-${oldAttrs.version}-${versionModifier}";
    });
    spacemacsPackages = emacsPackagesNgGen patched-emacs;
in
spacemacsPackages.emacsWithPackages (epkgs: [
  # epkgs.ht                      #  bundled with spacemacs
  epkgs.emacsql-sqlite
  epkgs.dash                    #  not bundled with spacemacs
  epkgs.s                       #  not bundled with spacemacs
  epkgs.f                       #  not bundled with spacemacs
  epkgs.toc-org                       #  not bundled with spacemacs
])
