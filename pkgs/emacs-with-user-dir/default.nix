{lib, makeWrapper, texinfo}:

userDir: nameSuffix: emacsPackages: emacsPackages.overrideScope' (eself: esuper:
  {
    emacs = lib.appendToName nameSuffix (esuper.emacs.overrideAttrs (oa: {
      nativeBuildInputs = oa.nativeBuildInputs ++ [texinfo];
      patches = oa.patches ++ [ ./emacs-user-directory.patch ];
      # passthru = oa.passthru //
      #            { envVars = { EMACS_USER_DIRECTORY = "\${HOME}/${userDir}";};};
      postInstall = (oa.postInstall or "") + ''
        sed '1 aexport EMACS_USER_DIRECTORY="''${HOME}/${userDir}"'
      '';
    }));
  }
)
