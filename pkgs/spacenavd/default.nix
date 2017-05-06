{ stdenv, fetchurl, libX11 }:

stdenv.mkDerivation rec {
  name = "spacenavd-${version}";
  version = "0.6";

  src = fetchurl {
   #url = "mirror://sourceforge/project/spacenav/spacenav%20daemon/spacenav%20${version}/spacenavd-${version}.tar.gz";
   url = "mirror://sourceforge/spacenav/spacenavd-${version}.tar.gz";
   sha256 = "1ayhi06pv5lx36m5abwbib1wbs75svjkz92605cmkaf5jszh7ln2";
  };

  buildInputs = [ libX11 ];

  meta = with stdenv.lib; {
    description = "Open Source driver for 3DConnexion Space Navigator devices";
    homepage = "http://spacenav.sourceforge.net";
    license = licenses.gpl3Plus;
    maintainers = [ maintainers.timor ];
    platforms = platforms.linux;
  };
}
