{ lib, stdenv, fetchurl, xorg }:

stdenv.mkDerivation rec {
  name = "spacenavd-${version}";
  version = "0.8";

  src = fetchurl {
   #url = "mirror://sourceforge/project/spacenav/spacenav%20daemon/spacenav%20${version}/spacenavd-${version}.tar.gz";
   url = "mirror://sourceforge/spacenav/spacenavd-${version}.tar.gz";
   sha256 = "0pwiadw02j8j48ml77n26mybm26zai7p3x5sxwlrwfpvw0wq89bf";
  };

  patches = [ ./pidfile.patch ];

  # postPatch = ''
  #   patch spnavd_ctl <<END_PATCH
  #   @@ -18,2 +18,1 @@
  #   -	DISPLAY=":0"
  #   -	xdpyinfo >/dev/null 2>/dev/null
  #   +	@xdpyinfo@/bin/xdpyinfo >/dev/null 2>/dev/null
  #   END_PATCH
  # '';

  buildInputs = [ xorg.libX11 ];

  inherit (xorg) xdpyinfo;
  postInstall = ''
    # sed -i 's#xdpyinfo#${lib.getBin xorg.xdpyinfo}/bin/xdpyinfo#' $out/bin/spnavd_ctl
    substituteAllInPlace $out/bin/spnavd_ctl
    substituteInPlace $out/bin/spnavd_ctl --replace /var/run /run/spacenavd
  '';

  meta = with stdenv.lib; {
    description = "Open Source driver for 3DConnexion Space Navigator devices";
    homepage = "http://spacenav.sourceforge.net";
    license = licenses.gpl3Plus;
    maintainers = [ maintainers.timor ];
    platforms = platforms.linux;
  };
}
