{
  inputs.nixpkgs = {
    type = "indirect";
    id = "nixpkgs";
  };

  outputs = {nixpkgs, ...}: rec {
    overlay = import ./default.nix;

    legacyPackages."x86_64-linux" = import nixpkgs { system = "x86_64-linux"; overlays = [ overlay ]; config.allowUnfree = true; };
  };
  # outputs = { self, nixpkgs, ... }: let
  #   forAllSystems = f: nixpkgs.lib.genAttrs [ "x86_64-linux" ] (system: f {
  #     inherit system;
  #     pkgs = import nixpkgs {
  #       inherit system;
  #       overlays = [ self.overlay ];
  #     };
  #   });
  # in {
  #   overlay = final: prev: (import ./default.nix) final prev;
  #   legacyPackages = forAllSystems ({ pkgs, ... }: pkgs);
  # };
}
