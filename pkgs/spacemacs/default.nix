{emacs, emacsPackagesNgGen, writeScriptBin, git, lib, fetchurl, fetchFromGitHub}:

let patched-emacs = emacs.overrideAttrs(oldAttrs: rec {
      patches = oldAttrs.patches ++ [ ./spacemacs.d.patch ];
      versionModifier = "spacemacs";
      name = "emacs-${oldAttrs.version}-${versionModifier}";
    });
    # spacemacsPackages = emacsPackagesNg.overrideScope (self: super: {
    #   emacs = patched-emacs;
    #   });
    spacemacsPackages = emacsPackagesNgGen patched-emacs;
    # emacsql-sqlite override taken from https://github.com/NixOS/nixpkgs/pull/53868/files
    spacemacs-emacs = spacemacsPackages.emacsWithPackages (epkgs: [ (epkgs.melpaBuild rec {
       pname = "emacsql-sqlite";
       ename = "emacsql-sqlite";
       version = "20180128.1252";
       src = fetchFromGitHub {
         owner = "skeeto";
         repo = "emacsql";
         rev = "62d39157370219a1680265fa593f90ccd51457da";
         sha256 = "0ghl3g8n8wlw8rnmgbivlrm99wcwn93bv8flyalzs0z9j7p7fdq9";
       };
       recipe = fetchurl {
         url = "https://raw.githubusercontent.com/milkypostman/melpa/3cfa28c7314fa57fa9a3aaaadf9ef83f8ae541a9/recipes/emacsql-sqlite";
         sha256 = "1y81nabzzb9f7b8azb9giy23ckywcbrrg4b88gw5qyjizbb3h70x";
         name = "recipe";
       };
       preBuild = ''
         cd sqlite
         make
       '';
       packageRequires = [ epkgs.emacs epkgs.emacsql ];
       meta = {
         homepage = "https://melpa.org/#/emacsql-sqlite";
         license = lib.licenses.free;
       };
     })]);
in
  writeScriptBin "spacemacs" ''
    #!/bin/sh
    dir=~/.spacemacs.d.d
    if [ ! -d "$dir" ]; then
      ${git}/bin/git clone -b develop https://github.com/syl20bnr/spacemacs.git "$dir"
      ${git}/bin/git clone https://github.com/timor/spacemacsOS "$dir/private/exwm"
    fi
    ${spacemacs-emacs}/bin/emacs $@
''
