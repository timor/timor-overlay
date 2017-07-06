{ stdenv, pkgs, lib, fetchurl, writeTextFile, buildFHSUserEnv, bash }:

let toolchain = stdenv.mkDerivation rec {
  name = "xtensa-esp32-elf-linux64-${version}";
  version = "1.22.0-61-gab8375a-5.2.0";
  src = fetchurl {
    url = "https://dl.espressif.com/dl/xtensa-esp32-elf-linux64-${version}.tar.gz";
    sha256 = "1yfly36pjzp86cgr0pfy2ljwnb1ygjjhqkkwxrgh6bv2gzyk6hxp";
  };

  buildPhase = "true";

  installPhase = ''
  mkdir $out;
  cp -r * $out
  
  '';
  };

in toolchain

# in buildFHSUserEnv {
#     name = "esp32-shell";
#     targetPkgs = pkgs: [ toolchain ];
# }

# in writeTextFile {
#   name = "esp32-shell";
#   destination = "/bin/esp32-shell";
#   executable = "true";
#   text = ''
#     #!${bash}/bin/bash
#     ${env}/bin/esp32-fhs-env 
