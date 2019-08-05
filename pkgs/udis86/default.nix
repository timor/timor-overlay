{ stdenv, fetchurl, autoreconfHook, python }:

stdenv.mkDerivation rec {
  name = "udis86-${version}";
  version = "1.7.2";

  nativeBuildInputs = [ autoreconfHook python ];

  configureFlags = [
    "--enable-shared"
  ];

  src = fetchurl {
    url = https://github.com/vmt/udis86/archive/v1.7.2.tar.gz;
    sha256 = "0yappb8dxwsq6jcqm4zq51iv6g53nzsx7czznp2l728n29z7ymj3";
  };

}
