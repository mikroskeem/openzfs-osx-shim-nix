{
  description = "OpenZFS on OSX shim";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in
    (flake-utils.lib.eachSystem supportedSystems
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              self.overlay
            ];
          };
        in
        {
          packages.zfs = if pkgs.stdenv.isDarwin then self.packages.${system}.zfs-mac else pkgs.zfs;
          packages.zfs-mac = pkgs.callPackage ./pkgs/mac-zfs.nix { };
        })) // {
      overlay = final: prev: {
        zfs = if prev.stdenv.isDarwin then prev.callPackage ./pkgs/mac-zfs.nix { } else prev.zfs;
      };
    };
}
