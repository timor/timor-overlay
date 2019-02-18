{stdenv, linuxPackages}:

let
  kernel = linuxPackages.kernel;
  ksrc = kernel.src;
in
stdenv.mkDerivation rec {
  name = "kerneldocs-${kernel.version}";
  src = ksrc;

  configurePhase = "true";
  buildPhase = "true";
  installPhase = ''
    mkdir -p $out/share/doc/
    cp -R Documentation $out/share/doc/linux
  '';
}
