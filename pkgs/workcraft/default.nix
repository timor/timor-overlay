{ stdenv, pkgs, fetchurl, jre, gradle, minisat, makeWrapper, bash }:

stdenv.mkDerivation rec {
  name = "workcraft";

  src = fetchurl {
    url = "https://github.com/workcraft/workcraft/releases/download/v3.1.3/workcraft-v3.1.3-linux.tar.gz";
    sha256 = "1dl97jw55y2wil6vs40z28ayxkhyw4s7lzkjwda77c6vc6c4wsnc";
  };

  buildInputs = [ bash makeWrapper ];

  phases = [ "unpackPhase" "installPhase" "fixupPhase"];


  installPhase = ''
  mkdir -p $out/share
  cp -r * $out/share
  mkdir $out/bin
  makeWrapper $out/share/workcraft $out/bin/workcraft \
    --set JAVA_HOME "${jre}";
  '';
}
