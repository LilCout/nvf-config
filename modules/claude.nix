# Claude Code integration (claudecode.nvim), with LazyVim's claudecode keymaps
{pkgs, ...}: {
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
