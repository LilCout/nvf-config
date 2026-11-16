# Look, as in LazyVim: statusline, buffer tabs, icons, noice, todo comments, and the <leader>u… toggles.
# lualine and bufferline are set up here with LazyVim's options rather than through nvf's modules, whose defaults
# (layout, separators, buffer numbers) differ from LazyVim's in many places.
let
  inherit (import ../lib/keys.nix) cmd lua picker;
in
  {
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.generators) mkLuaInline;
    inherit (lib.nvim.dag) entryAfter entryBetween;
  in {
    vim = {
      # Icons from mini.icons, standing in for nvim-web-devicons (some nvf modules turn that on; mini.icons answers its
      # calls instead)
      visuals.nvim-web-devicons.enable = lib.mkForce false;
      startPlugins = ["mini-icons"];
      # Not in LazyVim: colour codes (e.g. #ff8800) shown in their colour
      ui.colorizer.enable = true;
      luaConfigRC.mini-icons = entryBetween ["pluginConfigs"] ["lazyConfigs"] ''
        require("mini.icons").setup({
          file = {
            [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
            ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
          },
          filetype = {
            dotenv = { glyph = "", hl = "MiniIconsYellow" },
          },
        })
        require("mini.icons").mock_nvim_web_devicons()
      '';

      extraPlugins = {
        lualine = {
          package = pkgs.vimPlugins.lualine-nvim;
          setup = ''
            do
              local icons = LazyVimIcons

              -- A path relative to the cwd, shortened to its first part and last two, the file name in bold (red when
              -- modified), as LazyVim's pretty_path
              local function hl(component, text, group)
                text = text:gsub("%%", "%%%%")
                component.hl_cache = component.hl_cache or {}
                local lualine_hl = component.hl_cache[group]
                if not lualine_hl then
                  local utils = require("lualine.utils.utils")
                  local gui = vim.tbl_filter(function(x) return x end, {
                    utils.extract_highlight_colors(group, "bold") and "bold",
                    utils.extract_highlight_colors(group, "italic") and "italic",
                  })
                  lualine_hl = component:create_hl({
                    fg = utils.extract_highlight_colors(group, "fg"),
                    gui = #gui > 0 and table.concat(gui, ",") or nil,
                  }, "LV_" .. group)
                  component.hl_cache[group] = lualine_hl
                end
                return component:format_hl(lualine_hl) .. text .. component:get_default_hl()
              end
              local function pretty_path(self)
                local path = vim.fn.expand("%:p")
                if path == "" then return "" end
                local root, cwd = ProjectRoot(), vim.fn.getcwd()
                if path:find(cwd, 1, true) == 1 then
                  path = path:sub(#cwd + 2)
                elseif path:find(root, 1, true) == 1 then
                  path = path:sub(#root + 2)
                end
                local parts = vim.split(path, "/")
                if #parts > 3 then
                  parts = { parts[1], "…", unpack(parts, #parts - 1, #parts) }
                end
                parts[#parts] = hl(self, parts[#parts], vim.bo.modified and "MatchParen" or "Bold")
                local dir = #parts > 1 and table.concat({ unpack(parts, 1, #parts - 1) }, "/") .. "/" or ""
                local readonly = vim.bo.readonly and hl(self, " 󰌾 ", "MatchParen") or ""
                return dir .. parts[#parts] .. readonly
              end
              -- The project's name when it isn't the cwd
              local function root_name()
                local root, cwd = ProjectRoot(), vim.fn.getcwd()
                return root ~= cwd and vim.fs.basename(root) or nil
              end

              -- File buffers only (not terminals, pickers or other special buffers)
              local winbar_file = { "filename", path = 1, cond = function() return vim.bo.buftype == "" end }

              local trouble = require("trouble").statusline({
                mode = "symbols",
                groups = {},
                title = false,
                filter = { range = true },
                format = "{kind_icon}{symbol.name:Normal}",
                hl_group = "lualine_c_normal",
              })

              require("lualine").setup({
                options = {
                  theme = "auto",
                  globalstatus = vim.o.laststatus == 3,
                  disabled_filetypes = {
                    statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" },
                    winbar = { "snacks_dashboard", "snacks_picker_list", "snacks_picker_input", "snacks_layout_box", "snacks_terminal", "trouble", "help", "qf" },
                  },
                },
                sections = {
                  lualine_a = { "mode" },
                  lualine_b = { "branch" },
                  lualine_c = {
                    {
                      function() return "󱉭  " .. root_name() end,
                      cond = function() return root_name() ~= nil end,
                      color = function() return { fg = Snacks.util.color("Special") } end,
                    },
                    {
                      "diagnostics",
                      symbols = {
                        error = icons.diagnostics.Error,
                        warn = icons.diagnostics.Warn,
                        info = icons.diagnostics.Info,
                        hint = icons.diagnostics.Hint,
                      },
                    },
                    { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
                    { pretty_path },
                    -- The symbol path at the cursor (Trouble)
                    {
                      trouble.get,
                      cond = function() return vim.b.trouble_lualine ~= false and trouble.has() end,
                    },
                  },
                  lualine_x = {
                    -- Keys of a command being typed (e.g. 2d) and macro recording ("recording @q"); noice hides
                    -- Neovim's own messages for these
                    {
                      function() return require("noice").api.status.command.get() end,
                      cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
                      color = function() return { fg = Snacks.util.color("Statement") } end,
                    },
                    {
                      function() return require("noice").api.status.mode.get() end,
                      cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
                      color = function() return { fg = Snacks.util.color("Constant") } end,
                    },
                    {
                      function() return "  " .. require("dap").status() end,
                      cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
                      color = function() return { fg = Snacks.util.color("Debug") } end,
                    },
                    {
                      "diff",
                      symbols = { added = icons.git.added, modified = icons.git.modified, removed = icons.git.removed },
                      source = function()
                        local gitsigns = vim.b.gitsigns_status_dict
                        if gitsigns then
                          return { added = gitsigns.added, modified = gitsigns.changed, removed = gitsigns.removed }
                        end
                      end,
                    },
                  },
                  lualine_y = {
                    { "progress", separator = " ", padding = { left = 1, right = 0 } },
                    { "location", padding = { left = 0, right = 1 } },
                  },
                  lualine_z = {
                    function() return " " .. os.date("%R") end,
                  },
                },
                -- Not in LazyVim: a bar at the top of each window with its file's path (relative to the cwd), so split windows
                -- show which file they hold; the statusline is shared by all windows
                winbar = { lualine_b = { winbar_file } },
                inactive_winbar = { lualine_b = { winbar_file } },
              })
            end
          '';
        };

        bufferline = {
          package = pkgs.vimPlugins.bufferline-nvim;
          setup = ''
            require("bufferline").setup({
              options = {
                close_command = function(n) Snacks.bufdelete(n) end,
                right_mouse_command = function(n) Snacks.bufdelete(n) end,
                diagnostics = "nvim_lsp",
                always_show_bufferline = false,
                diagnostics_indicator = function(_, _, diag)
                  local icons = LazyVimIcons.diagnostics
                  local ret = (diag.error and icons.Error .. diag.error .. " " or "")
                    .. (diag.warning and icons.Warn .. diag.warning or "")
                  return vim.trim(ret)
                end,
                offsets = {
                  { filetype = "snacks_layout_box" },
                },
              },
            })
            -- Redraws the tabs when buffers are added or deleted from a session restore
            vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
              callback = function()
                vim.schedule(function() pcall(nvim_bufferline) end)
              end,
            })
          '';
        };
      };

      # LazyVim's icons, used by the statusline, bufferline, diagnostics, debugger and completion menu
      luaConfigRC.lazyvim-icons = entryBetween ["pluginConfigs"] ["lazyConfigs"] ''
          _G.LazyVimIcons = {
            diagnostics = { Error = " ", Warn = " ", Hint = " ", Info = " " },
            git = { added = " ", modified = " ", removed = " " },
            dap = {
              Stopped = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
              Breakpoint = " ",
              BreakpointCondition = " ",
              BreakpointRejected = { " ", "DiagnosticError" },
              LogPoint = ".>",
            },
            kinds = {
        Array         = " ",
        Boolean       = "󰨙 ",
        Class         = " ",
        Codeium       = "󰘦 ",
        Color         = " ",
        Control       = " ",
        Collapsed     = " ",
        Constant      = "󰏿 ",
        Constructor   = " ",
        Copilot       = " ",
        Enum          = " ",
        EnumMember    = " ",
        Event         = " ",
        Field         = " ",
        File          = " ",
        Folder        = " ",
        Function      = "󰊕 ",
        Interface     = " ",
        Key           = " ",
        Keyword       = " ",
        Method        = "󰊕 ",
        Module        = " ",
        Namespace     = "󰦮 ",
        Null          = " ",
        Number        = "󰎠 ",
        Object        = " ",
        Operator      = " ",
        Package       = " ",
        Property      = " ",
        Reference     = " ",
        Snippet       = "󱄽 ",
        String        = " ",
        Struct        = "󰆼 ",
        Supermaven    = " ",
        TabNine       = "󰏚 ",
        Text          = " ",
        TypeParameter = " ",
        Unit          = " ",
        Value         = " ",
        Variable      = "󰀫 ",
            },
          }
      '';

      ui.noice = {
        enable = true; # also shows LSP progress, bottom right
        setupOpts = {
          lsp.signature.enabled = true;
          # noice's own cmdline icons
          format = {
            cmdline = null;
            search_down = null;
            search_up = null;
            filter = null;
            lua = null;
            help = null;
          };
          # Write and undo messages go to the small view at the bottom right
          routes = lib.mkForce [
            {
              filter = {
                event = "msg_show";
                any = [
                  {find = "%d+L, %d+B";}
                  {find = "; after #%d+";}
                  {find = "; before #%d+";}
                ];
              };
              view = "mini";
            }
          ];
        };
      };
      # Notifications and the start screen are Snacks' (snacks.nix); noice shows its messages through the Snacks notifier
      notes.todo-comments = {
        enable = true;
        mappings = {
          trouble = "<leader>xt";
          telescope = null; # Snacks pickers below
          quickFix = null;
        };
      };

      # LazyVim's toggles: each notifies its new state, and which-key shows it next to the key
      luaConfigRC.lazyvim-toggles = entryAfter ["pluginConfigs"] ''
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.line_number():map("<leader>ul")
        Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" }):map("<leader>uc")
        Snacks.toggle.option("showtabline", { off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = "Tabline" }):map("<leader>uA")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
        Snacks.toggle.dim():map("<leader>uD")
        Snacks.toggle.animate():map("<leader>ua")
        Snacks.toggle.indent():map("<leader>ug")
        Snacks.toggle.scroll():map("<leader>uS")
        Snacks.toggle.profiler():map("<leader>dpp")
        Snacks.toggle.profiler_highlights():map("<leader>dph")
        Snacks.toggle.inlay_hints():map("<leader>uh")
        Snacks.toggle.zoom():map("<leader>wm"):map("<leader>uZ")
        Snacks.toggle.zen():map("<leader>uz")
        Snacks.toggle({
          name = "Render Markdown",
          get = function() return require("render-markdown").get() end,
          set = function(state) require("render-markdown").set(state) end,
        }):map("<leader>um")
        Snacks.toggle({
          name = "Git Signs",
          get = function() return require("gitsigns.config").config.signcolumn end,
          set = function(state) require("gitsigns").toggle_signs(state) end,
        }):map("<leader>uG")
      '';

      keymaps = [
        (lua "<leader>ui" "Inspect pos" "vim.show_pos")
        (lua "<leader>uI" "Inspect tree" "function() vim.treesitter.inspect_tree() vim.api.nvim_input('I') end")

        # Notifications (Snacks notifier and noice)
        (picker "<leader>n" "Notification history" "notifications" "")
        (lua "<leader>un" "Dismiss all notifications" "function() Snacks.notifier.hide() end")
        (cmd "<leader>snl" "Noice last message" "Noice last")
        (cmd "<leader>snh" "Noice history" "Noice history")
        (cmd "<leader>sna" "Noice all" "Noice all")
        (cmd "<leader>snd" "Dismiss all" "Noice dismiss")
        (cmd "<leader>snt" "Noice picker" "Noice snacks")
        # Scroll hover and signature popups; the keys keep their usual meaning when there is none
        ((lua "<c-f>" "Scroll forward" "function() if not require('noice.lsp').scroll(4) then return '<c-f>' end end")
          // {
            mode = ["i" "n" "s"];
            expr = true;
          })
        ((lua "<c-b>" "Scroll backward" "function() if not require('noice.lsp').scroll(-4) then return '<c-b>' end end")
          // {
            mode = ["i" "n" "s"];
            expr = true;
          })
        # Shows the output of the command being typed in a popup
        ((lua "<S-Enter>" "Redirect cmdline" "function() require('noice').redirect(vim.fn.getcmdline()) end") // {mode = "c";})

        # Todo comments
        (picker "<leader>st" "Todo" "todo_comments" "")
        (picker "<leader>sT" "Todo/Fix/Fixme" "todo_comments" "{ keywords = { 'TODO', 'FIX', 'FIXME' } }")
        (cmd "<leader>xT" "Todo/Fix/Fixme (Trouble)" "Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}")
        (lua "]t" "Next todo comment" "function() require('todo-comments').jump_next() end")
        (lua "[t" "Previous todo comment" "function() require('todo-comments').jump_prev() end")

        (lua "<leader>?" "Buffer keymaps (which-key)" "function() require('which-key').show({ global = false }) end")
        (lua "<c-w><space>" "Window hydra mode (which-key)" "function() require('which-key').show({ keys = '<c-w>', loop = true }) end")
      ];
    };
  }
