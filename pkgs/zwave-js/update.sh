#!/usr/bin/env sh

node2nix -14 -i node-packages.json -c node-composition.nix --include-peer-dependencies
