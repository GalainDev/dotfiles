{
  # A flake is the entry point of a Nix project: it declares inputs (pinned
  # dependencies, locked in flake.lock) and outputs (what this repo can build).
  # Ours outputs exactly one thing: a complete macOS system configuration.
  description = "heman's dotfiles";

  inputs = {
    # The package collection everything else draws from.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    # nix-darwin: manages macOS itself (system defaults, Homebrew, etc.)
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # home-manager: manages the user layer (dotfile symlinks, packages, env).
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # nix-homebrew: lets nix-darwin drive Homebrew declaratively.
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nix-homebrew, home-manager, nixpkgs }:
    let
      user = "heman";
    in
    {
      # `sudo darwin-rebuild switch --flake ~/.dotfiles#mac` builds THIS.
      darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit user; };
        modules = [
          ./configuration.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit user; };
            home-manager.users.${user} = import ./home.nix;
            # If home-manager wants to place a file where a real (unmanaged)
            # file already exists, it backs the old one up with this suffix
            # instead of failing the build.
            home-manager.backupFileExtension = "before-nix";
          }
        ];
      };
    };
}
