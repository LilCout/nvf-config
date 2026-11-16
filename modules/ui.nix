# Look: statusline, buffer tabs, noice, todo comments, and LazyVim's <leader>u… toggles
let
  inherit (import ../lib/keys.nix) cmd lua picker;
in
  {lib, ...}: let
    # File path relative to the cwd, only for file buffers (not terminals, pickers, or other special buffers)
    fileName = ["filename" (lib.generators.mkLuaInline "path = 1, cond = function() return vim.bo.buftype == '' end")];
  in {
    vim = {
      statusline.lualine = {
        enable = true;
        # A bar at the top of each window: its file, and in the active one the symbol path from the language server
        # (navic); the statusline is shared by all windows (laststatus = 3). :Navbuddy browses the file's symbols.
        integrations.breadcrumbs = {
          location = "winbar";
          nvim-navic.enable = true;
          navbuddy.enable = true;
        };
        setupOpts = {
          winbar.lualine_b = [fileName];
          inactive_winbar.lualine_b = [fileName];
          options.disabled_filetypes.winbar = ["snacks_dashboard" "snacks_picker_list" "snacks_picker_input" "snacks_layout_box" "toggleterm" "trouble" "help" "qf"];
        };
      };
      tabline.nvimBufferline.enable = true;
      visuals = {
        nvim-web-devicons.enable = true;
        indent-blankline.enable = true;
        highlight-undo.enable = true;
        nvim-scrollbar.enable = true; # with marks for diagnostics, git changes and search hits
      };
      ui = {
        borders.enable = true;
        noice.enable = true; # also shows LSP progress, bottom right (as in LazyVim; fidget would duplicate it)
        colorizer.enable = true;
        illuminate.enable = true;
        fastaction.enable = true; # code-action and selection menus with a key per entry
      };
      # Notifications and the start screen are Snacks' (snacks.nix); noice shows its messages through the Snacks notifier
      notes.todo-comments = {
        enable = true;
        mappings = {
          trouble = "<leader>xt";
          telescope = null; # Snacks pickers below
          quickFix = null;
        };
      };

      keymaps = [
        # Toggles; `option?` echoes the new value
        (cmd "<leader>uw" "Toggle wrap" "setlocal wrap! wrap?")
        (cmd "<leader>ul" "Toggle line numbers" "setlocal number! number?")
        (cmd "<leader>uL" "Toggle relative numbers" "setlocal relativenumber! relativenumber?")
        (cmd "<leader>us" "Toggle spelling" "setlocal spell! spell?")
        (cmd "<leader>uc" "Toggle conceal level" "let &l:conceallevel = &l:conceallevel == 0 ? 2 : 0 | set conceallevel?")
        (cmd "<leader>ub" "Toggle dark background" "let &background = &background ==# 'dark' ? 'light' : 'dark'")
        (lua "<leader>uT" "Toggle Treesitter highlight" "function() if vim.b.ts_highlight then vim.treesitter.stop() else vim.treesitter.start() end end")
        (cmd "<leader>ug" "Toggle indent guides" "IBLToggle")
        (cmd "<leader>ui" "Inspect position" "Inspect")
        (cmd "<leader>uI" "Inspect tree" "InspectTree")

        # Notifications (Snacks notifier and noice)
        (picker "<leader>n" "Notification history" "notifications" "")
        (lua "<leader>un" "Dismiss all notifications" "function() Snacks.notifier.hide() end")
        (cmd "<leader>snl" "Noice last message" "Noice last")
        (cmd "<leader>snh" "Noice history" "Noice history")
        (cmd "<leader>sna" "Noice all" "Noice all")
        (cmd "<leader>snd" "Dismiss all" "Noice dismiss")
        (cmd "<leader>snt" "Noice picker" "Noice snacks")

        # Todo comments
        (picker "<leader>st" "Todo" "todo_comments" "")
        (picker "<leader>sT" "Todo/Fix/Fixme" "todo_comments" "{ keywords = { 'TODO', 'FIX', 'FIXME' } }")
        (cmd "<leader>xT" "Todo/Fix/Fixme (Trouble)" "Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}")
        (lua "]t" "Next todo comment" "function() require('todo-comments').jump_next() end")
        (lua "[t" "Previous todo comment" "function() require('todo-comments').jump_prev() end")

        (lua "<leader>?" "Buffer keymaps (which-key)" "function() require('which-key').show({ global = false }) end")
      ];
    };
  }
