{ stdenv, fetchurl, pkgsi686Linux, dpkg, makeWrapper, coreutils, gnused, gawk, file, cups, patchelf, ghostscript, a2ps, bsdiff }:

let model = "mfcl8650cdw";
in
stdenv.mkDerivation rec {
  name = "${model}lpr-${version}";
  version = "1.1.2-1";

  src = fetchurl {
    url = "http://download.brother.com/welcome/dlf101088/${model}lpr-${version}.i386.deb";
    sha256 = "043f0v51bbr9l952smzxlr52k8933s64z5qvwp4z2ry08jqng4rw";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ cups ghostscript dpkg a2ps bsdiff ]; # TODO remove cups???

  unpackPhase = "true";

  # see below
  brprintconf_script = ''
   #!/bin/sh
   cd $(mktemp -d)
   ln -s @out@/usr/bin/brprintconf_${model} brprintconf_${model}
   ln -s @out@/opt/brother/Printers/${model}/inf/br${model}func br${model}func
   ln -s @out@/opt/brother/Printers/${model}/inf/br${model}rc br${model}rc
   exec ./brprintconf_${model} "$@"
  '';

  # The precompiled filter looks int /opt paths for data files.  Since
  # these will not be searched in $PATH, we patch the paths to be
  # relative and wrap the whole thing in a temporary directory.  Taken
  # from mfcl8650lpr/default.nix.
  filter_script = ''
    #!/bin/sh
    cd $(mktemp -d)
    ln -s @out@/opt/brother/Printers/${model}/lpd/br${model}filter_patched br${model}filter
    ln -s @out@/opt/brother/Printers/${model}/inf/ImagingArea ImagingArea
    ln -s @out@/opt/brother/Printers/${model}/inf/PaperDimension PaperDimension
    mkdir -p ./${model}/inf
    ln -s @out@/opt/brother/Printers/${model}/inf/lut ${model}/inf/lut
    exec ./br${model}filter "$@"
  '';

  installPhase = ''
    dpkg-deb -x $src $out

    substituteInPlace $out/opt/brother/Printers/${model}/lpd/filter${model} \
      --replace /opt "$out/opt"
    substituteInPlace $out/opt/brother/Printers/${model}/lpd/psconvertij2 \
      --replace "GHOST_SCRIPT=\`which gs\`" "GHOST_SCRIPT=${ghostscript}/bin/gs"
    substituteInPlace $out/opt/brother/Printers/${model}/inf/setupPrintcapij \
      --replace "/opt/brother/Printers" "$out/opt/brother/Printers" \
      --replace "printcap.local" "printcap"

    # patch br${model}filter for relative paths, fix interpreter
    bspatch $out/opt/brother/Printers/${model}/lpd/br${model}filter \
      $out/opt/brother/Printers/${model}/lpd/br${model}filter_patched \
      ${./brfilter_patch.bsdiff}
    chmod +x $out/opt/brother/Printers/${model}/lpd/br${model}filter_patched
    patchelf --set-interpreter ${pkgsi686Linux.stdenv.cc.libc.out}/lib/ld-linux.so.2 \
      --set-rpath $out/opt/brother/Printers/${model}/inf:$out/opt/brother/Printers/${model}/lpd \
      $out/opt/brother/Printers/${model}/lpd/br${model}filter_patched

    # override the filter binary with the script
    echo -n "$filter_script" > $out/opt/brother/Printers/${model}/lpd/br${model}filter
    substituteInPlace $out/opt/brother/Printers/${model}/lpd/br${model}filter --replace @out@ $out
    chmod +x $out/opt/brother/Printers/${model}/lpd/br${model}filter

    # patch printconf for relative paths, replace and fix interpreter
    bspatch $out/usr/bin/brprintconf_${model} $out/usr/bin/brprintconf_${model}_patched ${./brprintconf_patch.bsdiff}   chmod +x $out/usr/bin/brprintconf_${model}_patched
    mv $out/usr/bin/brprintconf_${model}_patched $out/usr/bin/brprintconf_${model}
    patchelf --set-interpreter ${pkgsi686Linux.stdenv.cc.libc.out}/lib/ld-linux.so.2 $out/usr/bin/brprintconf_${model}
    mkdir -p $out/bin
    echo -n "$brprintconf_script" > $out/bin/brprintconf_${model}
    chmod +x $out/bin/brprintconf_${model}
    substituteInPlace $out/bin/brprintconf_${model} --replace @out@ $out

    wrapProgram $out/opt/brother/Printers/${model}/lpd/psconvertij2 \
      --prefix PATH ":" ${ stdenv.lib.makeBinPath [ coreutils gnused gawk ] }
    wrapProgram $out/opt/brother/Printers/${model}/lpd/filter${model} \
      --prefix PATH ":" ${ stdenv.lib.makeBinPath [ coreutils gnused file ghostscript a2ps ] }
  '';

  meta = {
    homepage = http://www.brother.com/;
    description = "Brother MFC-L8650CDW LPR driver";
    license = stdenv.lib.licenses.unfree;
    platforms = stdenv.lib.platforms.linux;
    downloadPage = http://support.brother.com/g/b/downloadtop.aspx?c=eu_ot&lang=en&prod=mfcl8650cdw_eu_cn;
    maintainers = [ ];
  };
}
