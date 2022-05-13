{ stdenvNoCC
, zfsPath ? "/usr/local/zfs"
, lib
, fetchurl
, libarchive
, libtapi
, xar
}:

stdenvNoCC.mkDerivation {
  pname = "mac-zfs-user";
  version = "2.1.0";

  src = let
    system = stdenvNoCC.targetPlatform.system;
    srcs = {
      aarch64-darwin = {
        url = "https://openzfsonosx.org/forum/download/file.php?id=342&sid=49c5a58d40e3e984c4d15d0f281ed5e0";
        name = "OpenZFSonOsX-2.1.0-Big.Sur-11-arm64.pkg";
        sha256 = "sha256-ry+rlBAkNMvIovKJ0XfUpNlKlHGhHyEp+1QWCBq0euc=";
      };
      x86_64-darwin = {
        url = "https://openzfsonosx.org/forum/download/file.php?id=343&sid=49c5a58d40e3e984c4d15d0f281ed5e0";
        name = "OpenZFSonOsX-2.1.0-Big.Sur-11.pkg";
        sha256 = "sha256-LMDC2jO+POMx6SK6LKfFhReeefGt3HIkbxDflbfXuNc=";
      };
    };
  in fetchurl srcs.${system} or (throw "Unsupported system ${system}");

  nativeBuildInputs = [
    libarchive # for bsdtar
    libtapi
    xar
  ];

  sourceRoot = ".";
  outputs = [ "out" "dev" ];

  unpackPhase = ''
    runHook preUnpack

    mkdir _tmp
    _root="$PWD"
    pushd _tmp >/dev/null
    xar -xf $src

    bsdtar -C "$_root" -xzf my_package.pkg/Payload
    popd >/dev/null
    rm -rf _tmp

    runHook postUnpack
  '';

  buildPhase = ''
    runHook preBuild

    mkdir -p $out/bin
    mkdir -p $dev/include
    mkdir -p $dev/lib/pkgconfig

    # Stub libraries
    pushd usr/local/zfs/lib >/dev/null
    for f in *.dylib; do
      if [ -L "$f" ]; then
        target="$(readlink -- "$f")"
        ln -s "''${target%%.dylib}.tbd"  "$dev/lib/''${f%%.dylib}.tbd"
      else
        tapi stubify --filetype=tbd-v2  "$f" -o "$dev/lib/''${f%%.dylib}.tbd"
      fi
    done
    popd >/dev/null

    # Remove OpenSSL references
    rm $dev/lib/libcrypto*
    rm $dev/lib/libssl*

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Link binaries
    pushd usr/local/zfs/bin >/dev/null
    for f in *; do
      ln -s ${zfsPath}/bin/$f $out/bin/$f
    done
    popd >/dev/null

    # Copy headers & pkg-config files
    cp -r usr/local/zfs/include/* $dev/include/
    cp usr/local/zfs/lib/pkgconfig/*.pc $dev/lib/pkgconfig
    sed -i "s|^prefix=.*|prefix=$dev|" $dev/lib/pkgconfig/*.pc

    runHook postInstall
  '';

  dontStrip = true;

  passthru.warning = ''
    OpenZFS On OS X is required for this package to work on macOS. To install OpenZFS On OS X,
    use the installer from the <link xlink:href="https://openzfsonosx.org/wiki/Downloads">
    project website</link>.
  '';

  meta = with lib; {
    platforms = platforms.darwin;
  };
}
