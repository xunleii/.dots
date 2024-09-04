{
  description = "Radiofrance - NixOS (WSL)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # NixOS WSL dedicated configurations
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    # Elythh Neovim configurations
    nixvim.url = "github:elythh/nixvim";
  };

  outputs = { self, nixpkgs, nixos-wsl, nixvim, ... }: {
    nixosConfigurations =
      let
        system = "x86_64-linux";
        pkgs = import nixpkgs { inherit system; };
      in
      {
        nixos = nixpkgs.lib.nixosSystem rec {
          inherit system;
          modules = [
            nixos-wsl.nixosModules.default
            {
              environment.systemPackages = [
                pkgs.wget
                nixvim.packages.${system}.default
              ];
              nix.settings.experimental-features = [
                "nix-command"
                "flakes"
              ];
              system.stateVersion = "24.05";
              wsl.enable = true;
              programs.nix-ld = {
                enable = true;
                package = pkgs.nix-ld-rs;
              };
              programs.nh = {
                enable = true;
                clean.enable = true;
                clean.extraArgs = "--keep-since 4d --keep 3";
                flake = "/home/nixos";
              };
            }
          ];
        };
      };
  };
}
