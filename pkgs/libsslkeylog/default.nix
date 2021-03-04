{ stdenv, openssl, fetchgit }:

stdenv.mkDerivation {
  pname = "libsslkeylog";
  version = "9999";

  src = fetchgit {
    url = "https://git.lekensteyn.nl/peter/wireshark-notes";
    rev = "4a7586873954c711b9766c4ead23134d8d923281";
    sha256 = "0328mycl1lpfx40vsn1wnb6rsbpxbymrhsljz5lchzbbakcqg8p6";
    name = "source";
  };

  sourceRoot = "source/src";

  installPhase = ''
    mkdir -p $out/lib
    install libsslkeylog.so $out/lib
  '';

  buildInputs = [ openssl ];
}
