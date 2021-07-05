{ lib, stdenv, buildEnv, writeShellScriptBin, writeText, emacs, fetchFromGitHub, makeDesktopItem }:

let
  typemaster = emacs.pkgs.melpaBuild rec {
    pname = "typemaster";
    version = "1.0";

    src = fetchFromGitHub {
      owner = "timor";
      repo = "typemaster.el";
      rev = "v${version}";
      sha256 = "16m2ag3aq88ryp77vhv92b1vs8anjssjqysdk71lpka6lqr75x2g";
    };
    recipe = writeText "recipe" "(typemaster :fetcher github :repo \"\" :files (\"*.el\" \"*.gz\"))";
    packageRequires = [ emacs.pkgs.request ];
    fileSpecs = [ "*.el" "*.gz" ];
  };
  typemasterEmacs = emacs.pkgs.withPackages (epkgs: [typemaster # epkgs.color-theme-solarized
                                                    ]) ;
  run-de = writeShellScriptBin "typemaster-de" ''
    ${lib.getBin typemasterEmacs}/bin/emacs -q -mm \
       --eval "(require 'typemaster)" \
       --eval "(load-theme 'tango-dark t)" \
       -f typemaster-practice-german-de
  '';
  item-de = makeDesktopItem {
    name = "typemaster2000-de";
    exec = "typemaster-de";
    icon = "tools-check-spelling";
    genericName = "Typing Practice (german)";
    desktopName = "Typemaster2000 (german,de)";
    categories = "Education;";
  };

  run-en = writeShellScriptBin "typemaster-en" ''
    ${lib.getBin typemasterEmacs}/bin/emacs -q -mm \
       --eval "(require 'typemaster)" \
       --eval "(load-theme 'tango-dark t)" \
       -f typemaster-practice-english
  '';
  item-en = makeDesktopItem {
    name = "typemaster2000-en";
    exec = "typemaster-en";
    icon = "tools-check-spelling";
    genericName = "Typing Practice (english)";
    desktopName = "Typemaster2000 (english,en)";
    categories = "Education;";
  };
in

{
  de = buildEnv {
    name = "typemaster-practice-german-de";
    paths = [ run-de item-de ];
  };
  en = buildEnv {
    name = "typemaster-practice-english-de";
    paths = [ run-en item-en ];
  };
}
