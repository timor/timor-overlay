{ gdb, buildEnv, writeText, lib, runCommand, stdenv }:

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

rec {
  # Input: package, Output: debugified package
  debugify = import ./debugify.nix;
  # Input: debugified packages, Output: env
  gdbForDebugified = (debugPkgs:
    let
      debugFileStore = buildEnv {
        name = "gdb-env-debug-files";
        paths = debugPkgs;
        # This will create problems if actually important files for debugging clash for different packages
        ignoreCollisions = true;
        extraOutputsToInstall = [ "debug" "source" ];
      };
      gdbInit = writeText "gdb-env-init" ''
        directory ${debugFileStore}
        set substitute-path /build ${debugFileStore}
        # set debug-file-directory ${lib.concatMapStringsSep " " (p: "${p.debug}") debugPkgs}
        set debug-file-directory ${debugFileStore}/lib/debug
      '';
      gdbWrapper = runCommand "gdb-for-${(builtins.head debugPkgs).name}" {} ''
        mkdir -p $out/bin
        cat >$out/bin/gdb <<EOF
        #!/bin/sh
        ${lib.getBin gdb}/bin/gdb -ix ${gdbInit} \$@
        EOF
        chmod +x $out/bin/gdb
      '';
      env = buildEnv {
        ignoreCollisions = true ;
        name = "${gdbWrapper.name}-env";
        paths =  debugPkgs ++ [ gdbWrapper ];
        extraOutputsToInstall = [ "debug" "source" ];

      };
    in
      env.overrideAttrs (oldAttrs: {
        passthru = {
          debugPkgs = builtins.listToAttrs (map (p: { name = (builtins.parseDrvName p.name).name; value = p;}));
          env = stdenv.mkDerivation {
            name = "interactive-${gdbWrapper.name}-environment";
            nativeBuildInputs = [ env ];

            buildCommand = ''
              echo >&2 ""
              echo >&2 "*** gdbForPackage envs are meant for interactive use!***"
              echo >&2 ""
              exit 1
            '';
          };
        };
      })
  );
  # Input: packages, Output: env
  gdbForPackages = (pkgs:
    gdbForDebugified (map (p: lib.appendToName "debug" (debugify p)) pkgs)
  );
  # Input: package: Output: env
  gdbForPackage = (pkg: gdbForPackages [pkg]);
}
