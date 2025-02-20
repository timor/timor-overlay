{ stdenv, fetchFromGitHub, python }:

stdenv.mkDerivation {
  pname = "zfs-linux-tools";
  version = "2022-05-05";

  buildInputs = [ python ];

  src = fetchFromGitHub {
    owner = "richardelling";
    repo = "zfs-linux-tools";
    rev = "8e4f0818c188ebf4ecdfc12bb115a7866b67fc46";
    sha256 = "sha256-yQQjqwtl4NnFuB6oC76rbQd3gysdkKcpPz0VSTzoe/Q=";
    # sha256 = "1gbvsznr63559b3cim6lx47cx87wkyrs16snx9056ja8pyyvb6zh";
  };

  dontBuild = true;
  installPhase = ''
    mkdir -p $out/bin
    cp kstat-analyzer zfetchstat $out/bin/
  '';
}
