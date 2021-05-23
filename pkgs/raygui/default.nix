{ stdenv, fetchFromGitHub, raylib }:

let 
  version = "2.8";
  src = fetchFromGitHub {
    owner = "raysan5";
    repo = "raygui";
    rev = version;
    sha256 = "0m4js9wgjsdrp0c4rg4jk643rygh1vkf41dvif6ijml33cyz79gi";
    fetchSubmodules = false;
  };
in
stdenv.mkDerivation rec {
  pname = "raygui";
  inherit version;
  inherit src;

  nativeBuildInputs = [ raylib ];
  buildPhase = ''
    cp ${./raygui.c} ./raygui.c
    gcc -c -fpic raygui.c
    gcc -shared -o libraygui.so raygui.o
  '';
  installPhase = ''
    mkdir -p $out/lib
    cp libraygui.so $out/lib/
  '';
}
