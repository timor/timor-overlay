{emacsPackages, texinfo}:
# let patched-emacs = emacsPackages.emacs.overrideAttrs(oldAttrs: rec {
#       # patches = oldAttrs.patches ++ [ ./spacemacs.d.patch ];
#       buildInputs = oldAttrs.buildInputs ++ [ texinfo ];
#       patches = oldAttrs.patches ++ [ ./emacs-user-directory.patch ];
#       versionModifier = "spacemacs";
#       name = "emacs-${oldAttrs.version}-${versionModifier}";
#     });
# in
# emacsPackagesFor patched-emacs

emacsPackages.overrideScope' (self: super: {
  emacs = super.emacs.overrideAttrs(oa: {
    patches = oa.patches ++ [./emacs-user-directory.patch ];
    buildInputs = oa.buildInputs ++ [ texinfo ];
    name = "emacs-${oa.version}-spacemacs";
  });
})
