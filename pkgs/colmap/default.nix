{stdenv, lib, fetchFromGitHub, cmake, ceres-solver, boost, eigen, suitesparse, freeimage, glew, gflags, glog, openmp ? null
, qtbase
, ...}:

stdenv.mkDerivation rec {
  name = "colmap-${version}";
  version = "3.5-dev.1";

  src = fetchFromGitHub {
    owner = "colmap";
    repo = "colmap";
    rev = version;
    sha256 = "1y2pdwkzy95y60kphmgnj0p2c70pb3szycwcqnx9d2pn6wavn75r";
  };

  buildInputs = [ cmake ceres-solver boost eigen suitesparse freeimage glew gflags glog qtbase ] ++ lib.optional stdenv.cc.isClang openmp;

  cmakeFlags = [ "-DBOOST_STATIC=OFF" "-DTESTS_ENABLED=ON"];

  postPatch = ''
    substituteInPlace cmake/CMakeHelper.cmake \
      --replace "DESTINATION lib" "DESTINATION \''${CMAKE_INSTALL_LIBDIR}"
    substituteInPlace CMakeLists.txt \
      --replace "DESTINATION include" "DESTINATION \''${CMAKE_INSTALL_INCLUDEDIR}"
  '';

  checkPhase = ''
    QT_PLUGIN_PATH=${qtbase}/${qtbase.qtPluginPrefix} make test
  '';

  outputs = [ "out" "dev" "lib" ];
}
