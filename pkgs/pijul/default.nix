{ stdenv, fetchurl, rustPlatform, darwin }:

with rustPlatform;

buildRustPackage rec {
  name = "pijul-${version}";
  version = "0.8.3";

  src = fetchurl {
    url = "https://pijul.org/releases/${name}.tar.gz";
    sha256 = "45ef9ca3ae9d62953731b0c4b88c78fda7efae48e6970454c20581d49e10d4f6";
  };

  sourceRoot = "${name}/pijul";

  buildInputs = stdenv.lib.optionals stdenv.isDarwin
    (with darwin.apple_sdk.frameworks; [ Security ]);

  doCheck = false;

  depsSha256 = "1cnr08qbpia3336l37k1jli20d7kwnrw2gys8s9mg271cb4vdx03";

  meta = with stdenv.lib; {
    description = "A distributed version control system";
    homepage = https://pijul.org;
    license = with licenses; [ gpl2Plus ];
    maintainers = [ maintainers.gal_bolle ];
    platforms = platforms.all;
  };
}
