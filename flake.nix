{
  outputs = { self, nixpkgs, ... }: let
    forAllSystems = f: nixpkgs.lib.genAttrs [ "x86_64-linux" ] (system: f {
      inherit system;
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      };
    });
  in {
    overlay = final: prev: (import ./default.nix) final prev;
    legacyPackages = forAllSystems ({ pkgs, ... }: pkgs);
  };
}
