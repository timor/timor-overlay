{stdenv, lib, pkg-config, gdk-pixbuf, gtk2, fetchFromGitHub }:

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

  # Fix #4 for latest stable version
  patches = [ ./0001-Fix-issue-4-free-invalid-pointer.patch ];

  postPatch = ''
    # Substitute hard-coded install destinations
    substituteInPlace Makefile --replace /usr/local/bin $out/bin --replace /usr/share/ $out/share/

    # Leave stripping to fixup phase
    sed -i "/strip/d" Makefile
  '';

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ gdk-pixbuf gtk2 ];

  dontConfigure = true;

  preInstall = ''
    mkdir -p $out/bin
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons
  '';

  meta = {
    description = "A minimalistic graphical system tray CPU monitor";
    homepage = "https://github.com/gatopeich/gatotray";
    license = lib.licenses.cc-by-30;
    maintainers = [ lib.maintainers.timor ];
    platforms = lib.platforms.linux;
  };
}
