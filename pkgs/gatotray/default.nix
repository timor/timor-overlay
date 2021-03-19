{stdenv, pkgconfig, gdk_pixbuf, gtk2, fetchFromGitHub }:

let version = "3.3"; in

stdenv.mkDerivation {
  pname = "gatotray";
  inherit version ;

  src = fetchFromGitHub {
    owner = "gatopeich";
    repo = "gatotray";
    rev = "v${version}";
    sha256 = "08hy1zyq0nkrhmp599x6k0sn93a4484yi2lfgl0xf25lwdsrsyr5";
  };

  patches = [ ./0001-index-on-fix-g-free-806f364-gatotray-3.3-with-memory.patch ];

  postPatch = ''
    substituteInPlace Makefile --replace /usr/local/bin $out/bin --replace /usr/share/ $out/share/
    sed -i "/strip/d" Makefile
  '';

  nativeBuildInputs = [pkgconfig];
  buildInputs = [gdk_pixbuf gtk2];

  dontConfigure = true;

  preInstall = ''
    mkdir -p $out/bin
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons

  '';
}
