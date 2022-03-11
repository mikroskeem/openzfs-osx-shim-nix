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
        "x86_64-darwin"
      ];
    in
    (flake-utils.lib.eachSystem supportedSystems
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        rec {
          packages.zfs-mac = pkgs.callPackage ./pkgs/mac-zfs.nix { };
        })) // {
      overlay = final: prev: {
        zfs = prev.callPackage ./pkgs/mac-zfs.nix { };
      };
    };
}
