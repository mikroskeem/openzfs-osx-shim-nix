{ stdenvNoCC
, zfsPath ? "/usr/local/zfs"
}:

# Implies that https://openzfsonosx.org/ is installed on the system
stdenvNoCC.mkDerivation rec {
  name = "mac-zfs-user";
  phases = [ "installPhase" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    for output in bin include lib libexec share; do
      ln -s "${zfsPath}/$output" $out/$output
    done

    runHook postInstall
  '';
}
