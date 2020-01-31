{stdenv, lib, fetchurl, cmake, pythonPackages, tk, bison, flex, openblas, boost, zlib, gfortran }:

pythonPackages.buildPythonApplication rec {
  name = "code-aster-${version}";
  version = "14.2.0-1";

  src = fetchurl {
    url = "https://www.code-aster.org/FICHIERS/aster-full-src-${version}.noarch.tar.gz";
    sha256 = "1ig00r486vvp4qb4z5s37lvqk7cp5z4ikdsrkpnmnv4bbjbby311";
  };

  postPatch = ''
    (
    cd SRC
    tar xaf hdf5-1.8.14.tar.gz
    patchShebangs hdf5-1.8.14
    substituteInPlace hdf5-1.8.14/configure \
      --replace '/bin/mv' mv
    tar caf hdf5-1.8.14.tar.gz hdf5-1.8.14
    )
  '';

  buildInputs = [ cmake
    pythonPackages.python pythonPackages.numpy tk bison flex openblas boost zlib gfortran ];

  format = "other";

  NIX_LDFLAGS = [ "-lopenblas" ];

  dontUseCmakeBuildDir = true;

  dontUseCmakeConfigure = true;

  # hack: reuse cmake path list to get setup script to pick up paths
  configurePhase = ''
    export LD_LIBRARY_PATH="${lib.makeLibraryPath ([ stdenv.cc.cc stdenv.cc.libc ] ++ buildInputs) }"
    '';

  buildPhase = "python setup.py install --prefix=$out --noprompt --debug";
}
