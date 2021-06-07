{ lib, stdenv, fetchFromGitHub, premake5, xorg }:


stdenv.mkDerivation rec {
  pname = "shader-slang";
  version = "0.18.25";

  src = fetchFromGitHub {
    owner = "shader-slang";
    repo = "slang";
    rev = "v${version}";
    sha256 = "076806gf8a5fw8inryp6p7rfr4lxlcx3hfsp6sm8j42nnqa324qa";
    fetchSubmodules = true ;
  };

  postPatch = ''
    sed -i '/staticruntime/d' premake5.lua
  '';
  hardeningDisable = ["fortify"];

  nativeBuildInputs = with xorg;[
    premake5
    libX11
  ];

  buildPhase = "make config=debug_x64 slang slangc";

  installPhase = ''
    mkdir -p $out/bin
    mkdir $out/lib
    mkdir $out/include

    install -t $out/lib bin/linux-x64/debug/*.so
    install -t $out/bin bin/linux-x64/debug/slangc
    install -t $out/include slang.h
  '';

}
