{ stdenv, lib, fetchurl, glib, git,
  rlwrap, curl, pkg-config, perl, makeWrapper, tzdata, ncurses,
  pango, cairo, gtk2, gtk2-x11, gdk-pixbuf, gtkglext, pcre, openal,
  xorg, openssl, unzip, gnome2, libGL, libGLU, udis86, runCommand, interpreter,
  blas, zlib, freealut, libogg, libvorbis }:

let
  inherit (lib) optional;
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
    # FIXME: doesn't apply cleanly
    # ./0001-pathnames-redirect-work-prefix-to-.local-share-facto.patch
    # ./0002-adjust-unit-test-for-finding-executables-in-path-for.patch
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

    # update default paths in factor-listener.el for fuel mode
    substituteInPlace misc/fuel/fuel-listener.el \
      --replace '(defcustom fuel-factor-root-dir nil' "(defcustom fuel-factor-root-dir \"$out/lib/factor\""
    '';

  runtimeLibs =  with xorg; [
    glib
    pango cairo
    gtk2-x11
    gdk-pixbuf
    gnome2.gtkglext
    pcre
    libGL
    libGLU
    freealut
    openssl
    udis86 # available since NixOS 19.09
    openal
    libogg
    libvorbis
    zlib
  ];

  buildInputs = with xorg; [
    git rlwrap curl pkg-config perl makeWrapper
    unzip
  ] ++ runtimeLibs;

  runtimeLibPath = "/run/opengl-driver/lib:" + lib.makeLibraryPath runtimeLibs;

  configurePhase = "true";

  LD_LIBRARY_PATH = "${runtimeLibPath}";
  buildPhase = ''
    patchShebangs ./build.sh
    # Factor uses XDG_CACHE_HOME for cache during compilation.
    # We can't have that. So, set it to $TMPDIR/.cache
    export XDG_CACHE_HOME=$TMPDIR/.cache && mkdir -p $XDG_CACHE_HOME
    ./build.sh compile
    ./build.sh bootstrap
  '';

  doCheck = true;

  # For now, the check phase runs, but should always return 0.  This way the
  # logs contain the test failures until all unit tests are fixed.  Then, it
  # should return 1 if any test failures have occured.
  checkPhase = ''
    ./factor -e='USING: tools.test zealot.factor sequences namespaces formatting
    ;
    zealot-core-vocabs "compiler" suffix [ test ] each :test-failures
    test-failures get length "Number of failed Tests: %d\n" printf'
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib/factor
    cp -r factor factor.image boot*.image LICENSE.txt README.md basis core extra misc $out/lib/factor

    # Create a wrapper in bin/
    wrapProgram $out/lib/factor/factor --prefix LD_LIBRARY_PATH : \
      "${runtimeLibPath}"
    mv $out/lib/factor/factor.image $out/lib/factor/.factor-wrapped.image
    mv $out/lib/factor/factor $out/bin/

    # Emacs fuel expects the image being named `factor.image` in the factor base dir
    ln -s $out/lib/factor/.factor-wrapped.image $out/lib/factor/factor.image

    # Create a wrapper in lib/factor
    makeWrapper $out/lib/factor/.factor-wrapped $out/lib/factor/factor --prefix LD_LIBRARY_PATH : \
      "${runtimeLibPath}"

    # install fuel mode for emacs
    mkdir -p $out/share/emacs/site-lisp
    ln -s $out/lib/factor/misc/fuel/*.el $out/share/emacs/site-lisp/
  '';

  meta = with lib; {
    homepage = http://factorcode.org;
    license = licenses.bsd2;
    description = "A concatenative, stack-based programming language";

    maintainers = [ maintainers.vrthra maintainers.spacefrogg ];
    platforms = [ "x86_64-linux" ];
  };

  passthru.withLibs = wrapFactor;
}
