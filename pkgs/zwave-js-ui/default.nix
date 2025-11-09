{ pkgs, writeShellScriptBin, fetchFromGitHub, nodejs, stdenv, lib, ... }:

let

  src =
    pkgs.fetchFromGitHub {
      owner = "zwave-js";
      repo = "zwave-js-ui";
      rev = "v8.6.2";
      sha256 = "9gX757d0ISrF9XGrLaSSt/0t99NVtP/PpkndRObndW0=";
    };
  yarn = writeShellScriptBin "yarn" ''
    exec '${nodejs}/bin/node' '${./yarn-3.2.1.cjs}' "$@"
  '';
  nodePackages = pkgs.callPackage ./node-composition.nix {
    inherit pkgs nodejs;
    inherit (stdenv.hostPlatform) system;
    # inherit src;
  };
  # nodeDeps = nodePackages.nodeDependencies;
  nodeDeps = nodePackages.nodeDependencies.overrideAttrs (oa:
   { buildInputs = oa.buildInputs ++ [ nodejs.pkgs.node-gyp-build ]; }
  );
  # nodePkgs = nodePackages // {
  #   # "zwave-js-ui-fixed" = nodePackages."zwave-js-ui".override {
  #   #   buildInputs = [ nodejs.pkgs.node-gyp-build ];
  #   # };
  #   # "@serialport/bindings-cpp-10.8.0" = nodePackages."@serialport/bindings-cpp-10.8.0".override {
  #   #   buildInputs = [ nodejs.pkgs.node-gyp-build ];
  #   # };
  # };
  buildVars = ''
    # Make Yarn produce friendlier logging for automated builds.
    export CI=1
    # Tell node-pre-gyp to never fetch binaries / always build from source.
    export npm_config_build_from_source=true
  '';
  buildPhase = ''
    # npm-run-all 'build:*'
    npm run build:server
    npm run build:ui
  '';
in

nodePackages.package.override{
  inherit src ;

  nativeBuildInputs = [ nodejs.pkgs.node-gyp-build ];
  preRebuild = buildPhase;
}

# stdenv.mkDerivation {
#   pname = "zwave-js-ui";
#   version = "8.6.2";

#   inherit src;

#   buildInputs = [ nodejs
#                   yarn
#                   # nodejs.pkgs.typescript
#                 ];

#   configurePhase = ''
#     ${buildVars}

#     # Yarn may need a writable home directory.
#     export yarn_global_folder="$TMP"

#     # Some node-gyp calls may call out to npm, which could fail due to an
#     # read-only home dir.
#     export HOME="$TMP"

#     ln -s ${nodeDeps}/lib/node_modules .

#     # yarn install --immutable --immutable-cache

#   '';

#   buildPhase = ''
#    export PATH="${nodeDeps}/bin:$PATH"
#    # yarn run build
#     npm-run-all 'build:*'
#     # npm run 'build:server'
#     # npm run 'build:ui'
#   '';

#   # installPhase = ''
#   #   mkdir -p $out/bin
#   #   # mkdir -p $out
#   #   # cp -R * $out/

#   # '';

# }
