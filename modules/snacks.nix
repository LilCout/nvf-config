# Snacks, LazyVim's utility plugin: picker, explorer, notifier, start screen and smaller features.
# Picker and explorer keys are in navigation.nix and git.nix.
let
  inherit (import ../lib/keys.nix) lua;
in
  {
    config,
    lib,
    ...
  }: {
    vim = {
      utility.snacks-nvim = {
        enable = true;
        setupOpts = {
          picker = {
            enabled = true;
            ui_select = false; # fastaction (ui.nix) keeps vim.ui.select, for code actions with a key per entry
            # The explorer lists git-ignored files too (I toggles them; dotfiles stay hidden, H toggles those)
            sources.explorer.ignored = true;
          };
          explorer.enabled = true; # also opens for `nvim <folder>`, instead of netrw
          notifier.enabled = true;
          dashboard = {
            enabled = true;
            # Snacks' default keys and its "startup" section assume lazy.nvim and LazyVim's config folder
            preset.keys =
              [
                {
                  icon = " ";
                  key = "f";
                  desc = "Find file";
                  action = ":lua Snacks.picker.files()";
                }
                {
                  icon = " ";
                  key = "n";
                  desc = "New file";
                  action = ":ene | startinsert";
                }
                {
                  icon = " ";
                  key = "g";
                  desc = "Find text";
                  action = ":lua Snacks.picker.grep()";
                }
                {
                  icon = " ";
                  key = "r";
                  desc = "Recent files";
                  action = ":lua Snacks.picker.recent()";
                }
              ]
              ++ lib.optional (config.configDir != null)
              {
                icon = " ";
                key = "c";
                desc = "Config";
                action = ":lua Snacks.picker.files({ cwd = '${config.configDir}' })";
              }
              ++ [
                {
                  icon = " ";
                  key = "s";
                  desc = "Restore session";
                  action = ":lua require('persisted').load()";
                }
                {
                  icon = " ";
                  key = "q";
                  desc = "Quit";
                  action = ":qa";
                }
              ];
            sections = [
              {section = "header";}
              {
                section = "keys";
                gap = 1;
                padding = 1;
              }
            ];
          };
          bigfile.enabled = true; # plain editing for huge files, without Treesitter and LSP
          quickfile.enabled = true; # draws a file opened from the command line before plugins load
          # Indent scope: ii/ai select the current indentation block, [i/]i jump to its edges
          scope.enabled = true;
          # Terminals (shells, lazygit, jjui, Claude Code's panel), with LazyVim's keys: <C-h/j/k/l> move to the window in
          # that direction (a floating terminal gets the key itself), <C-/> hides the terminal. Snacks' own: Esc Esc leaves
          # terminal mode (off in Claude's panel, claude.nix), q hides from normal mode.
          terminal.win.keys = let
            termNav = dir: desc:
              lib.generators.mkLuaInline ''
                {
                  "<C-${dir}>",
                  function(self)
                    return self:is_floating() and "<C-${dir}>" or vim.schedule(function() vim.cmd.wincmd("${dir}") end)
                  end,
                  desc = "${desc}",
                  expr = true,
                  mode = "t",
                }
              '';
          in {
            nav_h = termNav "h" "Go to left window";
            nav_j = termNav "j" "Go to lower window";
            nav_k = termNav "k" "Go to upper window";
            nav_l = termNav "l" "Go to right window";
            hide_slash = lib.generators.mkLuaInline ''{ "<C-/>", "hide", desc = "Hide terminal", mode = "t" }'';
            # Ctrl+/ arrives as <c-_> outside the kitty keyboard protocol
            hide_underscore = lib.generators.mkLuaInline ''{ "<c-_>", "hide", desc = "which_key_ignore", mode = "t" }'';
          };
        };
      };

      keymaps = [
        (lua "<leader>uz" "Toggle zen mode" "function() Snacks.zen() end")
        (lua "<leader>uZ" "Toggle zoom mode" "function() Snacks.zen.zoom() end")
        (lua "<leader>wm" "Toggle zoom mode" "function() Snacks.zen.zoom() end")
        (lua "<leader>." "Toggle scratch buffer" "function() Snacks.scratch() end")
        (lua "<leader>S" "Select scratch buffer" "function() Snacks.scratch.select() end")
        # Renames the file and lets the language servers update imports
        (lua "<leader>cR" "Rename file" "function() Snacks.rename.rename_file() end")
        ((lua "<leader>gB" "Git browse (open)" "function() Snacks.gitbrowse() end") // {mode = ["n" "x"];})
        ((lua "<leader>gY" "Git browse (copy)" "function() Snacks.gitbrowse({ open = function(url) vim.fn.setreg('+', url) end, notify = false }) end") // {mode = ["n" "x"];})
      ];
    };
  }
