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
    preFixup = (oa.preFixup or "") + ''
      gappsWrapperArgs=(--run export\ PARENT_GDK_PIXBUF_MODULE_FILE=\"\$GDK_PIXBUF_MODULE_FILE\" "''${gappsWrapperArgs[@]}")
      gappsWrapperArgs+=(--add-flags --eval\ '"(setenv \"GDK_PIXBUF_MODULE_FILE\" (getenv \"PARENT_GDK_PIXBUF_MODULE_FILE\"))"')
    '';
    name = "emacs-${oa.version}-spacemacs";
  });
})
