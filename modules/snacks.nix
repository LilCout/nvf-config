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
