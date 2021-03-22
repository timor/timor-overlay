{ lib, stdenv, cmake, verilator, llvmPackages_11, fetchFromGitHub }:

let
  mlir = llvmPackages_11.mlir;
  llvm = llvmPackages_11.llvm;

in
stdenv.mkDerivation rec {
  pname = "circt";
  version = "2021-03-22";

  src = fetchFromGitHub {
    owner = "llvm";
    repo = "circt";
    rev = "72162617f62fff5ff12372fc94f81f8aa71b5af6";
    sha256 = "0j3v84i1v89l43ggqqk6lifcis7g6dv2bsybqmnbckniy2a0xb6l";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ llvm mlir verilator ];

}
