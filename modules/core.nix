# Theme, the project root used by the keymaps, and which-key's group names
{
  vim = {
    theme = {
      enable = true;
      # Same as Ghostty's theme in the NixOS config
      name = "tokyonight";
      style = "moon";
    };
    # Editor options and autocommands are in options.nix

    # Project root for the keymaps in this folder (explorer, terminal, finders): nearest .jj or .git, else the cwd
    luaConfigRC.project-root = ''
      function _G.ProjectRoot()
        return vim.fs.root(0, { ".jj", ".git" }) or vim.fn.getcwd()
      end
    '';

    # Group names in which-key's menu, as in LazyVim
    binds.whichKey.register = {
      "<leader><tab>" = "+tabs";
      "<leader>a" = "+ai";
      "<leader>b" = "+buffer";
      "<leader>c" = "+code";
      "<leader>d" = "+debug";
      "<leader>f" = "+file/find";
      "<leader>g" = "+git";
      "<leader>gh" = "+hunks";
      "<leader>gx" = "+conflicts";
      "<leader>q" = "+quit/session";
      "<leader>s" = "+search";
      "<leader>sn" = "+noice";
      "<leader>u" = "+ui";
      "<leader>w" = "+windows";
      "<leader>x" = "+diagnostics/quickfix";
    };
  };
}
