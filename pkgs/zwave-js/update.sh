#!/usr/bin/env sh

node2nix -18 -i node-packages.json -c node-composition.nix --include-peer-dependencies
