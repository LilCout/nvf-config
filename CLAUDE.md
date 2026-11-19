# CLAUDE.md

Standalone Neovim configuration built with nvf (`nvf.lib.neovimConfiguration`). See README.md for the layout. The
user's NixOS config (`~/.nixos-config`, `modules/user/nvf.nix`) consumes it as the `nvf-config` flake input through
`lib.mkNeovim`, adding nixd's option completion for that flake and `configDir`.

## Commands

- Evaluate: `nix eval --raw .#packages.x86_64-linux.default.outPath`
- Build: `nix build --no-link --print-out-paths .#default` (don't leave a `result` link in the repo); run: `nix run .`
- Format: `nix fmt -- <file>` or `nix fmt -- .` (alejandra). Always pass a path.
- Inspect the generated Lua: `<package>/bin/nvf-print-config` (or `nvf-print-config-path`).
- Test changes headless, e.g. `nvim --headless` with a `vim.defer_fn` that prints `vim.lsp.get_clients()`; LSP logs are
  in `~/.local/state/nvf/lsp.log`.
- Options reference: nvf's manual (https://notashelf.github.io/nvf/options.html); the standalone build has no man page.
- The NixOS config reads this repo through a `path:` input, locked by hash: after a change here, run
  `nix flake update nvf-config` in `~/.nixos-config` (ask first: it changes that repo's `flake.lock`), then `nh os test`.

## Version control

Colocated Jujutsu repo (`.jj` next to `.git`). Use `jj`, not `git commit`. Only commit or push when asked. Flakes only
see tracked files: run `jj status` after creating a file, before building.

## Conventions

- Each file under `modules/` is a plain nvf module setting `vim.*` (no `programs.nvf.settings` prefix). Keymap helpers
  are in `lib/keys.nix` (`import ../lib/keys.nix`).
- The `imports` list in `modules/default.nix` is in reverse order on purpose: list options (keymaps, autocmds) are
  concatenated last import first, and a later keymap wins on the same key.
- Nothing machine-specific here: paths and host names go into the consumer's `mkNeovim { modules = [...]; }`.
  `configDir` (null by default) enables `<leader>fc` and the dashboard's Config entry.
- Style: alejandra formatting, short comments explaining why a setting exists. LazyVim's keys are mapped onto nvf's
  plugins; nvf's own default keys are moved with its `mappings` options.

## Notes

- Two packages: `default` (light) and `full`. Both enable every language. In the light one, `mkNeovim` evaluates the
  config once, then `lib/tools-on-path.nix` force-sets every LSP/formatter/linter/DAP command from a store path to its
  bare name on PATH. Values it can't rewrite (a non-`bin/` store path) warn and stay bundled: add a light-only
  override under `config.full` in `languages.nix`, as for codelldb and debugpy. Check the light closure with
  `nix path-info -rsSh` after adding a language.

- nvf sets `timeoutlen` under its short name `tm`, so override `tm` (options.nix).
- nvf's Julia server command was broken with LanguageServer.jl 6 (extra positional argument, removed `runlinter`
  field), so `languages.nix` overrides `vim.lsp.servers.julia-languageserver.cmd`; drop the override once nvf fixes it.
- hunk.nvim's `:DiffEditor` is jj's diff editor; the NixOS config sets `ui.diff-editor` to this package's `nvim`.
- nixd's `formatting.command` is alejandra's store path in the full package, so it works without alejandra on PATH
  (the light package needs alejandra on PATH).
