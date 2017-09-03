{ stdenv, pkgs, fetchFromGithub }:

stdenv.mDerivation rec {
  name = "exwm-ns-${version}";
  version = "0.1";
  src = fetchFromGithub {
    owner = "timor";
    repo = "exwm-ns";
    rev = "v${version}";
    sha256 = "2qv9lxqx7m18029lj8cw3k7jngvxs4iciwrypdy0gd2nnghc68sw";
  };

  installPhase = ''
  mkdir -p $out/share/emacs
  cp exwm-ns.el $out/share/emacs
  '';
}
