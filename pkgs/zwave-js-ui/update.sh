#!/usr/bin/env sh

node2nix -14 -i package.json -c node-composition.nix --supplement-input supplement.json
