# The whole configuration, one area per file. Order matters only for list options (keymaps, autocmds; a later keymap
# wins on the same key): the module system concatenates imports' definitions last to first, so this list is reversed
# to keep the order the files had in the NixOS config (claude, editing, git, ... ui).
{lib, ...}: {
  imports = [
    ./ui.nix
    ./terminal.nix
    ./snacks.nix
    ./options.nix
    ./core.nix
    ./navigation.nix
    ./languages.nix
    ./git.nix
    ./editing.nix
    ./claude.nix
  ];

  # Not an nvf option: set by whoever builds the package (lib.mkNeovim's `modules`), e.g. the NixOS config
  options.configDir = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "/home/me/nixos-config";
    description = "Absolute path opened by <leader>fc and the dashboard's Config entry; both are left out when null.";
  };
}
