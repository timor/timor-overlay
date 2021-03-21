{ lib, stdenv, pkgs, python3Packages, fetchFromGitHub, libnetfilter_queue
, libnfnetlink, libpcap, protobuf, buildGoPackage, pkg-config
, qt5, makeDesktopItem
}:

let
  version = "1.0.1";
  src = fetchFromGitHub {
    owner = "gustavo-iniguez-goya";
    repo = "opensnitch";
    rev = "v${version}";
    sha256 = "03xlzj2mwh5vckvi0fq33x60p9g28aplilk8r44q65ia88g1dwkf";
  };
  unicode-slugify = python3Packages.buildPythonPackage {
    name = "unicode-slugify-0.1.3";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/8c/ba/1a05f61c7fd72df85ae4dc1c7967a3e5a4b6c61f016e794bc7f09b2597c0/unicode-slugify-0.1.3.tar.gz";
      sha256 = "34cf3afefa6480efe705a4fc0eaeeaf7f49754aec322ba3e8b2f27dc1cbcf650"; };
      doCheck = false;
      propagatedBuildInputs = with python3Packages; [
        six unidecode
      ];
      meta = with lib; {
        homepage = "http://github.com/mozilla/unicode-slugify";
        license = licenses.bsdOriginal;
        description = "A slug generator that turns strings into unicode slugs.";
      };
  };
  meta = {
    description = "GNU/Linux port of the Little Snitch application firewall";
    license = lib.licenses.gpl3;
    homepage = "https://github.com/evilsocket/opensnitch";
    platforms = lib.platforms.unix;
  };
  desktopItem = makeDesktopItem {
    name = "OpenSnitch";
    exec = "opensnitch-ui";
    desktopName = "OpenSnitch";
    icon = "preferences-system-firewall";
    genericName = "OpenSnitch Firewall";
    categories = "System;Filesystem;Network;";
  };
in

{
  opensnitchd = buildGoPackage rec {
    pname = "opensnitch-daemon";
    inherit src version meta;
    goPackagePath = "github.com/gustavo-iniguez-goya/opensnitch";
    subPackages = [ "./daemon" ];
    goDeps = ./deps.nix;
    buildInputs = [ pkg-config libnetfilter_queue libnfnetlink libpcap protobuf ];
    postInstall = "mv $bin/bin/daemon $bin/bin/opensnitchd";
  };

  opensnitch-ui = python3Packages.buildPythonApplication rec {
    pname = "opensnitch-ui";
    inherit src version meta;
    sourceRoot = "source/ui";
    dontWrapPythonPrograms = true;
    nativeBuildInputs = [ qt5.wrapQtAppsHook stdenv python3Packages.pyqt5 ];
    preBuild = ''
      pyrcc5 -o opensnitch/resources_rc.py opensnitch/res/resources.qrc
    '';
    propagatedBuildInputs = with python3Packages; [
      grpcio
      grpcio-tools
      pyinotify
      pyqt5
      unicode-slugify
    ] ;
    doCheck = false;
    postInstall = ''
      ${desktopItem.buildCommand}
      for program in $out/bin/*; do
      wrapQtApp $program --prefix PYTHONPATH : $PYTHONPATH
      done
    '';
  };
}
