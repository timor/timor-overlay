self: super:

# self: final fixpoint
# super: immediate predecessor pkgs
let
  lib = self.lib;
  callPackage = super.lib.callPackageWith self;
  debugify = let
    saveSource = ''
      savedSource="$(mktemp -d)"
      echo debugify: saving source from $NIX_BUILD_TOP/$sourceRoot to $savedSource
      cp -r $NIX_BUILD_TOP/$sourceRoot $savedSource/
      '';
    installSource = ''
      echo debugify: moving saved source to store
      if [ -z "$savedSource" ]; then
        echo debugify: unable to find saved source; exit 1
      fi
      mkdir -p $source
      echo mv $savedSource/* $source/
      mv $savedSource/* $source/
      '';
  in
    (pkg: pkg.overrideAttrs (oldAttrs:
      {
        name = oldAttrs.name +"-debug";
        separateDebugInfo = true;
        outputs = (oldAttrs.outputs or [ "out" ]) ++ [ "source" ];
        hardeningDisable = (oldAttrs.hardeningDisable or []) ++ [ "fortify" ];
      } // (
        if (oldAttrs ? buildPhase) then {
          buildPhase = saveSource + oldAttrs.buildPhase;
        } else {
          preBuild = (oldAttrs.preBuild or "") + saveSource;
        }) // (
        if (oldAttrs ? installPhase) then {
          installPhase = installSource + oldAttrs.installPhase;
        } else {
          preInstall = installSource + (oldAttrs.preInstall or "");
        })));
in

{

  # gdbForPackages: build a set of packages with debug information and source,
  # wrap a gdb that knows about the respective source locations and debug
  # symbols
  #
  # Some Examples:
  # 1. Enter a shell where `gdb glxinfo` and `gdb hello` does what one expects:
  # $ nix-shell -E 'with import <nixpkgs> {}; (gdbForPackages [glxinfo hello ]).env'
  #
  # 2. Install the set of relevant binaries for e.g. glxinfo and the corresponding gdb into user environment:
  # $ nix-build -E 'with import <nixpkgs> {}; (gdbForPackage glxinfo)'
  # $ nix-env -i ./result
  #
  # 3. Build above environment, enter afterwards
  # $ nix-build -E 'with import <nixpkgs> {}; (gdbForPackage glxinfo)'
  # $ nix-shell -p ./result
  gdbForPackages = (pkgs:
    let
    debugPkgs = map debugify pkgs;
    debugFileStore = self.buildEnv {
      name = "gdb-env-debug-files";
      paths = debugPkgs;
      extraOutputsToInstall = [ "debug" "source" ];
    };
    gdbInit = self.writeText "gdb-env-init" ''
      directory ${debugFileStore}
      set substitute-path /build ${debugFileStore}
      # set debug-file-directory ${lib.concatMapStringsSep " " (p: "${p.debug}") debugPkgs}
      set debug-file-directory ${debugFileStore}/lib/debug
      '';
    gdbWrapper = self.runCommand "gdb-for-${(builtins.head debugPkgs).name}" {} ''
      mkdir -p $out/bin
      cat >$out/bin/gdb <<EOF
      #!/bin/sh
      ${self.lib.getBin self.gdb}/bin/gdb -ix ${gdbInit} \$@
      EOF
      chmod +x $out/bin/gdb
      '';
    env = self.buildEnv {
      name = "${gdbWrapper.name}-env";
      paths =  debugPkgs ++ [ gdbWrapper ];
      extraOutputsToInstall = [ "debug" "source" ];
    };
  in env.overrideAttrs (oldAttrs: {passthru = {
      debugPkgs = builtins.listToAttrs (map (p: { name = (builtins.parseDrvName p.name).name; value = p;}));
      env = self.stdenv.mkDerivation {
        name = "interactive-${gdbWrapper.name}-environment";
        nativeBuildInputs = [ env ];

        buildCommand = ''
          echo >&2 ""
          echo >&2 "*** gdbForPackage envs are meant for interactive use!***"
          echo >&2 ""
          exit 1
        '';
      };};}));
  gdbForPackage = (pkg: self.gdbForPackages [pkg]);

  colmap-clang = self.libsForQt5.callPackage ./pkgs/colmap {
    stdenv = self.clangStdenv;
    inherit (self.llvmPackages) openmp;
    };

  colmap = self.libsForQt5.callPackage ./pkgs/colmap { };

  # Usage:
  # deployFactor "my-cool-factor-program" /factor/program/sources
  #
  # Output:
  # Derivation whose build product has the following structure:
  # /bin/<my-cool-factor-program> -> /lib/factor/<my-cool-factor-program>/<my-cool-factor-program>
  # /lib/factor/<my-cool-factor-program>/ : Directory (may contain other used resources)
  deployFactor = scriptName: scriptSource: super.runCommand scriptName {
    factorCmd = "${self.factor-lang}/bin/factor " + ./pkgs/deployFactor/deploy-me.factor;
    SRC = scriptSource;
    NAME = scriptName;
  } ''
    mkdir -p $out/bin "$NAME" tmp-cache
    export XDG_CACHE_HOME=$PWD/tmp-cache

    cp -r $SRC/* "$NAME"
    $factorCmd ./"$NAME" $out/lib/factor
    ln -sf $out/lib/factor/"$NAME"/"$NAME" $out/bin/"$NAME"
  '';

  factor-lang = callPackage ./pkgs/factor-lang {
    inherit (self.gnome2) gtkglext;
  };

  spnav = callPackage ./pkgs/spnav { };

  spacenavd = callPackage ./pkgs/spacenavd { };

  freecad = (super.freecad.overrideAttrs (oldAttrs: {
      buildInputs = oldAttrs.buildInputs ++ [ self.spnav ];
  }));

  open-zwave = callPackage ./pkgs/open-zwave {};
  workcraft = callPackage ./pkgs/workcraft {};

  unp = callPackage ./pkgs/unp { };

  esp32 = callPackage ./pkgs/esp32 { };

  mfcl8650cdwlpr = callPackage ./pkgs/mfcl8650cdwlpr { };
  mfcl8650cdwcupswrapper = callPackage ./pkgs/mfcl8650cdwcupswrapper {};

  # vlc = super.vlc.overrideAttrs(oldAttrs: {
  #   buildInputs = oldAttrs.buildInputs ++ [ self.libnotify self.gtk2 ];
  #   configureFlags = oldAttrs.configureFlags ++ [ "--enable-notify" ];
  # });

  exwm-ns = callPackage ./pkgs/exwm-ns { };

  # slic3r = super.slic3r.overrideAttrs(oldAttrs: {
  #   buildPhase = ''
  #     export LD=g++
  #   '' +
  #   oldAttrs.buildPhase;
  #   patches = [
  #     (self.fetchpatch {
  #       name = "fix-deserialize-return-values";
  #       url = "https://github.com/alexrj/Slic3r/commit/6e5938c8330b5bdb6b85c3ca8dc188605ee56b98.diff";
	#       sha256 = "1m125lajsm2yhacwvb3yxsz63jy9k2zzfaprnc4nkfcz0hs5vbpq";
	# })];
  # });
  slic3r = callPackage ./pkgs/slic3r {};

  emacs-spacemacs = self.emacs.overrideAttrs(oldAttrs: rec {
    patches = oldAttrs.patches ++ [ ./patches/spacemacs.d.patch ];
    versionModifier = "spacemacs";
    name = "emacs-${oldAttrs.version}-${versionModifier}";
  });

  spacemacs =
    (self.writeScriptBin "spacemacs" ''
     #!/bin/sh
     dir=~/.spacemacs.d.d
     if [ ! -d "$dir" ]; then
	      ${self.git}/bin/git clone -b develop https://github.com/syl20bnr/spacemacs.git "$dir"
        ${self.git}/bin/git clone https://github.com/timor/spacemacsOS "$dir/private/exwm"
     fi
     ${self.emacs-spacemacs}/bin/emacs $@
     '');

  perlPackages = super.perlPackages // (with super.perlPackages;{
    ExtUtilsCppGuess = buildPerlModule rec {
    name = "ExtUtils-CppGuess-0.07";
    src = self.fetchurl {
      url = "mirror://cpan/modules/by-module/ExtUtils/${name}.tar.gz";
      sha256 = "1a77hxf2pa8ia9na72rijv1yhpn2bjrdsybwk2dj2l938pl3xn0w";
    };
    propagatedBuildInputs = [ CaptureTiny ];
    perlPreHook = "unset LD";
  };});

  # notmuch = super.notmuch.overrideAttrs (oldAttrs: rec {
  #   version = "0.24.2";
  #   name = "notmuch-${version}";
  #   src = self.fetchurl {
  #     url = "http://notmuchmail.org/releases/${name}.tar.gz";
  #     sha256 = "0lfchvapk11qazdgsxj42igp9mpp83zbd0h1jj6r3ifmhikajxma";
  #   };
  #   doCheck = false;
  # });
  notmuch = callPackage ./pkgs/notmuch { };

  # pijul = callPackage ./pkgs/pijul { }; will only work once rust stuff has been sorted out

  xcircuit = callPackage ./pkgs/xcircuit { };

  zotero = callPackage ./pkgs/zotero { };
}
