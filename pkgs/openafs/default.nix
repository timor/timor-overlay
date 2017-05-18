{ stdenv, fetchurl, fetchgit, which, autoconf, automake, flex, yacc
, kernel, glibc, ncurses, perl, kerberos }:

stdenv.mkDerivation rec {
  name = "openafs-${version}-${kernel.version}";
  version = "1.6.20.1";

  src = fetchurl {
    url = "http://www.openafs.org/dl/openafs/${version}/openafs-${version}-src.tar.bz2";
    sha256 = "09l8iajh4sl3cigs64jhxj89pvqqf7wfl890vp9lj6f8yvn9x1nw";
  };

  nativeBuildInputs = [ autoconf automake flex yacc perl which ];

  buildInputs = [ ncurses ];

  hardeningDisable = [ "pic" ];

  preConfigure = ''
    ln -s "${kernel.dev}/lib/modules/"*/build $TMP/linux

    patchShebangs .
    for i in `grep -l -R '/usr/\(include\|src\)' .`; do
      echo "Patch /usr/include and /usr/src in $i"
      substituteInPlace $i \
        --replace "/usr/include" "${glibc.dev}/include" \
        --replace "/usr/src" "$TMP"
    done

    ./regen.sh

    ${stdenv.lib.optionalString (kerberos != null)
      "export KRB5_CONFIG=${kerberos}/bin/krb5-config"}

    configureFlagsArray=(
      "--with-linux-kernel-build=$TMP/linux"
      ${stdenv.lib.optionalString (kerberos != null) "--with-krb5"}
      "--sysconfdir=/etc"
      "--localstatedir=/var"
      "--disable-linux-d_splice-alias-extra-iput"
    )
  '';

  preFixup = ''
    rm $out/bin/kpasswd
    rm $out/sbin/{kas,kdb,ka-forwarder,kadb_check}
    rm $out/libexec/openafs/kaserver
  '';

  meta = with stdenv.lib; {
    description = "Open AFS client";
    homepage = https://www.openafs.org;
    license = licenses.ipl10;
    platforms = platforms.linux;
    maintainers = [ maintainers.z77z maintainers.spacefrogg ];
    broken =
      (!stdenv.lib.strings.versionOlder "3.18" kernel.version) ||
      (!stdenv.lib.strings.versionOlder kernel.version "4.10") ||
      (kernel.features.grsecurity or false);
  };
}
