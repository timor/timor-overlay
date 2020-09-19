{ stdenv, fetchurl, alsaLib }:


stdenv.mkDerivation {
  pname = "amidicat";
  version = "1.2";

  src = fetchurl {
   url = "http://krellan.com/amidicat/amidicat-1.2.tar.gz" ;
   sha256 = "1h1wd5agnly5q8pf85s6xgfd6gdk83r65qlhk80qwzdidd6jv4mh";
  };

  buildInputs = [ alsaLib ];
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/man/man1
    cp amidicat $out/bin/
    cp amidicat.1 $out/man/man1/
  '';
}
