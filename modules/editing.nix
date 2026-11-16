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
  {
    lib,
    pkgs,
    ...
  }: {
    vim = {
      # Completion as in LazyVim: Enter accepts, Tab jumps through snippet fields, documentation shows after 200 ms,
      # snippets from friendly-snippets through Neovim's own vim.snippet, LazyVim's icons in the menu
      autocomplete.blink-cmp = {
        enable = true;
        friendly-snippets.enable = true;
        # nvf's keys (Tab/S-Tab select, <C-d>/<C-f> scroll); LazyVim uses blink's "enter" preset
        mappings = {
          complete = null;
          confirm = null;
          next = null;
          previous = null;
          close = null;
          scrollDocsUp = null;
          scrollDocsDown = null;
        };
        setupOpts = {
          keymap = {
            preset = "enter";
            "<C-y>" = ["select_and_accept"];
            "<Tab>" = ["snippet_forward" "fallback"];
          };
          appearance = {
            use_nvim_cmp_as_default = false;
            nerd_font_variant = "mono";
            kind_icons = lib.generators.mkLuaInline "LazyVimIcons.kinds";
          };
          completion = {
            accept.auto_brackets.enabled = true;
            menu.draw.treesitter = ["lsp"];
            ghost_text.enabled = true; # preview of the selected item, inline
          };
          # Lua: Neovim's API from lazydev first
          sources = {
            per_filetype.lua = lib.generators.mkLuaInline ''{ inherit_defaults = true, "lazydev" }'';
            providers.lazydev = {
              name = "LazyDev";
              module = "lazydev.integrations.blink";
              score_offset = 100;
            };
          };
          cmdline = {
            enabled = true;
            keymap = {
              preset = "cmdline";
              "<Right>" = [];
              "<Left>" = [];
            };
            completion = {
              list.selection.preselect = false;
              menu.auto_show = lib.generators.mkLuaInline ''function() return vim.fn.getcmdtype() == ":" end'';
              ghost_text.enabled = true;
            };
          };
        };
      };

      # Pairs: mini.pairs with LazyVim's tweaks (luaConfigRC below); <leader>up toggles it
      mini.pairs = {
        enable = true;
        setupOpts.modes = {
          insert = true;
          command = true;
          terminal = false;
        };
      };
      luaConfigRC.mini-pairs-lazyvim = lib.nvim.dag.entryAfter ["pluginConfigs"] ''
        do
          local opts = {
            skip_next = [=[[%w%%%'%[%"%.%`%$]]=], -- no pair before these characters
            skip_ts = { "string" }, -- nor inside strings
            skip_unbalanced = true, -- nor when the line has more closing than opening characters
            markdown = true, -- ``` in Markdown opens a code block
          }
          Snacks.toggle({
            name = "Mini Pairs",
            get = function() return not vim.g.minipairs_disable end,
            set = function(state) vim.g.minipairs_disable = not state end,
          }):map("<leader>up")
          local pairs = require("mini.pairs")
          local open = pairs.open
          pairs.open = function(pair, neigh_pattern)
            if vim.fn.getcmdline() ~= "" then
              return open(pair, neigh_pattern)
            end
            local o, c = pair:sub(1, 1), pair:sub(2, 2)
            local line = vim.api.nvim_get_current_line()
            local cursor = vim.api.nvim_win_get_cursor(0)
            local next = line:sub(cursor[2] + 1, cursor[2] + 1)
            local before = line:sub(1, cursor[2])
            if opts.markdown and o == "`" and vim.bo.filetype == "markdown" and before:match("^%s*``") then
              return "`\n```" .. vim.api.nvim_replace_termcodes("<up>", true, true, true)
            end
            if opts.skip_next and next ~= "" and next:match(opts.skip_next) then
              return o
            end
            if opts.skip_ts and #opts.skip_ts > 0 then
              local ok, captures = pcall(vim.treesitter.get_captures_at_pos, 0, cursor[1] - 1, math.max(cursor[2] - 1, 0))
              for _, capture in ipairs(ok and captures or {}) do
                if vim.tbl_contains(opts.skip_ts, capture.capture) then
                  return o
                end
              end
            end
            if opts.skip_unbalanced and next == c and c ~= o then
              local _, count_open = line:gsub(vim.pesc(pair:sub(1, 1)), "")
              local _, count_close = line:gsub(vim.pesc(pair:sub(2, 2)), "")
              if count_close > count_open then
                return o
              end
            end
            return open(pair, neigh_pattern)
          end
        end
      '';

      # Comments: Neovim's own gc/gcc, with ts-comments picking the comment style of embedded languages (e.g. JSX)
      extraPlugins.ts-comments = {
        package = pkgs.vimPlugins.ts-comments-nvim;
        setup = ''require("ts-comments").setup({})'';
      };

      # Surround, as LazyVim's mini.surround extra: gsa add, gsd delete, gsr replace, gsf/gsF find, gsh highlight
      mini.surround = {
        enable = true;
        setupOpts.mappings = {
          add = "gsa";
          delete = "gsd";
          find = "gsf";
          find_left = "gsF";
          highlight = "gsh";
          replace = "gsr";
          update_n_lines = "gsn";
        };
      };

      utility = {
        undotree.enable = true; # :UndotreeToggle; <leader>su is the Snacks undo picker, as in LazyVim
        grug-far-nvim = {
          enable = true; # search and replace across files
          setupOpts.headerMaxWidth = 80;
        };
        motion.flash-nvim.enable = true; # s / S, r / R in operator mode, <c-s> in a / search
      };

      # Queries for the moves above and mini.ai's f/c/o objects
      treesitter.textobjects.enable = true;
      # Text objects with a/i, as in LazyVim: f function, c class, o block/conditional/loop, a argument, t tag,
      # d digits, e word part (camelCase/snake_case), u/U function call, g whole buffer, q quotes, b brackets;
      # e.g. daf, cia, vi" from outside the quotes. which-key names them after typing a or i.
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
                e = {
                  { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
                  "^().*()$",
                },
                -- Whole buffer; the inner version skips leading and trailing blank lines
                g = function(ai_type)
                  local start_line, end_line = 1, vim.fn.line("$")
                  if ai_type == "i" then
                    local first, last = vim.fn.nextnonblank(start_line), vim.fn.prevnonblank(end_line)
                    if first == 0 or last == 0 then
                      return { from = { line = start_line, col = 1 } }
                    end
                    start_line, end_line = first, last
                  end
                  local to_col = math.max(vim.fn.getline(end_line):len(), 1)
                  return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
                end,
                u = ai.gen_spec.function_call(),
                U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
              }
            end)()
          '';
        };
      };
      luaConfigRC.mini-ai-whichkey = lib.nvim.dag.entryAfter ["pluginConfigs"] ''
        vim.schedule(function()
            local objects = {
              { " ", desc = "whitespace" }, { '"', desc = '" string' }, { "'", desc = "' string" },
              { "(", desc = "() block" }, { ")", desc = "() block with ws" }, { "<", desc = "<> block" },
              { ">", desc = "<> block with ws" }, { "?", desc = "user prompt" }, { "U", desc = "use/call without dot" },
              { "[", desc = "[] block" }, { "]", desc = "[] block with ws" }, { "_", desc = "underscore" },
              { "`", desc = "` string" }, { "a", desc = "argument" }, { "b", desc = ")]} block" },
              { "c", desc = "class" }, { "d", desc = "digit(s)" }, { "e", desc = "CamelCase / snake_case" },
              { "f", desc = "function" }, { "g", desc = "entire file" }, { "i", desc = "indent" },
              { "o", desc = "block, conditional, loop" }, { "q", desc = "quote `\"'" }, { "t", desc = "tag" },
              { "u", desc = "use/call" }, { "{", desc = "{} block" }, { "}", desc = "{} with ws" },
            }
            local ret = { mode = { "o", "x" } }
            local mappings = { around = "a", inside = "i", around_next = "an", inside_next = "in", around_last = "al", inside_last = "il" }
            for name, prefix in pairs(mappings) do
              name = name:gsub("^around_", ""):gsub("^inside_", "")
              ret[#ret + 1] = { prefix, group = name }
              for _, obj in ipairs(objects) do
                ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
              end
            end
            require("which-key").add(ret, { notify = false })
        end)
      '';

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
          {
            key = "<Down>";
            mode = ["n" "x"];
            desc = "Down";
            expr = true;
            action = "v:count == 0 ? 'gj' : 'j'";
          }
          {
            key = "<Up>";
            mode = ["n" "x"];
            desc = "Up";
            expr = true;
            action = "v:count == 0 ? 'gk' : 'k'";
          }
          # n always searches forward and N backward, whichever of / or ? started the search; in normal mode they also
          # open folds at the match
          {
            key = "n";
            mode = "n";
            desc = "Next search result";
            expr = true;
            action = "'Nn'[v:searchforward].'zv'";
          }
          {
            key = "N";
            mode = "n";
            desc = "Previous search result";
            expr = true;
            action = "'nN'[v:searchforward].'zv'";
          }
          {
            key = "n";
            mode = ["x" "o"];
            desc = "Next search result";
            expr = true;
            action = "'Nn'[v:searchforward]";
          }
          {
            key = "N";
            mode = ["x" "o"];
            desc = "Previous search result";
            expr = true;
            action = "'nN'[v:searchforward]";
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
            expr = true;
            lua = true;
            # Also leaves the snippet being filled in
            action = "function() vim.cmd('noh') if vim.snippet then vim.snippet.stop() end return '<esc>' end";
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
          # Search and replace across files with the current file's extension, prefilled with the selection in visual mode
          ((lua "<leader>sr" "Search and replace" ''
              function()
                local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
                require("grug-far").open({
                  transient = true,
                  prefills = { filesFilter = ext and ext ~= "" and "*." .. ext or nil },
                })
              end
            '')
            // {mode = ["n" "x"];})

          # Comment lines below/above
          {
            key = "gco";
            mode = "n";
            desc = "Add comment below";
            action = "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>";
          }
          {
            key = "gcO";
            mode = "n";
            desc = "Add comment above";
            action = "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>";
          }
          # Selects the Treesitter node at the cursor; <c-space> again grows it, <BS> shrinks it
          ((lua "<c-space>" "Treesitter incremental selection" "function() require('flash').treesitter({ actions = { ['<c-space>'] = 'next', ['<BS>'] = 'prev' } }) end")
            // {mode = ["n" "o" "x"];})
        ];
    };
  }
