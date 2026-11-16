# Theme, the project root used by the keymaps, and which-key, as in LazyVim
{lib, ...}: {
  vim = {
    theme = {
      enable = true;
      # LazyVim's default colorscheme (also Ghostty's theme in the NixOS config)
      name = "tokyonight";
      style = "moon";
    };
    # Editor options and autocommands are in options.nix

    # Project root for the keymaps in this folder (explorer, terminal, finders, statusline): nearest .jj or .git, else
    # the cwd. LazyVim asks the language server first; jj repos need .jj.
    luaConfigRC.project-root = lib.nvim.dag.entryBefore ["pluginConfigs"] ''
      function _G.ProjectRoot()
        return vim.fs.root(0, { ".jj", ".git" }) or vim.fn.getcwd()
      end
    '';

    # which-key with LazyVim's settings: the "helix" layout, no borders, and its group names; <leader>b and <leader>w
    # list the open buffers and windows, and <leader>w also accepts <c-w>'s keys
    binds.whichKey = {
      setupOpts = {
        preset = "helix";
        replace = lib.mkForce {}; # which-key's own labels and icons (nvf's spell out "SPACE", "RETURN")
        win.border = lib.mkForce "none";
        spec = lib.generators.mkLuaInline ''
          {
            {
              mode = { "n", "x" },
              { "<leader><tab>", group = "tabs" },
              { "<leader>a", group = "ai" },
              { "<leader>c", group = "code" },
              { "<leader>d", group = "debug" },
              { "<leader>dp", group = "profiler" },
              { "<leader>f", group = "file/find" },
              { "<leader>g", group = "git" },
              { "<leader>gh", group = "hunks" },
              { "<leader>gx", group = "conflicts" },
              { "<leader>q", group = "quit/session" },
              { "<leader>s", group = "search" },
              { "<leader>sn", group = "noice" },
              { "<leader>u", group = "ui" },
              { "<leader>x", group = "diagnostics/quickfix" },
              { "[", group = "prev" },
              { "]", group = "next" },
              { "g", group = "goto" },
              { "gs", group = "surround" },
              { "z", group = "fold" },
              {
                "<leader>b",
                group = "buffer",
                expand = function() return require("which-key.extras").expand.buf() end,
              },
              {
                "<leader>w",
                group = "windows",
                proxy = "<c-w>",
                expand = function() return require("which-key.extras").expand.win() end,
              },
              { "gx", desc = "Open with system app" },
            },
          }
        '';
      };
      # nvf's own groups for keys that moved (gitsigns' <leader>h…, the LSP's <leader>lw…)
      register = {
        "<leader>h" = null;
        "<leader>lw" = null;
        "<leader>cw" = "+workspace";
      };
    };
  };
}
