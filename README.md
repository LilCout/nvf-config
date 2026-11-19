# nvf-config

Neovim as an IDE, configured with [nvf](https://github.com/NotAShelf/nvf) and LazyVim's keymaps. Plugins come from Nix.
It ignores `~/.config/nvim`; its state lives in `~/.local/{share,state}/nvf`.

Both packages support the same languages (Treesitter, LSP, formatters, linters, debuggers). They differ in where the
tools come from:

- `default` (about 0.5 GiB): language servers, formatters, linters and debuggers are looked up on PATH, e.g. a project's
  dev shell through direnv. Missing ones are skipped quietly. Julia's server needs `LanguageServer` installed and
  Python's debugger needs `debugpy`.
- `full` (about 7 GiB): all of them bundled from Nix, Julia only on x86_64.

## Use

```sh
nix run .                # try it from this checkout
nix run .#full           # with the language tools bundled
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
    # full = true;  # bundle the language tools
  })
];
```

`nvfModules.default` is the full configuration as a module, for nvf's own Home Manager or NixOS module
(`programs.nvf.settings.imports = [inputs.nvf-config.nvfModules.default];`).

## Layout

```
flake.nix         mkNeovim, packages.<system>.{default,full}, nvfModules.default, formatter
lib/keys.nix      Keymap constructors (cmd, lua, picker) used by the modules
lib/tools-on-path.nix  Light package: language tools' store paths rewritten to commands on PATH
modules/
  default.nix     Imports the rest; the `configDir` option
  core.nix        Theme, ProjectRoot(), which-key groups
  options.nix     Editor options and autocommands (LazyVim's defaults)
  languages.nix   LSPs, formatters, Treesitter, debugger, LSP jumps
  editing.nix     Completion, snippets, pairs, comments, motions, text objects
  navigation.nix  Finder, explorer, buffer/window/tab and search keys, sessions
  terminal.nix    Snacks terminals and their keys
  git.nix         Git signs, diffs, lazygit, jjui, jj diff editor (hunk.nvim)
  claude.nix      claudecode.nvim
  snacks.nix      Snacks: picker, explorer, notifier, start screen, zen/zoom, scratch, rename file, git browse
  ui.nix          Statusline, buffer tabs, noice, todo comments, toggles
```
