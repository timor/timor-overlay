{ lib, stdenv, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "llhd";
  version = "0.15";

  src = fetchFromGitHub {
    owner = "fabianschuiki";
    repo = "llhd";
    rev = "v${version}";
    sha256 = "14w3cm9mqwp767614f5ph5vz9azdbymsw7bfrfjpr2cc4nm6azws";
  };

  cargoPatches = [ ./cargo-lock.patch ];
  cargoSha256 = "1vvagzijkrdq205k1ixn9c6a4b9yb3ykjr235h21qkx50qqzv723";
  # cargoSha256 = "17ldqr3asrdcsh4l29m3b5r37r5d0b3npq1lrgjmxb6vlx6a35qh";

  doCheck = false;
  dontCargoCheck = true;
}
