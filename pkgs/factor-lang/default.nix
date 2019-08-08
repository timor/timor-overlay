{ stdenv, lib, fetchurl, glib, git,
  rlwrap, curl, pkgconfig, perl, makeWrapper, tzdata, ncurses,
  pango, cairo, gtk2, gdk_pixbuf, gtkglext, pcre, openal,
  mesa_glu, xorg, openssl, unzip, udis86, runCommand, interpreter }:

let
  inherit (stdenv.lib) optional;
  wrapFactor = runtimeLibs:
    runCommand (lib.appendToName "with-libs" interpreter).name {
      buildInputs = [ makeWrapper ];} ''
        mkdir -p $out/bin
        makeWrapper ${interpreter}/bin/factor $out/bin/factor \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs}
      '';
in
stdenv.mkDerivation rec {
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
    ./0002-adjust-unit-test-for-finding-executables-in-path-for.patch
    ./fuel-dir.patch
    # preempt https://github.com/factor/factor/pull/2139
    ./fuel-dont-jump-to-using.patch
  ];

  postPatch = ''
    # There is no ld.so.cache in NixOS so we patch out calls to that completely.
    # This should work as long as no application code relies on `find-library*`
    # to return a match, which currently is the case and also a justified assumption.
    # TODO: put stuff below into patches like above

    sed -i 's#"lib" prepend load-ldconfig-cache#"lib" prepend { }#' \
      basis/alien/libraries/finder/linux/linux.factor

    # Some other hard-coded paths to fix:
    sed -i 's#/usr/share/zoneinfo/#${tzdata}/share/zoneinfo/#g' \
      extra/tzinfo/tzinfo.factor

    sed -i 's#/usr/share/terminfo#${ncurses.out}/share/terminfo#g' \
      extra/terminfo/terminfo.factor

    # De-memoize xdg-* functions, otherwise they break the image.
    sed -i 's/^MEMO:/:/' basis/xdg/xdg.factor

    sed -i '4i GIT_LABEL = heads/master-${rev}' GNUmakefile
    '';

  runtimeLibs =  with xorg; [
    stdenv.glibc.out
    glib
    libX11 pango cairo gtk2 gdk_pixbuf gtkglext pcre
    mesa_glu libXmu libXt libICE libSM openssl udis86
    openal
  ];

  buildInputs = with xorg; [
    git rlwrap curl pkgconfig perl makeWrapper
    unzip
  ] ++ runtimeLibs;

  runtimeLibPath = stdenv.lib.makeLibraryPath runtimeLibs;

  configurePhase = "true";

  buildPhase = ''
    make linux-x86-64

    # Factor uses XDG_CACHE_HOME for cache during compilation.
    # We can't have that. So set it to $TMPDIR/.cache
    export XDG_CACHE_HOME=$TMPDIR/.cache && mkdir -p $XDG_CACHE_HOME

    # The released image has library path info embedded, so we
    # first have to recreate the boot image with Nix paths, and
    # then use it to build the Nix release image.
    cp boot.unix-x86.64.image factor.image

    # Expose libraries in LD_LIBRARY_PATH for factor
    export LD_LIBRARY_PATH=${lib.makeLibraryPath runtimeLibs}:$LD_LIBRARY_PATH

    echo "=== Building first full image from boot image..."

    # build full factor image from boot image, saving the state for the next call
    ./factor  -script -e='"unix-x86.64" USING: system bootstrap.image memory ; make-image save 0 exit'

    echo "=== Building new boot image..."
    # make a new bootstrap image
    ./factor  -script -e='"unix-x86.64" USING: system bootstrap.image ; make-image 0 exit'

    echo "=== Building final full image..."
    # rebuild final full factor image to include all patched sources
    ./factor -i=boot.unix-x86.64.image

  '';

  doCheck = true;

  # For now, the check phase runs, but should always return 0.  This way the
  # logs contain the test failures until all unit tests are fixed.  Then, it
  # should return 1 if any test failures have occured.
  checkPhase = ''
    ./factor -e='USING: tools.test zealot.factor sequences ; zealot-core-vocabs "compiler" suffix [ test ] each :test-failures';
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib/factor
    cp -r factor factor.image LICENSE.txt README.md basis core extra misc $out/lib/factor

    makeWrapper $out/lib/factor/factor $out/bin/factor --prefix LD_LIBRARY_PATH : \
      "${runtimeLibPath}"

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

  passthru.withLibs = wrapFactor;
}
