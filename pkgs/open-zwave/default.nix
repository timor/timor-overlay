{stdenv, fetchurl, unzip, libudev, doxygen, graphviz, libxml2, pkgconfig, fontconfig}:

stdenv.mkDerivation rec {
  name = "open-zwave-${version}";
  version = "1.5";

  buildInputs = [ unzip libudev graphviz fontconfig pkgconfig ];
  src = fetchurl {
    url = "https://github.com/OpenZWave/open-zwave/archive/V1.5.zip";
    sha256 = "1cq9kajk388kyby7zn8li78rbdcfpg4yvn6g3xyzchp8w7hqn74q";
  };

  postPatch = ''
    substituteInPlace cpp/build/support.mk \
      --replace '$(shell which doxygen)' ${doxygen}/bin/doxygen \
      --replace '$(shell which dot)' ${graphviz}/bin/dot \
      --replace '$(shell which xmllint)' ${libxml2}/bin/xmllint \
      --replace '$(shell which pkg-config)' ${pkgconfig}/bin/pkg-config \
    '';

  preInstall = ''
    export PREFIX=$out
    '';
}

