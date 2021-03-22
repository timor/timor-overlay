{ lib, stdenv, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "moore";
  version = "0.12.0";

  src = fetchFromGitHub {
    owner = "fabianschuiki";
    repo = "moore";
    rev = "v${version}";
    sha256 = "0ignaa6sfa4jkls0a7yfgjzbv0g81smp42v4fhc512r5hf7c16hw";
  };

  cargoPatches = [ ./cargo-lock.patch ];
  cargoSha256 = "0j5z294wm12m9li7pwfjykf3ha9xnjs3salq3pn7vdj6n4z6p46b";

  dontCargoCheck = true;
}
