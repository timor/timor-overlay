#!/usr/bin/env bash

srcs=./auctex-srcs.nix
echo "{" > $srcs
for v in $(cat ./auctex-versions); do
    url="https://elpa.gnu.org/packages/auctex-$v.tar.lz"
    cat >> $srcs <<EOF
    "$v" = {
    url = "$url";
    sha256 = "$(nix-prefetch-url $url)";
    };
EOF
    done
echo "}" >> $srcs
