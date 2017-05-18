{ stdenv, pkgs, lib, fetchurl, makeWrapper, perl, unrar, unzip, gzip, extraBackends ? [] }:

stdenv.mkDerivation rec {
  name = "unp-${version}";
  version = "2.0-pre7";

  backends =  [ unrar unzip gzip ] ++ extraBackends;
  buildInputs = [ perl makeWrapper ] ++ backends;

  src = fetchurl {
    # url = "http://http.debian.net/debian/pool/main/u/unp/unp_2.0~pre7+nmu1.tar.bz2";
    url = "mirror://debian/pool/main/u/unp/unp_2.0~pre7+nmu1.tar.bz2";
    sha256 = "09w2sy7ivmylxf8blf0ywxicvb4pbl0xhrlbb3i9x9d56ll6ybbw";
    name = "unp_2.0_pre7+nmu1.tar.bz2";
  };

  configurePhase = "true";
  buildPhase = "true";
  installPhase = ''
  mkdir -p $out/bin
  mkdir -p $out/share/man
  cp unp $out/bin/
  cp ucat $out/bin/
  cp debian/unp.1 $out/share/man

  wrapProgram $out/bin/unp \
    --prefix PATH : ${lib.makeBinPath backends}
  wrapProgram $out/bin/ucat \
    --prefix PATH : ${lib.makeBinPath backends}
  '';
}
