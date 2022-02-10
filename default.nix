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
  auctexSrcs = import ./auctex-srcs.nix;
  auctexFun = esuper:
    let version = esuper.auctex.version; in
    if isNull(auctexSrcs.${version} or null) then
      esuper.auctex
    else
      let tarName = "auctex-${version}.tar"; in
      esuper.elpaBuild rec {
        inherit (esuper.auctex) ename pname version meta;
        lzipsrc = self.fetchurl auctexSrcs.${version} ;
        tarsrc = self.runCommand tarName {
           nativeBuildInputs = [self.lzip];} ''
             mkdir -p $out
             cp ${lzipsrc} $out/${tarName}.lz
             lzip -d $out/${tarName}.lz
           '';
         src="${tarsrc}/${tarName}";
      };
in

{
  amidicat = callPackage ./pkgs/amidicat { };

  # bgrep = callPackageUnlessProvided "bgrep" ./pkgs/bgrep { };

  inherit (callPackage ./pkgs/gdbForPackages {})
    debugify
    gdbForDebugified
    gdbForPackages
    gdbForPackage ;

  # colmap-clang = self.libsForQt5.callPackage ./pkgs/colmap {
  #   stdenv = self.clangStdenv;
  #   inherit (self.llvmPackages) openmp;
  #   };

  emacs27Packages = super.emacs27Packages.overrideScope' (eself: esuper:
    { auctex = auctexFun esuper; }
  );

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
    version = "0.99-pre6";
    name = "factor-lang-${version}";
    bootImage = self.fetchurl {
      url = "https://downloads.factorcode.org/images/build/boot.unix-x86.64.image.e511080c91c884c117edc585e61a9979e11731a8";
      sha256 = "043nrf2m3bcs6hhc4knnhkjqwy9g3l1x9bygfqpdn6j6kmpbjxzm";
    };

    src = self.fetchFromGitHub {
      owner = "factor";
      repo = "factor";
      rev = "6996415cd0e0ba3c4a081b561015bd3c4349013b";
      sha256 = "1gc99rsa0dzy44lrp3jwbcb5g139zw2rbz39ralxa37dfi43phhc";
    };

    # patches = lib.init oldAttrs.patches;
    patches = [
      ./pkgs/factor-lang/staging-command-line-0.98-pre.patch
      # ./pkgs/factor-lang/fuel-dir.patch
    ] ;

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

  spnav = callPackage ./pkgs/spnav { };

  spacenavd = callPackage ./pkgs/spacenavd { };

  spnavcfg = callPackage ./pkgs/spnavcfg { };

  spoof_vendorid = callPackage ./pkgs/spoof_vendorid { };

  solvespace = super.solvespace.overrideAttrs (oa: {buildInputs = oa.buildInputs ++ [ self.spnav ];});

  wine-wrap-spoofed = callPackage ./pkgs/spoof_vendorid/wrapper.nix { };

  wine-spoofed = self.wine-wrap-spoofed self.wine ;

  freecad = (super.freecad.overrideAttrs (oldAttrs: {
      buildInputs = oldAttrs.buildInputs ++ [ self.spnav ];
  }));

  gatotray = callPackage ./pkgs/gatotray {};

  gmime_patched = self.gmime3.overrideAttrs(oa: {
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

  notmuch = (super.notmuch.overrideAttrs (oa: {
    #patches = (oa.patches or []) ++ [ ./patches/0001-Display-application-pkcs7-mime-parts-smime-decryptio.patch ];
  })).override{ gmime = self.gmime_patched; };

  open-zwave = callPackage ./pkgs/open-zwave {};

  esp32 = callPackage ./pkgs/esp32 { };

  makemkv = self.libsForQt5.callPackage ./pkgs/makemkv { };

  mfcl8650cdwlpr = callPackage ./pkgs/mfcl8650cdwlpr { };
  mfcl8650cdwcupswrapper = callPackage ./pkgs/mfcl8650cdwcupswrapper {};

  exwm-ns = callPackage ./pkgs/exwm-ns { };

  frame3dd = self.libsForQt5.callPackage ./pkgs/frame3dd {};

  nux = callPackage ./pkgs/nux {};

  ocrfeeder = callPackage ./pkgs/ocrfeeder { automake = self.automake111x; };

  inherit (callPackage ./pkgs/opensnitch {})
    opensnitchd opensnitch-ui;

#  plasma5 = super.plasma5 // {
#    plasma-workspace = super.plasma5.plasma-workspace.overrideAttrs (oldAttrs: {
#      patches = oldAttrs.patches ++ [ ./patches/plasma-lockscreen-suspend-20.03.patch ];
#    });
#  };

  raygui = callPackage ./pkgs/raygui { };

  shader-slang = callPackage ./pkgs/shader-slang { };

  spacemacsPackages = callPackage ./pkgs/spacemacs/spacemacs-packages.nix
    { emacsPackages = self.emacs27Packages; };

  spacemacs = callPackage ./pkgs/spacemacs/default.nix { emacsPackages = self.spacemacsPackages; };

  spacemacs-default =
    self.spacemacs.override {
      dotfile = "${self.spacemacs}/core/templates/.spacemacs.template";
    } ;

  typemaster = callPackage ./pkgs/typemaster { };

  totala = callPackage ./pkgs/totala { };

  wine = self.wineWowPackages.full ;

  wrapBins = callPackage ./pkgs/wrapBin { };

  zfs-linux-tools = callPackage ./pkgs/zfs-linux-tools { };
}
