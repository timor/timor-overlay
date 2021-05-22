{ makeWrapper, runCommand, lib }:

pkg: wrapperString:

runCommand "${pkg.name}-binwrap" {buildInputs = [makeWrapper];} ''
mkdir -p $out/bin
for f in ${lib.getBin pkg}/bin/*; do
makeWrapper "$f" "$out/bin/$(basename $f)" ${wrapperString}
done
''
