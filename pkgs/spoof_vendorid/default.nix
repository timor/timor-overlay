{ stdenv, cmake, fetchFromGitHub, pkg-config, xorg } :

stdenv.mkDerivation {
  pname = "spoof_vendorid" ;
  version = "2019-08-20";

  src = fetchFromGitHub {
    owner = "volca02";
    repo = "spoof_vendorid";
    rev = "5a261e076c90858afb239a81d797bc84bfca61da";
    sha256 = "1ap43l2m5k7gkzybwzqzyv87hmjcjdb8as81bijspal0v5qldiy5";
  };

  cmakeFlags = [ "-DBUILD_WSI_WAYLAND_SUPPORT=OFF"];
  nativeBuildInputs = with xorg; [cmake pkg-config libxcb libX11 libXrandr];

  installPhase = ''
    mkdir -p $out/share/spoof_vendorid
    cp libVkLayer_vendorid_layer.so VkLayer_vendorid_layer.json $out/share/spoof_vendorid/
  '';
}
