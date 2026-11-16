# Editing: completion, snippets, pairs, comments, motions, and LazyVim's general editing keys
let
  inherit (import ../lib/keys.nix) cmd lua;

  # Treesitter textobject moves, as in LazyVim: ]f/[f function, ]c/[c class, ]a/[a argument; capitals go to the end.
  # In diff mode ]c/[c stay Vim's next/previous change.
  move = key: desc: fn: query: {
    inherit key desc;
    mode = ["n" "x" "o"];
    lua = true;
    action = "function() if vim.wo.diff and ('${key}'):find('[cC]') then return vim.cmd('normal! ${key}') end require('nvim-treesitter-textobjects.move').${fn}('${query}', 'textobjects') end";
  };
  moves = letter: upper: query: name: [
    (move "]${letter}" "Next ${name} start" "goto_next_start" query)
    (move "]${upper}" "Next ${name} end" "goto_next_end" query)
    (move "[${letter}" "Previous ${name} start" "goto_previous_start" query)
    (move "[${upper}" "Previous ${name} end" "goto_previous_end" query)
  ];
in
  {lib, ...}: {
    vim = {
      autocomplete.blink-cmp = {
        enable = true;
        setupOpts.completion.ghost_text.enabled = true; # preview of the selected item, inline
      };
      snippets.luasnip.enable = true;
      autopairs.nvim-autopairs.enable = true;
      comments.comment-nvim.enable = true; # gcc, gc, gco/gcO (comment below/above)
      utility = {
        surround.enable = true;
        undotree.enable = true;
        grug-far-nvim.enable = true; # search and replace across files
        motion.flash-nvim.enable = true; # s / S, r / R in operator mode, <c-s> in a / search
      };

      # Queries for the moves above and mini.ai's f/c/o objects
      treesitter.textobjects.enable = true;
      # Text objects with a/i, as in LazyVim: f function, c class, o block/conditional/loop, a argument, t tag,
      # d digits, u/U function call, g whole buffer, q quotes, b brackets; e.g. daf, cia, vi" from outside the quotes
      mini.ai = {
        enable = true;
        setupOpts = {
          n_lines = 500;
          custom_textobjects = lib.generators.mkLuaInline ''
            (function()
              local ai = require("mini.ai")
              return {
                o = ai.gen_spec.treesitter({
                  a = { "@block.outer", "@conditional.outer", "@loop.outer" },
                  i = { "@block.inner", "@conditional.inner", "@loop.inner" },
                }),
                f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
                c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
                t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
                d = { "%f[%d]%d+" },
                u = ai.gen_spec.function_call(),
                U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
                g = function()
                  local last = vim.fn.line("$")
                  return { from = { line = 1, col = 1 }, to = { line = last, col = math.max(vim.fn.getline(last):len(), 1) } }
                end,
              }
            end)()
          '';
        };
      };

      keymaps =
        moves "f" "F" "@function.outer" "function"
        ++ moves "c" "C" "@class.outer" "class"
        ++ moves "a" "A" "@parameter.inner" "argument"
        ++ [
          # j/k move by screen line in wrapped text, unless given a count
          {
            key = "j";
            mode = ["n" "x"];
            desc = "Down";
            expr = true;
            action = "v:count == 0 ? 'gj' : 'j'";
          }
          {
            key = "k";
            mode = ["n" "x"];
            desc = "Up";
            expr = true;
            action = "v:count == 0 ? 'gk' : 'k'";
          }
          # n always searches forward and N backward, whichever of / or ? started the search
          {
            key = "n";
            mode = ["n" "x" "o"];
            desc = "Next search result";
            expr = true;
            action = "'Nn'[v:searchforward].'zv'";
          }
          {
            key = "N";
            mode = ["n" "x" "o"];
            desc = "Previous search result";
            expr = true;
            action = "'nN'[v:searchforward].'zv'";
          }

          # Move lines
          {
            key = "<A-j>";
            mode = "n";
            desc = "Move down";
            action = "<cmd>execute 'move .+' . v:count1<cr>==";
          }
          {
            key = "<A-k>";
            mode = "n";
            desc = "Move up";
            action = "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==";
          }
          {
            key = "<A-j>";
            mode = "i";
            desc = "Move down";
            action = "<esc><cmd>m .+1<cr>==gi";
          }
          {
            key = "<A-k>";
            mode = "i";
            desc = "Move up";
            action = "<esc><cmd>m .-2<cr>==gi";
          }
          {
            key = "<A-j>";
            mode = "v";
            desc = "Move down";
            action = ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv";
          }
          {
            key = "<A-k>";
            mode = "v";
            desc = "Move up";
            action = ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv";
          }
          # Keep the selection when indenting
          {
            key = "<";
            mode = "x";
            desc = "Indent left";
            action = "<gv";
          }
          {
            key = ">";
            mode = "x";
            desc = "Indent right";
            action = ">gv";
          }

          {
            key = "<C-s>";
            mode = ["i" "x" "n" "s"];
            desc = "Save file";
            action = "<cmd>w<cr><esc>";
          }
          {
            key = "<esc>";
            mode = ["i" "n" "s"];
            desc = "Escape and clear hlsearch";
            action = "<cmd>noh<cr><esc>";
          }
          (cmd "<leader>ur" "Redraw / clear hlsearch / diff update" "nohlsearch<bar>diffupdate<bar>normal! <C-L>")
          (cmd "<leader>K" "Keywordprg" "norm! K")
        ]
        # Undo breakpoints: u undoes up to the last , . or ; typed, not the whole insert
        ++ map (char: {
          key = char;
          mode = "i";
          action = "${char}<c-g>u";
        }) ["," "." ";"]
        ++ [
          # Search and replace across files, prefilled with the selection in visual mode
          (lua "<leader>sr" "Search and replace" "function() require('grug-far').open({ transient = true }) end")
          ((lua "<leader>sr" "Search and replace" "function() require('grug-far').with_visual_selection({ transient = true }) end") // {mode = "x";})
        ];
    };
  }
