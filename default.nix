self: super:

# self: final fixpoint
# super: immediate predecessor pkgs
let
  lib = self.lib;
  callPackage' = super.lib.callPackageWith self;
  callPackage = super.lib.callPackageWith self;
  callPackageIfNewer = (oldPackage: path: args:
    let newPackage = callPackage path args;
      in
    if lib.versionOlder (lib.getVersion oldPackage) (lib.getVersion newPackage) then
    newPackage
    else
    oldPackage
  );
  # Use this to provide package until attribute is present in super
  replaceUnlessProvided = (attribute: newPackage:
    let attrExists = super ? "${attribute}"; in
    if attrExists then
      let existingPackage = super."${attribute}"; in
      abort "Overlay attribute for '${newPackage.name}' may not override existing definition: '${existingPackage.name}'"
    else
      newPackage
  );
  callPackageUnlessProvided = (attribute: path: args: replaceUnlessProvided attribute (callPackage' path args));
in

{
  amidicat = callPackage ./pkgs/amidicat { };

  # bgrep = callPackageUnlessProvided "bgrep" ./pkgs/bgrep { };

  inherit (callPackage ./pkgs/gdbForPackages {})
    debugify
    gdbForDebugified
    gdbForPackages
    gdbForPackage ;

  cataclysm-fresh = let
    myBuild =
    (self.cataclysm-dda-git.override {

      version = "2024-09-19";

      # debug = true;
      debug = false;

    }).overrideDerivation(oa: {
      src = import ./pkgs/cataclysm-fresh/src.nix;
      # src =  lib.cleanSource /home/martin/src/Cataclysm-DDA;
      patches = [
        /home/martin/src/Cataclysm-DDA/gasoline-messkit.patch
        # (self.fetchpatch {
        #   url = "https://patch-diff.githubusercontent.com/raw/CleverRaven/Cataclysm-DDA/pull/75937.patch";
        #   hash = "sha256-96HNA4J7bUlGE8hmbtkfYd71vmhdzG8UFeEacEQLIPE=";
        # })
      ];

      stdenv = self.gcc12Stdenv;
      # makeFlags = oa.makeFlags ++ [ "LTO=1" "SOUND=0" "TESTS=0" "BACKTRACE=1" ];
      # buildInputs = oa.buildInputs ++ [ self.libbacktrace ];

      makeFlags = oa.makeFlags ++ [ "LTO=1" "SOUND=0" "TESTS=0" "LINTJSON=0" ];
      # makeFlags = oa.makeFlags ++ [ "LTO=1" "SOUND=0" "TESTS=0" ];

      # postInstall = ''
      #   wrapProgram $out/bin/cataclysm-tiles --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ myenv.cc.cc.libc ] }"
      # '';
    }); in
    myBuild ;


  # colmap-clang = self.libsForQt5.callPackage ./pkgs/colmap {
  #   stdenv = self.clangStdenv;
  #   inherit (self.llvmPackages) openmp;
  #   };

  # Usage:
  # deployFactor "my-cool-factor-program" /factor/program/sources
  #
  # Output:
  # Derivation whose build product has the following structure:
  # /bin/<my-cool-factor-program> -> /lib/factor/<my-cool-factor-program>/<my-cool-factor-program>
  # /lib/factor/<my-cool-factor-program>/ : Directory (may contain other used resources)
  colmapCudaWrapped = (let colmap = self.colmapWithCuda;
                           cuda = lib.findFirst (d: (d.pname or "INVALID") == "cudatoolkit") null colmap.buildInputs ;
                       in
                       self.wrapBins colmap ''
                        --set CUDA_PATH ${cuda} \
                        --set EXTRA_LDFLAGS "-L${self.linuxPackages.nvidia_x11}/lib"
                       ''
  );

  deployFactor = callPackage ./pkgs/deployFactor { factor-lang = self.factor-lang-live; };
  factor-lang-new = callPackage ./pkgs/factor-lang/scope.nix { stdenv = self.clangStdenv; };

  # FIXME Depends on pdconfig definition at the moment
  factor-lang-live = (self.factor-lang-new.extend (self': super': {interpreter = super'.interpreter.overrideAttrs (oldAttrs:
  rec {
    version = "2021-05-24";
    name = "factor-lang-${version}";
    bootImage = self.fetchurl {
      url = "https://downloads.factorcode.org/images/build/boot.unix-x86.64.image.bfc423e43beeebcb14774054c9685fbded456faf";
      sha256 = "042gwrvk9hvpc49zc3hzscr54kxmd86pykyhp8xjpix5ljknhg7g";
    };

    src = self.fetchFromGitHub {
      owner = "factor";
      repo = "factor";
      rev = "25e5b51689a03cbd7e8b652c9e879a14f5e4326f";
      sha256 = "0sawhjm2n91j1ribp6npyrjflv7756cslc0l2z7qq4ikma7dlc7v";
    };

    # patches = lib.init oldAttrs.patches;
    # patches = [
    #   ./pkgs/factor-lang/staging-command-line-0.98-pre.patch
    #   # ./pkgs/factor-lang/fuel-dir.patch
    # ] ;

    postUnpack = ''
      cp ${bootImage} $sourceRoot/boot.unix-x86.64.image
      chmod 644 $sourceRoot/boot.unix-x86.64.image
    '';});}));

  git-rebase-all = self.runCommand "git-rebase-all" rec {
    src = self.fetchurl {
      url = https://raw.githubusercontent.com/nornagon/git-rebase-all/febe9888a62c6901793353107776c49a42d5fc1e/git-rebase-all ;
      sha256 = "0hlifc1kkk8243jz3igacyj959xwsc4fz9pp5lbpakzflmbw9yw4";
    };
  } ''
    mkdir -p $out/bin
    cp  $src $out/bin/git-rebase-all
    chmod +x $out/bin/git-rebase-all
    patchShebangs $out/bin/git-rebase-all
    '';

  libsslkeylog = callPackage ./pkgs/libsslkeylog { };

  sniffedFirefox = self.runCommand self.firefox.name { nativeBuildInputs = [ self.makeWrapper ];} ''
    mkdir -p $out
    ln -s ${self.firefox}/share $out
    makeWrapper ${lib.getBin self.firefox}/bin/firefox $out/bin/firefox \
      --set SSLKEYLOGFILE /tmp/.sslkeylog \
      --set LD_PRELOAD ${self.libsslkeylog}/lib/libsslkeylog.so
  '';

  libspnav-with-examples = super.libspnav.overrideAttrs (oa: {
    buildInputs = oa.buildInputs ++ [ self.libGL self.libGLU ];
    postBuild = ''
      (
      cd examples/cube
      make
      )
    '';
    postInstall = ''
      mkdir -p $out/bin
      cp examples/cube/cube $out/bin/cube
    '';
  });

  spoof_vendorid = callPackage ./pkgs/spoof_vendorid { };

  wine-wrap-spoofed = callPackage ./pkgs/spoof_vendorid/wrapper.nix { };

  wine-spoofed = self.wine-wrap-spoofed self.wine ;

  gatotray = callPackage ./pkgs/gatotray {};

  gmime_patched = super.gmime3.overrideAttrs(oa: {
    patches = (oa.patches or []) ++ [ ./patches/0001-Normalize-x-variants-for-comparing-protocol-and-mime.patch ];
    doCheck = true;
  });

  hachoir = callPackage ./pkgs/hachoir {};

  kerneldocs = callPackage ./pkgs/kerneldocs {};

  lsb-shell = callPackage ./pkgs/lsb-shell {};

  circt = callPackage ./pkgs/circt {};

  llhd = callPackage ./pkgs/llhd {};

  llvm-mlir = callPackage ./pkgs/llvm-mlir {};

  moore = callPackage ./pkgs/moore {};

  notify-send-all = callPackage ./pkgs/notify-send-all {};

  notmuch = (super.notmuch.overrideAttrs (oa: {
    meta = oa.meta // { outputsToInstall = [ "out" "man" "emacs"]; };
  })).override{ gmime3 = self.gmime_patched; };

  esp32 = callPackage ./pkgs/esp32 { };

  freecad-live = super.freecad.overrideAttrs (oa: {
    src = self.fetchurl {
      url = "https://github.com/FreeCAD/FreeCAD-Bundle/releases/download/weekly-builds/freecad_source.tar.gz";
      sha256 = "sha256-OX4s9rbGsAhH7tLJkUJYyq3A2vCdkq/73iqYo9adogs=";
    };
    # src = self.fetchFromGitHub {
    #   owner = "FreeCAD";
    #   repo = "FreeCAD";
    #   rev = finalAttrs.version;
    #   hash = "sha256-OX4s9rbGsAhH7tLJkUJYyq2A2vCdkq/73iqYo9adogs=";
    # }
  });

  mfcl8650cdwlpr = callPackage ./pkgs/mfcl8650cdwlpr { };
  mfcl8650cdwcupswrapper = callPackage ./pkgs/mfcl8650cdwcupswrapper {};

  exwm-ns = callPackage ./pkgs/exwm-ns { };

  frame3dd = self.libsForQt5.callPackage ./pkgs/frame3dd {};

  nux = callPackage ./pkgs/nux {};

  ocrfeeder = callPackage ./pkgs/ocrfeeder { automake = self.automake111x; };

  inherit (callPackage ./pkgs/opensnitch {})
    opensnitchd opensnitch-ui;

  raygui = callPackage ./pkgs/raygui { };

  shader-slang = callPackage ./pkgs/shader-slang { };

  spacemacsPackages = callPackage ./pkgs/spacemacs/spacemacs-packages.nix
    { emacsPackages = self.emacs29.pkgs; };

  spacemacs = callPackage ./pkgs/spacemacs/default.nix { emacsPackages = self.spacemacsPackages; };

  spacemacs-default =
    self.spacemacs.override {
      dotfile = "${self.spacemacs}/core/templates/.spacemacs.template";
    } ;

  typemaster = callPackage ./pkgs/typemaster { };

  totala = callPackage ./pkgs/totala { };

  wine = self.wineWowPackages.full ;

  wrapBins = callPackage ./pkgs/wrapBin { };

  wrapWine = callPackage ./pkgs/wrapWine { };

  zfs-linux-tools = callPackage ./pkgs/zfs-linux-tools { python=self.python3; };

  node-zwave-js = callPackage ./pkgs/zwave-js { nodejs=self."nodejs-18_x"; };
}
