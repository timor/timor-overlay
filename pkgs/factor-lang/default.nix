{ stdenv, fetchurl, fetchFromGitHub, glib, glibc, git,
  rlwrap, curl, pkgconfig, perl, makeWrapper, tzdata, ncurses,
  pango, cairo, gtk2, gdk_pixbuf, gtkglext,
  mesa, xorg, openssl }:

stdenv.mkDerivation rec {
  name = "factor-lang-${version}";
  version = "0.98-pre";
  rev = "b2de82042c5d14f80ba1fa54a6ce63344dd35daa";

  src = fetchFromGitHub {
    owner = "factor";
    repo = "factor";
    rev = rev;
    sha256 = "092i366mwc3rpdrk571c4lwf3xzxkgn9i64q654yl416af40gvk6";
  };

  factorimage = fetchurl {
    url = http://downloads.factorcode.org/images/build/boot.unix-x86.64.image.52de821e1930b4c161d0a2f5df2d719bfc181221;
    sha256 = "0gd4c60p3yp33pj09x15rg5klm3yn10xp960kg9imjjwfxal5s1d";
    name = "factorimage";
  };

  patches = [
    ./staging-command-line-0.98-pre.patch
    ./workdir-0.98-pre.patch
    ./fuel-dir.patch
  ];

  buildInputs = with xorg; [ git rlwrap curl pkgconfig perl makeWrapper
    libX11 pango cairo gtk2 gdk_pixbuf gtkglext
    mesa libXmu libXt libICE libSM openssl ];

  # buildPhase = ''
  #   make $(bash ./build-support/factor.sh make-target) GIT_LABEL=heads/master-${rev}
  # '';
  buildPhase = ''
    sed -ie '4i	GIT_LABEL = heads/master-${rev}' GNUmakefile
    make linux-x86-64
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib/factor
    # First, get a workable image. Unfortunately, no boot-image
    # is available with release info. So fetch a released image.
    # The released image has library path info embedded, so we
    # have to first recreate the boot image with Nix paths, and
    # then use it to build the Nix release image.
    # zcat ${factorimage} | (cd $out/lib && tar -xvpf - factor/factor.image )
    cp ${factorimage} $out/lib/factor/factor.image

    cp -r basis core extra $out/lib/factor

    # Factor uses XDG_CACHE_HOME for cache during compilation.
    # We can't have that. So set it to $TMPDIR/.cache
    export XDG_CACHE_HOME=$TMPDIR/.cache && mkdir -p $XDG_CACHE_HOME

    # there is no ld.so.cache in NixOS so we construct one
    # out of known libraries. The side effect is that find-lib
    # will work only on the known libraries. There does not seem
    # to be a generic solution here.
    find $(echo ${stdenv.lib.makeLibraryPath (with xorg; [
        glib libX11 pango cairo gtk2 gdk_pixbuf gtkglext
        mesa libXmu libXt libICE libSM ])} | sed -e 's#:# #g') -name \*.so.\* > $TMPDIR/so.lst

    (echo $(cat $TMPDIR/so.lst | wc -l) "libs found in cache \`/etc/ld.so.cache'";
    for l in $(<$TMPDIR/so.lst);
    do
      echo "	$(basename $l) (libc6,x86-64) => $l";
    done)> $out/lib/factor/ld.so.cache

    sed -ie "s#/sbin/ldconfig -p#cat $out/lib/factor/ld.so.cache#g" \
      $out/lib/factor/basis/alien/libraries/finder/linux/linux.factor

    sed -ie 's#/usr/share/zoneinfo/#${tzdata}/share/zoneinfo/#g' \
      $out/lib/factor/extra/tzinfo/tzinfo.factor

    sed -ie 's#/usr/share/terminfo#${ncurses.out}/share/terminfo#g' \
      $out/lib/factor/extra/terminfo/terminfo.factor

    cp ./factor $out/bin
    wrapProgram $out/bin/factor --prefix LD_LIBRARY_PATH : \
      "${stdenv.lib.makeLibraryPath (with xorg; [ glib
        libX11 pango cairo gtk2 gdk_pixbuf gtkglext
        mesa libXmu libXt libICE libSM openssl])}"

    sed -ie 's#/bin/.factor-wrapped#/lib/factor/factor#g' $out/bin/factor
    mv $out/bin/.factor-wrapped $out/lib/factor/factor

    # build full factor image from boot image
    (cd $out/bin && ./factor  -script -e='"unix-x86.64" USING: system bootstrap.image memory ; make-image save 0 exit' )

    # make a new bootstrap image
    (cd $out/bin && ./factor  -script -e='"unix-x86.64" USING: system tools.deploy.backend ; make-boot-image 0 exit' )

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

    maintainers = [ maintainers.vrthra ];
    platforms = [ "x86_64-linux" ];
  };
}
