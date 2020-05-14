let
    saveSource = ''
      savedSource="$(mktemp -d)"
      echo debugify: saving source from $NIX_BUILD_TOP/$sourceRoot to $savedSource
      cp -r $NIX_BUILD_TOP/$sourceRoot $savedSource/
      '';
    installSource = ''
      echo debugify: moving saved source to store
      if [ -z "$savedSource" ]; then
        echo debugify: unable to find saved source; exit 1
      fi
      mkdir -p $source
      echo mv $savedSource/* $source/
      mv $savedSource/* $source/
      '';
     removeGenericDebugFiles = ''
       echo debugify: removing possible artifacts in $source
       rm -rf $source/source/build/CMakeFiles
       echo debugify: removing possible artifacts in $out
       rm -f $out/lib/debug/a.out
       rm -f $out/lib/debug/CMake*.bin
       echo debugify: removing possible artifacts in $debug
       rm -f $debug/lib/debug/a.out
       rm -f $debug/lib/debug/CMake*.bin
     '';
  in
    (pkg: pkg.overrideAttrs (oldAttrs:
      {
        separateDebugInfo = true;
        outputs = (oldAttrs.outputs or [ "out" ]) ++ [ "source" ];
        hardeningDisable = (oldAttrs.hardeningDisable or []) ++ [ "fortify" ];
      } // (
        if (oldAttrs ? buildPhase) then {
          buildPhase = saveSource + oldAttrs.buildPhase;
        } else {
          preBuild = (oldAttrs.preBuild or "") + saveSource;
        }) // (
        if (oldAttrs ? installPhase) then {
          installPhase = installSource + oldAttrs.installPhase;
        } else {
          preInstall = installSource + (oldAttrs.preInstall or "");
        })
        # // (
        #   if (oldAttrs ? fixupPhase) then {
        #     fixupPhase = oldAttrs.fixupPhase + removeGenericDebugFiles;
        #   } else {
        #     postFixup = (oldAttrs.postFixup or "") + removeGenericDebugFiles;
        #   })
    ))
