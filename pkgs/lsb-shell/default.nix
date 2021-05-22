{  # lib, stdenv, xorg

# # additionally for LSB
# , gnumake, coreutils, zlib, ncurses5, glib, bashInteractive
# , nspr, nss, pam, openssl, libGL, libGLU, qt4, alsaLib, cairo
# , fontconfig, freetype, gdk_pixbuf, gtk2-x11, pango, libjpeg, libpng, libtiff
# ,
buildFHSUserEnv}:

let lsb-packages = p: with p; with p.xorg; [ # LSB Core/Common
    (lib.hiPrio stdenv.cc.cc.lib) stdenv.cc.libc.out
    stdenv.cc stdenv.cc.bintools gnumake
    bashInteractive
    ncurses5 nspr nss pam openssl zlib coreutils
    # LSB Desktop
    libGL libGLU qt4 libSM libX11 libXext libXft libXi libXrender libXt
    libXxf86vm libXrandr libxcb libXcomposite libXmu
    libXtst alsaLib cairo fontconfig freetype gdk_pixbuf gtk2-x11 glib.out
    pango.out libjpeg libpng libtiff sane-backends cups.lib libxml2 libxslt
    xdg_utils
    # LSB Runtime Languages
    python perl
    # GTK3 (trial)
    # (lib.hiPrio gtk3)
    ] ;

in

buildFHSUserEnv {
  name = "lsb-shell";
  targetPkgs = lsb-packages ;
}
