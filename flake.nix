{
  description = "Neovim configured with nvf, with LazyVim's keymaps";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nvf,
  }: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

    # Builds Neovim from this config plus extra nvf modules, with the caller's pkgs (a NixOS config passes its own,
    # so plugins and language servers come from the system's nixpkgs)
    mkNeovim = {
      pkgs,
      modules ? [],
    }:
      (nvf.lib.neovimConfiguration {
        inherit pkgs;
        modules = [self.nvfModules.default] ++ modules;
      }).neovim;
  in {
    lib = {inherit mkNeovim;};

    # For nvf's own NixOS/Home Manager modules: programs.nvf.settings.imports = [nvf-config.nvfModules.default];
    nvfModules.default = ./modules;

    # nix run github:<owner>/nvf-config
    packages = forAllSystems (pkgs: {
      default = mkNeovim {inherit pkgs;};
    });

    formatter = forAllSystems (pkgs: pkgs.alejandra);
  };
}
