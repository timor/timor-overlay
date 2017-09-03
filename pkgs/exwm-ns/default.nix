{ stdenv, pkgs, fetchFromGitHub }:

stdenv.mkDerivation rec {
  name = "exwm-ns-${version}";
  version = "0.1";
  src = fetchFromGitHub {
    owner = "timor";
    repo = "exwm-ns";
    rev = "v${version}";
    sha256 = "0wcrf19q1fj635ric19a8qb4g7fvhgan3x6kz8ckvj73s88zfzva";
  };

  installPhase = ''
  mkdir -p $out/share/emacs
  cp exwm-ns.el $out/share/emacs
  '';
}
