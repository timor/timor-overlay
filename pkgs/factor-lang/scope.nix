{ stdenv, pkgs, lib, gnome2,
overrides ? (self: super: {})}:

let
  inside = (self:
  let callPackage = pkgs.newScope self ;
  in rec {
    recurseForDerivations = true;
    interpreter = callPackage ./default.nix { inherit (gnome2) gtkglext; inherit stdenv; };

    # Convenience access for using the returned attribute the same way as the interpreter derivation
    withLibs = self.interpreter.withLibs;
  });
  extensible-self = lib.makeExtensible (lib.extends overrides inside);
in extensible-self
