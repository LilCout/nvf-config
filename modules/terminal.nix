# Terminal (Snacks), with LazyVim's keys. The keys inside terminals (<C-h/j/k/l>, <C-/> to hide) are in snacks.nix.
let
  inherit (import ../lib/keys.nix) lua;
  # The terminal at the project root (ProjectRoot() in core.nix): focuses it when it's visible elsewhere, otherwise
  # opens or hides it. Inside a terminal, <C-/> hides that terminal (snacks.nix). LazyVim calls Snacks.terminal.focus,
  # which nvf's Snacks doesn't have yet; this does the same with get and toggle.
  focusRoot = key: desc:
    (lua key desc ''
      function()
        local term = Snacks.terminal.get(nil, { cwd = ProjectRoot(), create = false })
        if term and term:win_valid() and vim.api.nvim_get_current_win() ~= term.win then
          term:focus()
        else
          Snacks.terminal.toggle(nil, { cwd = ProjectRoot() })
        end
      end
    '')
    // {
      mode = ["n" "t"];
    };
in
  {lib, ...}: {
    vim = {
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
        (focusRoot "<c-/>" "Terminal (root dir)")
        (focusRoot "<c-_>" "which_key_ignore")
        (lua "<leader>ft" "Terminal (root dir)" "function() Snacks.terminal(nil, { cwd = ProjectRoot() }) end")
        (lua "<leader>fT" "Terminal (cwd)" "function() Snacks.terminal() end")
      ];
    };
  }
