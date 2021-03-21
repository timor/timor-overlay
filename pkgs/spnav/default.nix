{ stdenv, lib, fetchurl, xorg}:

stdenv.mkDerivation rec {
  name = "spnav-${version}";
  version = "0.2.3";

  src = fetchurl {
   url = "mirror://sourceforge/spacenav/libspnav-${version}.tar.gz";
   sha256 = "14qzbzpfdb0dfscj4n0g8h8n71fcmh0ix2c7nhldlpbagyxxgr3s";
  };

  buildInputs = [ xorg.libX11 ];

  meta = with lib; {
    description = "Spacenav SDK development libraries";
    homepage = "http://spacenav.sourceforge.net";
    license = licenses.gpl3Plus;
    maintainers = [ maintainers.timor ];
    platforms = platforms.linux;
  };
}
