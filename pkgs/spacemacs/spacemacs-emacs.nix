{emacsPackages, extraPackages ? (p: [])}:
emacsPackages.emacsWithPackages (epkgs: [
  # epkgs.ht                      #  bundled with spacemacs
  epkgs.emacsql-sqlite
  epkgs.dash                    #  not bundled with spacemacs
  epkgs.s                       #  not bundled with spacemacs
  epkgs.f                       #  not bundled with spacemacs
  epkgs.toc-org                       #  not bundled with spacemacs
] ++ (extraPackages epkgs))
