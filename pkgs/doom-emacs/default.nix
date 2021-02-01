{ stdenv, lib, writeShellScriptBin, fetchFromGitHub, extraPackages ? (p: []), emacsPackages, emacsWithUserDir, callStraightEnv }:

let
  name = "doom-emacs";
  version = "2021-01-31";
  doomSrc = fetchFromGitHub {
    owner = "hlissner";
    repo = "doom-emacs";
    rev = "026d96198569974f4432a6b3afed91e17507b64a";
    sha256 = "0g88fca4xq1cgdssyiz4mjkavf079k9h6c7ac2i957lx283fs0db";
  };
  doomEmacsPackages = emacsWithUserDir "doom.d" "doom" emacsPackages ;
  
in rec
{
  emacs = doomEmacsPackages.emacs;
  # doom-emacs = runCommand "doom-emacs" {nativeBuildInputs = [makeWrapper];} ''
  #   mkdir -p $out/bin
  #   makeWrapper ${emacs}/bin/emacs $out/bin/doom-emacs --set EMACS_USER_DIRECTORY ${emacs.envVars.EMACS_USER_DIRECTORY}
  #   ln -s ${emacs}/bin/emacsclient $out/bin/
  # '';
  doom-emacs = writeShellScriptBin "doom-emacs" ''
    export EMACS_USER_DIRECTORY="${emacs.envVars.EMACS_USER_DIRECTORY}"
    exec "${lib.getBin emacs}/bin/emacs" "$@"
  '';
  emacs-env = callStraightEnv {

  };
}

  # Most of the stuff is stolen from nix-doom-emacs
# callStraightEnv {
#   emacsPackages = doomEmacsPackages;
#   emacsInitFile = "${doomSrc}/bin/doom";
#   emacsLoadFiles = [ ./advice.el ];
# }
