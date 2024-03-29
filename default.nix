let
  # Read in the Niv sources
  sources = import ./nix/sources.nix {};
  # If ./nix/sources.nix file is not found run:
  #   niv init
  #   niv add input-output-hk/haskell.nix -n haskellNix

  # Fetch the haskell.nix commit we have pinned with Niv
  haskellNix = import sources.haskellNix {};
  # If haskellNix is not found run:
  #   niv add input-output-hk/haskell.nix -n haskellNix

  iohkNix = import sources.iohkNix {};

  # Import nixpkgs and pass the haskell.nix provided nixpkgsArgs
  pkgs = import
    # haskell.nix provides access to the nixpkgs pins which are used by our CI,
    # hence you will be more likely to get cache hits when using these.
    # But you can also just use your own, e.g. '<nixpkgs>'.
    haskellNix.sources.nixpkgs-unstable
    # These arguments passed to nixpkgs, include some patches and also
    # the haskell.nix functionality itself as an overlay.
    {
      overlays = haskellNix.nixpkgsArgs.overlays ++ iohkNix.overlays.crypto;
      config = haskellNix.nixpkgsArgs.config;
    };
in pkgs.haskell-nix.project {
  # 'cleanGit' cleans a source directory based on the files known by git
  src = pkgs.haskell-nix.haskellLib.cleanGit {
    name = "quickcheck-contractmodel";
    src = ./.;
  };
  # Specify the GHC version to use.
  compiler-nix-name = "ghc8107"; # Not required for `stack.yaml` based projects.

  modules = [
    ({ pkgs, ... }: {
      packages.cardano-crypto-class.components.library.pkgconfig = 
        pkgs.lib.mkForce [ [ pkgs.libsodium-vrf pkgs.secp256k1 ] ];
      packages.cardano-crypto-praos.components.library.pkgconfig = 
        pkgs.lib.mkForce [ [ pkgs.libsodium-vrf ] ];
    })
  ];
}
