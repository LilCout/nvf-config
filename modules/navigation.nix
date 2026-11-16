# Navigation: finder, file explorer, buffers, windows and tabs, with LazyVim's keys so its muscle memory carries over.
# Pickers and the explorer are Snacks' (snacks.nix), as in LazyVim. ProjectRoot() is in core.nix.
let
  inherit (import ../lib/keys.nix) cmd lua picker;
in
  {
    config,
    lib,
    pkgs,
    ...
  }: {
    vim = {
      extraPackages = with pkgs; [
        ripgrep # Snacks grep
        fd # Snacks file finder
      ];

      binds.whichKey.enable = true;

      # Sessions (windows and buffers per directory, with persistence.nvim as in LazyVim), saved automatically on exit
      lazy.plugins."persistence.nvim" = {
        package = pkgs.vimPlugins.persistence-nvim;
        setupModule = "persistence";
        setupOpts = {};
        event = ["BufReadPre"];
        keys = [
          (lua "<leader>qs" "Restore session" "function() require('persistence').load() end")
          (lua "<leader>qS" "Select session" "function() require('persistence').select() end")
          (lua "<leader>ql" "Restore last session" "function() require('persistence').load({ last = true }) end")
          (lua "<leader>qd" "Don't save current session" "function() require('persistence').stop() end")
        ];
      };
      # LazyVim's: without "blank", the explorer's window isn't saved (it came back as an empty [No Name] window),
      # nor terminals (they came back dead); "globals" keeps SessionExplorer, set below
      options.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,globals,skiprtp";
      autocmds = [
        {
          event = ["User"];
          pattern = ["PersistenceSavePre"];
          desc = "Remember whether the explorer was open";
          callback = lib.generators.mkLuaInline ''
            function()
              vim.g.SessionExplorer = #Snacks.picker.get({ source = "explorer" }) > 0 and 1 or 0
            end
          '';
        }
        {
          event = ["User"];
          pattern = ["PersistenceLoadPost"];
          desc = "Reopen the explorer if it was open";
          callback = lib.generators.mkLuaInline ''
            function()
              if vim.g.SessionExplorer == 1 and #Snacks.picker.get({ source = "explorer" }) == 0 then
                Snacks.explorer({ cwd = ProjectRoot() })
              end
            end
          '';
        }
      ];

      keymaps =
        [
          # Find
          (picker "<leader><space>" "Find files (root dir)" "files" "{ cwd = ProjectRoot() }")
          (picker "<leader>ff" "Find files (root dir)" "files" "{ cwd = ProjectRoot() }")
          (picker "<leader>fF" "Find files (cwd)" "files" "")
          (picker "<leader>fr" "Recent" "recent" "")
          (picker "<leader>fR" "Recent (cwd)" "recent" "{ filter = { cwd = true } }")
        ]
        ++ lib.optional (config.configDir != null) (picker "<leader>fc" "Find config file" "files" "{ cwd = '${config.configDir}' }")
        ++ [
          (picker "<leader>fp" "Projects" "projects" "")
          (picker "<leader>," "Switch buffer" "buffers" "")
          (picker "<leader>fb" "Buffers" "buffers" "")
          (picker "<leader>fB" "Buffers (all)" "buffers" "{ hidden = true, nofile = true }")
          (picker "<leader>:" "Command history" "command_history" "")
          (cmd "<leader>fn" "New file" "enew")

          # Search
          (picker "<leader>/" "Grep (root dir)" "grep" "{ cwd = ProjectRoot() }")
          (picker "<leader>sg" "Grep (root dir)" "grep" "{ cwd = ProjectRoot() }")
          (picker "<leader>sG" "Grep (cwd)" "grep" "")
          # Word under the cursor, or the selection in visual mode
          ((picker "<leader>sw" "Selection or word (root dir)" "grep_word" "{ cwd = ProjectRoot() }") // {mode = ["n" "x"];})
          ((picker "<leader>sW" "Selection or word (cwd)" "grep_word" "") // {mode = ["n" "x"];})
          (picker "<leader>sb" "Buffer lines" "lines" "")
          (picker "<leader>sB" "Grep open buffers" "grep_buffers" "")
          (picker "<leader>s\"" "Registers" "registers" "")
          (picker "<leader>s/" "Search history" "search_history" "")
          (picker "<leader>sa" "Autocmds" "autocmds" "")
          (picker "<leader>sc" "Command history" "command_history" "")
          (picker "<leader>sC" "Commands" "commands" "")
          (picker "<leader>sd" "Diagnostics" "diagnostics" "")
          (picker "<leader>sD" "Buffer diagnostics" "diagnostics_buffer" "")
          (picker "<leader>sh" "Help pages" "help" "")
          (picker "<leader>sH" "Highlights" "highlights" "")
          (picker "<leader>si" "Icons" "icons" "")
          (picker "<leader>sj" "Jumps" "jumps" "")
          (picker "<leader>sk" "Keymaps" "keymaps" "")
          (picker "<leader>sl" "Location list" "loclist" "")
          (picker "<leader>sm" "Marks" "marks" "")
          (picker "<leader>sM" "Man pages" "man" "")
          (picker "<leader>sq" "Quickfix list" "qflist" "")
          (picker "<leader>sR" "Resume" "resume" "")
          (picker "<leader>ss" "LSP symbols" "lsp_symbols" "")
          (picker "<leader>sS" "LSP workspace symbols" "lsp_workspace_symbols" "")
          (picker "<leader>su" "Undo history" "undo" "") # undotree's tree view is :UndotreeToggle
          (picker "<leader>uC" "Colorschemes" "colorschemes" "")

          # Buffers
          (cmd "<S-h>" "Previous buffer" "BufferLineCyclePrev")
          (cmd "<S-l>" "Next buffer" "BufferLineCycleNext")
          (cmd "<leader>bb" "Switch to other buffer" "e #")
          (cmd "<leader>`" "Switch to other buffer" "e #")
          (lua "<leader>bd" "Delete buffer" "function() Snacks.bufdelete() end")
          (cmd "<leader>bD" "Delete buffer and window" "bd")
          (lua "<leader>bi" "Delete invisible buffers" ''
            function()
              for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.bo[buf].buflisted and #vim.fn.win_findbuf(buf) == 0 then
                  Snacks.bufdelete(buf)
                end
              end
            end
          '')
          (lua "<leader>bo" "Delete other buffers" "function() Snacks.bufdelete.other() end")
          (cmd "<leader>bl" "Delete buffers to the left" "BufferLineCloseLeft")
          (cmd "<leader>br" "Delete buffers to the right" "BufferLineCloseRight")
          (cmd "<leader>bp" "Toggle pin" "BufferLineTogglePin")
          (cmd "<leader>bP" "Delete non-pinned buffers" "BufferLineGroupClose ungrouped")
          (cmd "[b" "Previous buffer" "BufferLineCyclePrev")
          (cmd "]b" "Next buffer" "BufferLineCycleNext")
          (cmd "[B" "Move buffer prev" "BufferLineMovePrev")
          (cmd "]B" "Move buffer next" "BufferLineMoveNext")
          (cmd "<leader>bj" "Pick buffer" "BufferLinePick")

          # Windows
          (cmd "<C-h>" "Go to left window" "wincmd h")
          (cmd "<C-j>" "Go to lower window" "wincmd j")
          (cmd "<C-k>" "Go to upper window" "wincmd k")
          (cmd "<C-l>" "Go to right window" "wincmd l")
          (cmd "<C-Up>" "Increase window height" "resize +2")
          (cmd "<C-Down>" "Decrease window height" "resize -2")
          (cmd "<C-Left>" "Decrease window width" "vertical resize -2")
          (cmd "<C-Right>" "Increase window width" "vertical resize +2")
          (cmd "<leader>-" "Split window below" "split")
          (cmd "<leader>|" "Split window right" "vsplit")
          (cmd "<leader>wd" "Delete window" "close")
          (cmd "<leader>qq" "Quit all" "qa")

          # Tabs
          (cmd "<leader><tab><tab>" "New tab" "tabnew")
          (cmd "<leader><tab>]" "Next tab" "tabnext")
          (cmd "<leader><tab>[" "Previous tab" "tabprevious")
          (cmd "<leader><tab>f" "First tab" "tabfirst")
          (cmd "<leader><tab>l" "Last tab" "tablast")
          (cmd "<leader><tab>o" "Close other tabs" "tabonly")
          (cmd "<leader><tab>d" "Close tab" "tabclose")

          # File explorer (Snacks)
          (lua "<leader>e" "Explorer (root dir)" "function() Snacks.explorer({ cwd = ProjectRoot() }) end")
          (lua "<leader>fe" "Explorer (root dir)" "function() Snacks.explorer({ cwd = ProjectRoot() }) end")
          (lua "<leader>E" "Explorer (cwd)" "function() Snacks.explorer() end")
          (lua "<leader>fE" "Explorer (cwd)" "function() Snacks.explorer() end")
        ];
    };
  }
