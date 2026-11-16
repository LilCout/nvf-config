# Claude Code integration (claudecode.nvim), with LazyVim's claudecode keymaps
{
  lib,
  pkgs,
  ...
}: {
  # claudecode.nvim enters terminal mode when its commands open or focus the panel (auto_insert), but not when the
  # window is entered another way (window keys, mouse), which left it in normal mode. Its own API tells which buffer is
  # the panel; before the plugin is loaded there is no panel.
  vim.autocmds = [
    {
      event = ["BufEnter" "WinEnter"];
      pattern = ["term://*"];
      desc = "Enter terminal mode in the Claude Code panel";
      callback = lib.generators.mkLuaInline ''
        function(event)
          if not package.loaded["claudecode"] or vim.api.nvim_get_mode().mode:sub(1, 1) ~= "n" then -- "nt" in a terminal
            return
          end
          if event.buf == require("claudecode.terminal").get_active_terminal_bufnr() then
            vim.cmd("startinsert")
          end
        end
      '';
    }
  ];

  vim.lazy.plugins."claudecode.nvim" = {
    package = pkgs.vimPlugins.claudecode-nvim;
    setupModule = "claudecode";
    # Neovim's own terminal; with Snacks loaded (snacks.nix) it would pick Snacks', whose double Esc Claude Code uses
    setupOpts.terminal.provider = "native";
    cmd = ["ClaudeCode" "ClaudeCodeFocus" "ClaudeCodeAdd" "ClaudeCodeSend" "ClaudeCodeDiffAccept" "ClaudeCodeDiffDeny"];
    keys = [
      {
        key = "<leader>ac";
        mode = "n";
        action = "<cmd>ClaudeCode<cr>";
        desc = "Toggle Claude";
      }
      {
        key = "<leader>af";
        mode = "n";
        action = "<cmd>ClaudeCodeFocus<cr>";
        desc = "Focus Claude";
      }
      {
        key = "<leader>ar";
        mode = "n";
        action = "<cmd>ClaudeCode --resume<cr>";
        desc = "Resume Claude";
      }
      {
        key = "<leader>aC";
        mode = "n";
        action = "<cmd>ClaudeCode --continue<cr>";
        desc = "Continue Claude";
      }
      {
        key = "<leader>ab";
        mode = "n";
        action = "<cmd>ClaudeCodeAdd %<cr>";
        desc = "Add current buffer";
      }
      {
        key = "<leader>as";
        mode = "v";
        action = "<cmd>ClaudeCodeSend<cr>";
        desc = "Send to Claude";
      }
      {
        key = "<leader>aa";
        mode = "n";
        action = "<cmd>ClaudeCodeDiffAccept<cr>";
        desc = "Accept diff";
      }
      {
        key = "<leader>ad";
        mode = "n";
        action = "<cmd>ClaudeCodeDiffDeny<cr>";
        desc = "Deny diff";
      }
    ];
  };
}
