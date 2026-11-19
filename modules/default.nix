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

  # Set by lib.mkNeovim's `full`, which does the rest of the light build (commands found on PATH); on its own, false
  # only changes the settings in languages.nix that the generic rewrite can't handle
  options.full = lib.mkOption {
    type = lib.types.bool;
    default = true;
    internal = true;
    description = "Whether the language servers, formatters, linters and debuggers are bundled.";
  };
}
