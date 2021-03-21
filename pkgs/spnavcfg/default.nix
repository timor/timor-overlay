{ stdenv, lib, fetchurl, gtk2, gtk2-x11, pkg-config, libredirect, makeWrapper }:

let version = "0.3.1";
in

stdenv.mkDerivation rec {
  name = "spnavcfg-${version}";
  inherit version;

  src = fetchurl {
   url = "mirror://sourceforge/spacenav/spnavcfg-${version}.tar.gz";
   sha256 = "1834pswbyz61x9mb7smms6f4v4jad90h9zxj1scn69ri5zi691qa";
  };

  patches = [ ./non-root.patch ];

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ gtk2 pkg-config ];

      # --run 'export NIX_REDIRECTS="/var/run=''${XDG_RUNTIME_DIR}:/xdgconfighome=''${XDG_CONFIG_HOME:-~/.config}"' \
  postInstall = ''
    wrapProgram $out/bin/spnavcfg \
      --run 'export NIX_REDIRECTS="/XDG_CONFIG_HOME=''${XDG_CONFIG_HOME:-''${HOME}/.config}:/var/run=''${XDG_RUNTIME_DIR}"' \
      --prefix LD_PRELOAD : ${libredirect}/lib/libredirect.so
  '';

  meta = with lib; {
    description = "Spacenav SDK development libraries";
    homepage = "http://spacenav.sourceforge.net";
    license = licenses.gpl3Plus;
    maintainers = [ maintainers.timor ];
    platforms = platforms.linux;
  };
}
