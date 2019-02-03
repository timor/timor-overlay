{stdenv, lib, innoextract,  winePackages, writeScript, requireFile }:

let wine = winePackages.base;

in

stdenv.mkDerivation rec {
  name = "Total-Annihilation-${version}";
  version = "3.1";

  buildInputs = [ innoextract ];

  src = requireFile rec {
    name = "setup_total_annihilation_commander_pack_3.1_-22139-.exe";
    sha256 = "0hsv54s55x52cx3d79zsqjcdqwzvdjn444g129vrw10ksiqikzvc";
    url = "https://www.gog.com/game/total_anihilation_commander_pack";
  };

  phases = [ "patchPhase" "installPhase"];

  installPhase = ''
    installDir="$out/Total-Annihilation"
    mkdir -p $installDir
    innoextract -d $installDir '${src}'

    mkdir $out/bin

    echo "Writing wrapper to $out/bin/totala ..."
    cat > $out/bin/totala <<EOF
    #!/bin/sh
    ${lib.getBin wine}/bin/wine $installDir/Totala.exe
    EOF
    chmod +x $out/bin/totala
    echo "Done.";
  '';

  passthru = { inherit wine;};

}
