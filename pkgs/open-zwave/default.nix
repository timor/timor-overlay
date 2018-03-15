{stdenv, fetchurl, unzip, libudev, doxygen, graphviz, libxml2, pkgconfig, fontconfig, makeFontsConf, freefont_ttf}:

stdenv.mkDerivation rec {
  name = "open-zwave-${version}";
  version = "1.5";

  propagatedNativeBuildInputs = [ pkgconfig ];
  nativeBuildInputs = [ unzip graphviz fontconfig ];
  buildInputs = [ libudev ];
  src = fetchurl {
    url = "https://github.com/OpenZWave/open-zwave/archive/V1.5.zip";
    sha256 = "1cq9kajk388kyby7zn8li78rbdcfpg4yvn6g3xyzchp8w7hqn74q";
  };

  postPatch = ''
    sed -i.bak '93,97 d;92 a\
    pkgconfigdir=\$(PREFIX)/lib/pkgconfig
    27 c\
    GIT :=' cpp/build/support.mk
    substituteInPlace cpp/build/support.mk \
      --replace '$(shell which doxygen)' ${doxygen}/bin/doxygen \
      --replace '$(shell which dot)' ${graphviz}/bin/dot \
      --replace '$(shell which xmllint)' ${libxml2}/bin/xmllint \
      --replace '$(shell which pkg-config)' ${pkgconfig}/bin/pkg-config
    substituteInPlace cpp/build/ozw_config.in \
      --replace 'pcfile=@pkgconfigfile@' "pcfile=$out/@pkgconfigfile@"
    sed -i.bak '16,18 s/PREFIX/DESTDIR/' cpp/build/Makefile
    '';

  preBuild = ''
    makeFlagsArray=("DESTDIR=$out" "PREFIX=")
    '';

  enableParallelBuilding = true;

  FONTCONFIG_FILE = makeFontsConf {
    fontDirectories = [ freefont_ttf ];
  };
}
