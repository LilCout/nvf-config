# nvf-config

Neovim as an IDE, configured with [nvf](https://github.com/NotAShelf/nvf) and LazyVim's keymaps. Plugins, language
servers, formatters and debuggers all come from Nix. It ignores `~/.config/nvim`; its state lives in
`~/.local/{share,state}/nvf`.

## Use

```sh
nix run .                # try it from this checkout
nix run github:<owner>/nvf-config
```

From another flake, build it with that flake's `pkgs` and add machine-specific settings as extra nvf modules:

```nix
inputs.nvf-config = {
  url = "github:<owner>/nvf-config";
  inputs.nixpkgs.follows = "nixpkgs";
};

# in a NixOS or Home Manager module
home.packages = [
  (inputs.nvf-config.lib.mkNeovim {
    inherit pkgs;
    modules = [{configDir = "/home/me/nixos-config";}];
  })
];
```

`nvfModules.default` is the same configuration as a module, for nvf's own Home Manager or NixOS module
(`programs.nvf.settings.imports = [inputs.nvf-config.nvfModules.default];`).

## Layout

```
flake.nix         mkNeovim, packages.<system>.default, nvfModules.default, formatter
lib/keys.nix      Keymap constructors (cmd, lua, picker) used by the modules
modules/
  default.nix     Imports the rest; the `configDir` option
  core.nix        Theme, ProjectRoot(), which-key groups
  options.nix     Editor options and autocommands (LazyVim's defaults)
  languages.nix   LSPs, formatters, Treesitter, debugger, LSP jumps
  editing.nix     Completion, snippets, pairs, comments, motions, text objects
  navigation.nix  Finder, explorer, buffer/window/tab and search keys, sessions
  terminal.nix    toggleterm and its keys
  git.nix         Git signs, diffs, lazygit, jjui, jj diff editor (hunk.nvim)
  claude.nix      claudecode.nvim
  snacks.nix      Snacks: picker, explorer, notifier, start screen, zen/zoom, scratch, rename file, git browse
  ui.nix          Statusline, buffer tabs, noice, todo comments, toggles
```
