{ stdenv, fetchurl, mfcl8650cdwlpr, makeWrapper, dpkg, pkgsi686Linux, coreutils }:

let model = "mfcl8650cdw";
in
stdenv.mkDerivation rec {
  name = "${model}-cupswrapper-${version}";
  version = "1.1.3-1";

  src = fetchurl {
    url = "http://download.brother.com/welcome/dlf101089/${model}cupswrapper-${version}.i386.deb";
    sha256 = "12p41lw0vck3540ql84spx8n2zwy6a14zmaaqxaz2gjr74lvrgn4";
  };

  nativeBuildInputs = [ makeWrapper ];
  # buildInputs = [ mfcl8650cdwlpr ];
  buildInputs = [ dpkg ];

  unpackPhase = "true";

  # these are defined for the substituteAll call below
  printer_model = model;
  printer_name = stdenv.lib.toUpper model;
  rcpath = "${mfcl8650cdwlpr}/opt/brother/Printers/${model}/inf/br${model}rc";
  filterpath = "${mfcl8650cdwlpr}/opt/brother/Printers/${model}/lpd/filter${model}";
  binPath = stdenv.lib.makeBinPath [ coreutils ];

  installPhase = ''
    dpkg-deb -x $src $out

    patchelf --set-interpreter ${pkgsi686Linux.stdenv.cc.libc.out}/lib/ld-linux.so.2 $out/opt/brother/Printers/${model}/cupswrapper/brcupsconfpt1
    # make rcfile-modifying script available to confpt1 binary
    wrapProgram $out/opt/brother/Printers/${model}/cupswrapper/brcupsconfpt1 \
      --prefix PATH ":" ${ stdenv.lib.makeBinPath [ mfcl8650cdwlpr ] }

    PPD_FOLDER=$out/share/cups/model/Brother
    mkdir -p $PPD_FOLDER
    ln -s $out/opt/brother/Printers/${model}/cupswrapper/brother_${model}_printer_en.ppd $PPD_FOLDER

    CUPSFILTERFOLDER=$out/lib/cups/filter
    mkdir -p $CUPSFILTERFOLDER

    # the supplied wrapper_script contains what the provided install-script would have produced.
    export cupsconfpath="$out/opt/brother/Printers/${model}/cupswrapper/brcupsconfpt1"
    substituteAll ${./wrapper_script} $out/lib/cups/filter/brother_lpdwrapper_${model}
    chmod +x $out/lib/cups/filter/brother_lpdwrapper_${model}
    '';

  meta = with stdenv.lib; {
    homepage = http://www.brother.com/;
    description = "Brother MFC-J6510DW CUPS wrapper driver";
    license = with licenses; unfree;
    platforms = with platforms; linux;
    downloadPage = http://support.brother.com/g/b/downloadtop.aspx?c=eu_ot&lang=en&prod=mfcl8650cdw_eu_cn;
    maintainers = with maintainers; [ ];
  };
}
