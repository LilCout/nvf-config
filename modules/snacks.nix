# Snacks, LazyVim's utility plugin: picker, explorer, notifier, dashboard, indent guides, scrolling, terminals and
# smaller features. Picker and explorer keys are in navigation.nix and git.nix; the <leader>u… toggles in ui.nix.
let
  inherit (import ../lib/keys.nix) lua;
in
  {
    config,
    lib,
    ...
  }: let
    inherit (lib.generators) mkLuaInline;
  in {
    vim = {
      utility.snacks-nvim = {
        enable = true;
        setupOpts = {
          picker = {
            enabled = true;
            # Inside a picker: Alt+c switches between the project root and the cwd, Alt+t sends the results to Trouble
            win.input.keys = {
              "<a-c>" = mkLuaInline ''{ "toggle_cwd", mode = { "n", "i" } }'';
              "<a-t>" = mkLuaInline ''{ "trouble_open", mode = { "n", "i" } }'';
            };
            actions = {
              toggle_cwd = mkLuaInline ''
                function(p)
                  local root = vim.fs.root(p.input.filter.current_buf, { ".jj", ".git" }) or vim.fn.getcwd()
                  local cwd = vim.fs.normalize(vim.uv.cwd() or ".")
                  p:set_cwd(p:cwd() == root and cwd or root)
                  p:find()
                end
              '';
              trouble_open = mkLuaInline ''
                function(...) return require("trouble.sources.snacks").actions.trouble_open.action(...) end
              '';
            };
            # The explorer lists git-ignored files too (I toggles them; dotfiles stay hidden, H toggles those)
            sources.explorer.ignored = true;
          };
          explorer.enabled = true; # also opens for `nvim <folder>`, instead of netrw
          notifier.enabled = true;
          # Indent guides with the current scope highlighted, a floating input box (e.g. for rename), smooth scrolling,
          # highlighted uses of the word under the cursor, and the sign/fold column
          indent.enabled = true;
          input.enabled = true;
          scroll.enabled = true;
          words.enabled = true;
          statuscolumn.enabled = true;
          dashboard = {
            enabled = true;
            # LazyVim's dashboard keys, without its lazy.nvim entries and startup time, under Snacks' default
            # "NEOVIM" header (LazyVim's own shows its name)
            preset.keys =
              [
                {
                  icon = " ";
                  key = "f";
                  desc = "Find File";
                  action = ":lua Snacks.dashboard.pick('files')";
                }
                {
                  icon = " ";
                  key = "n";
                  desc = "New File";
                  action = ":ene | startinsert";
                }
                {
                  icon = " ";
                  key = "g";
                  desc = "Find Text";
                  action = ":lua Snacks.dashboard.pick('live_grep')";
                }
                {
                  icon = " ";
                  key = "r";
                  desc = "Recent Files";
                  action = ":lua Snacks.dashboard.pick('oldfiles')";
                }
              ]
              ++ lib.optional (config.configDir != null)
              {
                icon = " ";
                key = "c";
                desc = "Config";
                action = ":lua Snacks.dashboard.pick('files', { cwd = '${config.configDir}' })";
              }
              ++ [
                {
                  icon = " ";
                  key = "s";
                  desc = "Restore Session";
                  action = ":lua require('persistence').load()";
                }
                {
                  icon = " ";
                  key = "q";
                  desc = "Quit";
                  action = ":qa";
                }
              ];
            sections = [
              {section = "header";}
              {
                section = "keys";
                gap = 1;
                padding = 1;
              }
            ];
          };
          bigfile.enabled = true; # plain editing for huge files, without Treesitter and LSP
          quickfile.enabled = true; # draws a file opened from the command line before plugins load
          # Indent scope: ii/ai select the current indentation block, [i/]i jump to its edges
          scope.enabled = true;
          # Terminals (shells, lazygit, jjui, Claude Code's panel), with LazyVim's keys: <C-h/j/k/l> move to the window in
          # that direction (a floating terminal gets the key itself), <C-/> hides the terminal. Snacks' own: Esc Esc leaves
          # terminal mode (off in Claude's panel, claude.nix), q hides from normal mode.
          terminal.win.keys = let
            termNav = dir: desc:
              mkLuaInline ''
                {
                  "<C-${dir}>",
                  function(self)
                    return self:is_floating() and "<C-${dir}>" or vim.schedule(function() vim.cmd.wincmd("${dir}") end)
                  end,
                  desc = "${desc}",
                  expr = true,
                  mode = "t",
                }
              '';
          in {
            nav_h = termNav "h" "Go to left window";
            nav_j = termNav "j" "Go to lower window";
            nav_k = termNav "k" "Go to upper window";
            nav_l = termNav "l" "Go to right window";
            hide_slash = mkLuaInline ''{ "<C-/>", "hide", desc = "Hide terminal", mode = "t" }'';
            # Ctrl+/ arrives as <c-_> outside the kitty keyboard protocol
            hide_underscore = mkLuaInline ''{ "<c-_>", "hide", desc = "which_key_ignore", mode = "t" }'';
          };
        };
      };

      keymaps = [
        (lua "<leader>." "Toggle scratch buffer" "function() Snacks.scratch() end")
        (lua "<leader>S" "Select scratch buffer" "function() Snacks.scratch.select() end")
        (lua "<leader>dps" "Profiler scratch buffer" "function() Snacks.profiler.scratch() end")
        # Renames the file and lets the language servers update imports
        (lua "<leader>cR" "Rename file" "function() Snacks.rename.rename_file() end")
        ((lua "<leader>gB" "Git browse (open)" "function() Snacks.gitbrowse() end") // {mode = ["n" "x"];})
        ((lua "<leader>gY" "Git browse (copy)" "function() Snacks.gitbrowse({ open = function(url) vim.fn.setreg('+', url) end, notify = false }) end") // {mode = ["n" "x"];})
      ];

      autocmds = [
        {
          event = ["FileType"];
          pattern = ["lua"];
          desc = "Run Lua key";
          callback = mkLuaInline ''
            function(event)
              vim.keymap.set({ "n", "x" }, "<localleader>r", function() Snacks.debug.run() end, { buffer = event.buf, desc = "Run Lua" })
            end
          '';
        }
      ];
    };
  }
