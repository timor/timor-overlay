{ stdenv, fetchurl, glib, git,
  rlwrap, curl, pkgconfig, perl, makeWrapper, tzdata, ncurses,
  pango, cairo, gtk2, gdk_pixbuf, gtkglext, pcre,
  mesa_glu, xorg, openssl, unzip, udis86 }:

let
  inherit (stdenv.lib) optional;

in stdenv.mkDerivation rec {
  name = "factor-lang-${version}";
  version = "0.98";
  rev = "7999e72aecc3c5bc4019d43dc4697f49678cc3b4";

  src = fetchurl {
    url = http://downloads.factorcode.org/releases/0.98/factor-src-0.98.zip;
    sha256 = "01ip9mbnar4sv60d2wcwfz62qaamdvbykxw3gbhzqa25z36vi3ri";
  };

  patches = [
    ./staging-command-line-0.98-pre.patch
    ./0001-pathnames-redirect-work-prefix-to-.local-share-facto.patch
    ./fuel-dir.patch
    # preempt https://github.com/factor/factor/pull/2139
    ./fuel-dont-jump-to-using.patch
  ];

  runtimeLibs =  with xorg; [
    stdenv.glibc.out
    glib
    libX11 pango cairo gtk2 gdk_pixbuf gtkglext pcre
    mesa_glu libXmu libXt libICE libSM openssl udis86
  ];

  buildInputs = with xorg; [
    git rlwrap curl pkgconfig perl makeWrapper
    unzip
  ] ++ runtimeLibs;

  runtimeLibPath = stdenv.lib.makeLibraryPath runtimeLibs;

  buildPhase = ''
    sed -ie '4i GIT_LABEL = heads/master-${rev}' GNUmakefile
    make linux-x86-64
    # De-memoize xdg-* functions, otherwise they break the image.
    sed -ie 's/^MEMO:/:/' basis/xdg/xdg.factor
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib/factor
    # The released image has library path info embedded, so we
    # first have to recreate the boot image with Nix paths, and
    # then use it to build the Nix release image.
    cp boot.unix-x86.64.image $out/lib/factor/factor.image

    cp -r basis core extra misc $out/lib/factor

    # Factor uses XDG_CACHE_HOME for cache during compilation.
    # We can't have that. So set it to $TMPDIR/.cache
    export XDG_CACHE_HOME=$TMPDIR/.cache && mkdir -p $XDG_CACHE_HOME

    # There is no ld.so.cache in NixOS so we patch out calls to that completely.
    # This should work as long as no application code relies on `find-library*`
    # to return a match, which currently is the case and also a justified assumption.

    sed -ie 's#"lib" prepend load-ldconfig-cache#{ }#' \
      $out/lib/factor/basis/alien/libraries/finder/linux/linux.factor

    # Some other hard-coded paths to fix:
    sed -ie 's#/usr/share/zoneinfo/#${tzdata}/share/zoneinfo/#g' \
      $out/lib/factor/extra/tzinfo/tzinfo.factor

    sed -ie 's#/usr/share/terminfo#${ncurses.out}/share/terminfo#g' \
      $out/lib/factor/extra/terminfo/terminfo.factor

    cp ./factor $out/bin
    wrapProgram $out/bin/factor --prefix LD_LIBRARY_PATH : \
      "${runtimeLibPath}"

    sed -ie 's#/bin/.factor-wrapped#/lib/factor/factor#g' $out/bin/factor
    mv $out/bin/.factor-wrapped $out/lib/factor/factor

    echo "Building first full image from boot image..."

    # build full factor image from boot image
    (cd $out/bin && ./factor  -script -e='"unix-x86.64" USING: system bootstrap.image memory ; make-image save 0 exit' )

    echo "Building new boot image..."
    # make a new bootstrap image
    (cd $out/bin && ./factor  -script -e='"unix-x86.64" USING: system tools.deploy.backend ; make-boot-image 0 exit' )

    echo "Building final full image..."
    # rebuild final full factor image to include all patched sources
    (cd $out/lib/factor && ./factor -i=boot.unix-x86.64.image)

    # install fuel mode for emacs
    mkdir -p $out/share/emacs/site-lisp
    # update default paths in factor-listener.el for fuel mode
    substituteInPlace misc/fuel/fuel-listener.el \
      --subst-var-by fuel_factor_root_dir $out/lib/factor \
      --subst-var-by fuel_listener_factor_binary $out/bin/factor
    cp misc/fuel/*.el $out/share/emacs/site-lisp/
  '';

  meta = with stdenv.lib; {
    homepage = http://factorcode.org;
    license = licenses.bsd2;
    description = "A concatenative, stack-based programming language";

    maintainers = [ maintainers.vrthra maintainers.spacefrogg ];
    platforms = [ "x86_64-linux" ];
  };
}
