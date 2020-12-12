{lib, emacs, writeText, spacemacs, runCommand }:

dotfile:

runCommand "spacemacs-elpa-packages" rec {
  # dotfilePath = builtins.path { path = dotfile; name = "dot_spacemacs"; recursive=false;};
  dotfilePath = writeText "imported-dotfile" (builtins.readFile dotfile);
  elispScript = writeText "make-packages" ''
  (setq debug-on-error t)
  (load "${spacemacs}/core/core-versions.el")
  (load "${spacemacs}/core/core-load-paths.el")
  (load "${dotfilePath}")
  (load "${spacemacs}/core/core-configuration-layer.el")
  (load "${./elisp/nix-spacemacs.el}")
  (dotspacemacs/layers)
  (message "Configured layers: %s" dotspacemacs-configuration-layers)

  (message "Configuration layer dir: %s" configuration-layer-directory)
  (configuration-layer/discover-layers 'refresh-index)
  (configuration-layer//declare-used-layers dotspacemacs-configuration-layers)
  (message "Used layers: %s" configuration-layer--used-layers)
  (configuration-layer//declare-used-packages configuration-layer--used-layers)
  (message "Used packages: %s" configuration-layer--used-packages)
  (setq nix-build-spacemacs-packages configuration-layer--used-packages)
'';
} ''
  export HOME=$TMPDIR/fakehome
  mkdir -p $HOME/.emacs.d/.cache
  ${lib.getBin emacs}/bin/emacs --batch \
    --script "$elispScript" --eval "(nix-spacemacs-generate-expression \"$out\")"
''
