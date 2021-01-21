{ stdenv, fetchFromGitHub, python }:

stdenv.mkDerivation {
  pname = "zfs-linux-tools";
  version = "2020-07-11";

  buildInputs = [ python ];

  src = fetchFromGitHub {
    owner = "richardelling";
    repo = "zfs-linux-tools";
    rev = "9e5c8c748a2d73c5cbf00b248e0730645f59d9b2";
    sha256 = "1gbvsznr63559b3cim6lx46cx87wkyrs16snx9056ja8pyyvb6zh";
  };

  dontBuild = true;
  installPhase = ''
    mkdir -p $out/bin
    cp kstat-analyzer zfetchstat $out/bin/
  '';
}
