# Claude Code integration (claudecode.nvim), with LazyVim's claudecode keymaps
{
  lib,
  pkgs,
  ...
}: {
  # <leader>as in the file explorer adds the file under the cursor (or the picked files) to Claude's context.
  # LazyVim's extra only maps it for neo-tree, oil and nvim-tree; claudecode.nvim also supports Snacks' explorer.
  vim.autocmds = [
    {
      event = ["FileType"];
      pattern = ["snacks_picker_list"];
      desc = "Add files to Claude from the explorer";
      callback = lib.generators.mkLuaInline ''
        function(event)
          vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", { buffer = event.buf, desc = "Add file to Claude" })
        end
      '';
    }
  ];

  vim.lazy.plugins."claudecode.nvim" = {
    package = pkgs.vimPlugins.claudecode-nvim;
    setupModule = "claudecode";
    # Snacks' terminal, as in LazyVim: entering the panel enters terminal mode, Shift+Enter inserts a newline, and the
    # terminal keys from snacks.nix apply (<C-h/j/k/l>, <C-/> hides it). Snacks' double Esc (leave terminal mode) is
    # turned off here: Claude Code uses Esc Esc to rewind.
    setupOpts.terminal = {
      provider = "snacks";
      snacks_win_opts.keys.term_normal = false;
    };
    cmd = ["ClaudeCode" "ClaudeCodeFocus" "ClaudeCodeAdd" "ClaudeCodeSend" "ClaudeCodeTreeAdd" "ClaudeCodeDiffAccept" "ClaudeCodeDiffDeny"];
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
