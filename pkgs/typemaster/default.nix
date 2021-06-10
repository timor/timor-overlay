{ lib, stdenv, buildEnv, writeShellScriptBin, writeText, emacs, fetchFromGitHub, makeDesktopItem }:

let
  typemaster = emacs.pkgs.melpaBuild rec {
    pname = "typemaster";
    version = "0.6";

    src = fetchFromGitHub {
      owner = "timor";
      repo = "typemaster.el";
      rev = "v${version}";
      sha256 = "12byhsdzx1vf5n1xia39088413pqv0dxgwmxwj9vg6d8f4mfh459";
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
in

{
  de = buildEnv {
    name = "typemaster-practice-german-de";
    paths = [ run-de item-de ];
  };
}
