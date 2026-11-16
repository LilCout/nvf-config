# Editor options and autocommands, following LazyVim's defaults (lua/lazyvim/config/options.lua and autocmds.lua)
{lib, ...}: let
  inherit (lib.generators) mkLuaInline;
  # Autocommand in the "lazyvim" group running a Lua function
  autocmd = event: pattern: desc: callback: {
    inherit event pattern desc;
    group = "lazyvim";
    callback = mkLuaInline callback;
  };
in {
  vim = {
    options = {
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      shiftround = true; # round indents to a multiple of shiftwidth
      smartindent = true;

      scrolloff = 4; # lines of context around the cursor
      sidescrolloff = 8;
      cursorline = true;
      laststatus = 3; # one statusline for all windows
      wrap = false; # <leader>uw toggles; text filetypes wrap (autocommand below)
      linebreak = true; # when wrapping, break at word boundaries
      conceallevel = 2; # hide Markdown markup such as ** and links' targets; JSON is excluded below
      splitkeep = "screen"; # splits don't scroll the other window

      confirm = true; # :q with unsaved changes asks instead of failing
      mouse = "a";
      tm = 300; # timeoutlen: which-key and key sequences respond faster; nvf sets it as `tm`, so this name overrides it
      updatetime = 200;
      virtualedit = "block"; # visual block can extend past line ends
      jumpoptions = "view"; # jumping back restores the view, not just the line
      undolevels = 10000;

      # Folds from Treesitter, all open at start; za/zc/zo/zR/zM
      foldmethod = "expr";
      foldexpr = "v:lua.vim.treesitter.foldexpr()";
      foldlevel = 99;
      foldtext = "";

      # More of LazyVim's options
      showmode = false; # lualine shows the mode
      list = true; # show tabs, trailing spaces and non-breaking spaces
      smoothscroll = true; # scroll through long wrapped lines a screen line at a time
      autowrite = true; # save before :make, :next and similar
      grepprg = "rg --vimgrep";
      grepformat = "%f:%l:%c:%m";
      winminwidth = 5;
      pumheight = 10; # popup menus show at most 10 entries
      wildmode = "longest:full,full";
      formatoptions = "jcroqlnt";
      # Fold arrows in the fold column, plain fold lines, diagonal fill for deleted diff lines, no ~ after the last line
      fillchars = "foldopen:,foldclose:,fold: ,foldsep: ,diff:╱,eob: ";
      # Neovim's default plus W (no "written"), I (no intro), c and C (no completion messages)
      shortmess = "ltToOCFWIcC";
    };
    undoFile.enable = true; # undo history survives closing the file (~/.local/state/nvf/undo)
    searchCase = "smart"; # case-insensitive unless the search has a capital
    clipboard = {
      enable = true;
      registers = "unnamedplus";
      providers.wl-copy.enable = true;
    };
    spellcheck.enable = false; # on per filetype below; <leader>us toggles

    augroups = [
      {
        name = "lazyvim";
        clear = true;
      }
    ];
    autocmds = [
      # Reload files changed outside Neovim, e.g. by Claude Code or jj
      (autocmd ["FocusGained" "TermClose" "TermLeave"] ["*"] "Reload files changed outside Neovim" ''
        function()
          if vim.o.buftype ~= "nofile" then vim.cmd("checktime") end
        end
      '')
      (autocmd ["TextYankPost"] ["*"] "Highlight yanked text" ''
        function() vim.hl.on_yank() end
      '')
      (autocmd ["VimResized"] ["*"] "Equalize splits when the terminal is resized" ''
        function()
          local tab = vim.fn.tabpagenr()
          vim.cmd("tabdo wincmd =")
          vim.cmd("tabnext " .. tab)
        end
      '')
      # Not for commit and jj description messages, which always start at the top
      (autocmd ["BufReadPost"] ["*"] "Reopen at the last cursor position" ''
        function(event)
          local exclude = { "gitcommit", "jjdescription" }
          local buf = event.buf
          if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_loc_done then return end
          vim.b[buf].last_loc_done = true
          local mark = vim.api.nvim_buf_get_mark(buf, '"')
          if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(buf) then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
          end
        end
      '')
      (autocmd ["FileType"] ["checkhealth" "dbout" "gitsigns-blame" "grug-far" "help" "lspinfo" "notify" "qf" "startuptime"] "Close with q" ''
        function(event)
          vim.bo[event.buf].buflisted = false
          vim.schedule(function()
            vim.keymap.set("n", "q", function()
              vim.cmd("close")
              pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
            end, { buffer = event.buf, silent = true, desc = "Quit buffer" })
          end)
        end
      '')
      (autocmd ["FileType"] ["man"] "Keep man pages out of the buffer list" ''
        function(event) vim.bo[event.buf].buflisted = false end
      '')
      (autocmd ["FileType"] ["text" "plaintex" "typst" "gitcommit" "jjdescription" "markdown"] "Wrap and spell-check text" ''
        function()
          vim.opt_local.wrap = true
          vim.opt_local.spell = true
        end
      '')
      (autocmd ["FileType"] ["json" "jsonc" "json5"] "Show JSON quotes" ''
        function() vim.opt_local.conceallevel = 0 end
      '')
      (autocmd ["BufWritePre"] ["*"] "Create missing folders on save" ''
        function(event)
          if event.match:match("^%w%w+:[\\/][\\/]") then return end
          local file = vim.uv.fs_realpath(event.match) or event.match
          vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
        end
      '')
    ];
  };
}
