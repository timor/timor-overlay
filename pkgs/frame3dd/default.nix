{ stdenv, fetchurl, unzip, scons, soqt, cppunit }:

stdenv.mkDerivation rec {
  name = "frame3dd-${version}";
  version = "r583";

  src = fetchurl {
    url = "https://sourceforge.net/code-snapshots/svn/f/fr/frame3dd/code/frame3dd-code-r583-trunk.zip";
    sha256 = "01p1ixpwr4jhl13kpcqnp34qwwpm85h37hyh0jasq4rnsrxk197f";
  };

  patches = [ ./scons-path.patch ];

  patchFlags = "-p1 -l";

  postPatch = ''
    ln -s Frame3DD-manual.html doc/user-manual.html
  '';

  buildInputs = [ unzip scons soqt cppunit ];

  buildPhase = false;

  installPhase = ''
    scons INSTALL_PREFIX=$out install
  '';

}
