{ stdenv, pkgs, lib, fetchFromGitHub, xorg}:

stdenv.mkDerivation rec {
  name = "clipnotify-${version}";
  version = "1.0.0";

  buildInputs = [ xorg.libX11 xorg.libXfixes ];

  src = fetchFromGitHub  {
      owner = "cdown";
      repo = "clipnotify";
      rev = version;
      sha256 = "1vskrvkl2vpbzlp5l0k9lcnz45q49gl3flsm84v777hk1rzh5y7n";
  };

  installPhase = ''
  mkdir -p $out/bin
  cp clipnotify $out/bin
  '';

  meta = with stdenv.lib; {
    description = "Command line tool to notify on new x clipboard events";
    homepage = https://packages.qa.debian.org/u/unp.html;
    license = with licenses; [ publicDomain ];
    maintainers = [ maintainers.timor ];
    platforms = platforms.unix;
  };
}
