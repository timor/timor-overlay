{ runCommand, makeWrapper, lib, factor-lang}:

{name, source, extraPath}:
let
  deployedVocab = runCommand "${name}-vocab" {
    factorCmd = "${factor-lang.interpreter}/bin/factor " + ./deploy-me.factor;
    SRC = source;
    NAME = name;
  } ''
    echo "script source: '$SRC'"
    echo "script name: '$NAME'"

    mkdir -p $out/lib/factor "$NAME" tmp-cache
    export XDG_CACHE_HOME=$PWD/tmp-cache

    cp -r $SRC/* "$NAME"
    $factorCmd ./"$NAME" $out/lib/factor
  '';

in

runCommand name {
  nativeBuildInputs = [ makeWrapper ];
  passthru = {
    inherit deployedVocab;
  };
} ''

  mkdir -p $out/bin

  makeWrapper "${deployedVocab}/lib/factor/${name}/${name}" "$out/bin/${name}" --prefix PATH : ${lib.makeBinPath extraPath}
''
