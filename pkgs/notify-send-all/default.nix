{ lib, stdenv, fetchFromGitHub, libnotify
}:

let version = "2023-06-08";

in

stdenv.mkDerivation {
  inherit version;
  pname = "notify-send-all";

  buildInputs = [ libnotify ];

  src = fetchFromGitHub {
    owner = "hackerb9";
    repo = "notify-send-all";
    rev = "c7da5abd544b87512f7bed33ed73ebba3adc6dc4";
    sha256 = "sha256-+Y19RaGLQaVmToS3f4z2luBdCxLWo8hoCklMI3BRx44=";
  };

  installPhase = ''
    mkdir -p $out/bin

    sed -i '11d' notify-send-all

    substituteInPlace notify-send-all \
      --replace /bin/test test \
      --replace "notify-send " "${libnotify}/bin/notify-send "
    install -m 0755 notify-send-all $out/bin
    ln -s $out/bin/notify-send-all $out/bin/notify-send-to
  '';
}
