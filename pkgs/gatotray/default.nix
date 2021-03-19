{stdenv, pkgconfig, gdk_pixbuf, gtk2, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "gatotray";
  version = "2017-05-08";

  src = fetchFromGitHub {
    owner = "kafene";
    repo = "gatotray";
    rev = "4d8e78ca0b7c2eeefd33d2d2b80068862d6c54ed";
    sha256 = "1rv9gd63s3zj43708w6fydfvf37sl5ir3s03lzkvry7fhar66ywc";
  };

  nativeBuildInputs = [pkgconfig];
  buildInputs = [gdk_pixbuf gtk2];

  dontConfigure = true;

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/icons
    install gatotray $out/bin
    install gatotray.xpm $out/share/icons
  '';
}
