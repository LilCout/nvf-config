# Terminal (toggleterm), with LazyVim's keys; toggleterm's own <c-t> opens it at the cwd
let
  inherit (import ../lib/keys.nix) lua;
  # Toggles a terminal in `dir` (a Lua expression). toggleterm can't open a split from a floating window ("Invalid
  # terminal direction"), and the explorer's list is one, so move to a regular editor window first.
  terminal = key: desc: dir:
    lua key desc ''
      function()
        if vim.api.nvim_win_get_config(0).relative ~= "" then
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
            if vim.api.nvim_win_get_config(win).relative == "" and ft ~= "snacks_layout_box" then
              vim.api.nvim_set_current_win(win)
              break
            end
          end
        end
        vim.cmd("ToggleTerm dir=" .. vim.fn.fnameescape(${dir}))
      end
    '';
  # Opens or closes a terminal at the project root (ProjectRoot() in default.nix), like LazyVim's
  rootTerminal = key: terminal key "Terminal (root dir)" "ProjectRoot()";
in
  {lib, ...}: {
    vim = {
      terminal.toggleterm.enable = true;

      # Terminals (Claude Code's panel included) stay out of the buffer list and the bufferline, as in LazyVim
      autocmds = [
        {
          event = ["TermOpen"];
          pattern = ["*"];
          desc = "Unlist terminal buffers";
          callback = lib.generators.mkLuaInline "function(event) vim.bo[event.buf].buflisted = false end";
        }
      ];

      keymaps = [
        # Ctrl+/ arrives as <c-/> in terminals with the kitty keyboard protocol (Ghostty) and as <c-_> elsewhere.
        ((rootTerminal "<c-/>") // {mode = ["n" "t"];})
        ((rootTerminal "<c-_>") // {mode = ["n" "t"];})
        (rootTerminal "<leader>ft")
        (terminal "<leader>fT" "Terminal (cwd)" "vim.fn.getcwd()")
      ];
    };
  }
