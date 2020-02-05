{stdenv, fetchFromGitHub}:

stdenv.mkDerivation {
  pname = "bgrep";
  version = "2016-02-13";

  src = fetchFromGitHub {
    owner = "tmbinc";
    repo = "bgrep";
    rev = "5ca1302382bd50c1c58055a07551c96480109e24";
    sha256 = "1mn96sm4n6m57kysibp3h8m25v1yda247kwacq2qvs7i5yiw33br";
  };

  dontConfigure = true;
  buildPhase = ''
    gcc -O2 -x c -o bgrep bgrep.c
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp bgrep $out/bin/
  '';
}
