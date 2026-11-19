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
    # so plugins and language servers come from the system's nixpkgs). Every language is configured either way; `full`
    # bundles their servers, formatters, linters and debuggers, otherwise Neovim finds them on PATH (lib/tools-on-path.nix).
    mkNeovim = {
      pkgs,
      modules ? [],
      full ? false,
    }: let
      configuration = extra:
        nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = [self.nvfModules.default {inherit full;}] ++ modules ++ extra;
        };
      # Commands as store paths, which the light package rewrites from this first evaluation (only evaluated, not built)
      withStorePaths = configuration [];
    in
      if full
      then withStorePaths.neovim
      else (configuration [(import ./lib/tools-on-path.nix pkgs.lib withStorePaths.config)]).neovim;
  in {
    lib = {inherit mkNeovim;};

    # For nvf's own NixOS/Home Manager modules: programs.nvf.settings.imports = [nvf-config.nvfModules.default];
    # the full configuration (the light one needs mkNeovim's second evaluation)
    nvfModules.default = ./modules;

    # nix run github:<owner>/nvf-config, or …#full with the language tools bundled
    packages = forAllSystems (pkgs: {
      default = mkNeovim {inherit pkgs;};
      full = mkNeovim {
        inherit pkgs;
        full = true;
      };
    });

    formatter = forAllSystems (pkgs: pkgs.alejandra);
  };
}
