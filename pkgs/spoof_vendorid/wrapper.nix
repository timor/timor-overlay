{ lib, runCommand, makeWrapper, spoof_vendorid }:

wine: runCommand "wine-spoofed" {
  nativeBuildInputs = [makeWrapper];
} ''
mkdir -p $out/bin
makeWrapper ${lib.getBin wine}/bin/wine $out/bin/wine-spoofed \
  --set VK_INSTANCE_LAYERS VK_LAYER_LUNARG_vendorid_layer \
  --set VK_LAYER_PATH ${spoof_vendorid}/share/spoof_vendorid/
''
