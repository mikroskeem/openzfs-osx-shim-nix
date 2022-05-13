{ stdenvNoCC
, libtapi
, zfsPath ? "/usr/local/zfs"
}:

# Implies that https://openzfsonosx.org/ is installed on the system
stdenvNoCC.mkDerivation rec {
  name = "mac-zfs-user";

  nativeBuildInputs = [
    libtapi
  ];

  phases = [ "installPhase" ];
  outputs = [ "out" "dev" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    for output in bin include lib libexec share; do
      ln -s "${zfsPath}/$output" $out/$output
    done

    mkdir -p $dev/lib/pkgconfig
    ln -s "${zfsPath}/include" $dev/include
    pushd "${zfsPath}/lib" >/dev/null
    for f in *.dylib; do
      if [ -L "$f" ]; then
        target="$(readlink -- "$f")"
        ln -s "''${target%%.dylib}.tbd"  "$dev/lib/''${f%%.dylib}.tbd"
      else
        tapi stubify --filetype=tbd-v2  "$f" -o "$dev/lib/''${f%%.dylib}.tbd"
      fi
    done
    cp ${zfsPath}/lib/pkgconfig/*.pc $dev/lib/pkgconfig
    sed -i "s|^prefix=.*|prefix=$dev|" $dev/lib/pkgconfig/*.pc
    popd >/dev/null

    runHook postInstall
  '';
}
