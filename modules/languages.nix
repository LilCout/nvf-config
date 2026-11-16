# Language support: LSP, Treesitter, formatter, linters and debugger per language
let
  inherit (import ../lib/keys.nix) cmd lua;
  # Jumps to the next (1) or previous (-1) diagnostic of one severity and shows it in a float (on_jump: jump's `float`
  # option is deprecated since Neovim 0.12)
  diagnosticJump = count: severity: "function() vim.diagnostic.jump({ count = ${toString count}, severity = ${severity}, on_jump = function(_, bufnr) vim.diagnostic.open_float({ bufnr = bufnr, scope = 'cursor', focus = false }) end }) end";
in
  {
    lib,
    pkgs,
    ...
  }: {
    vim = {
      extraPackages = with pkgs; [
        # rust-analyzer's root detection runs rustc and errors without it; projects' own toolchains come first via direnv
        rustc
        cargo
      ];

      # LazyVim's diagnostics: the message at the end of the line (Neovim shows none by default since 0.11), most severe
      # first, and icons in the sign column
      diagnostics = {
        enable = true;
        config = {
          underline = true;
          update_in_insert = false;
          virtual_text = {
            spacing = 4;
            source = "if_many";
            prefix = "●";
          };
          severity_sort = true;
          signs.text = lib.generators.mkLuaInline ''
            {
              [vim.diagnostic.severity.ERROR] = " ",
              [vim.diagnostic.severity.WARN] = " ",
              [vim.diagnostic.severity.HINT] = " ",
              [vim.diagnostic.severity.INFO] = " ",
            }
          '';
        };
      };

      lsp = {
        enable = true;
        formatOnSave = false; # format by hand with <leader>cf; <leader>uf turns on-save formatting on for the session
        inlayHints.enable = true; # types and parameter names inline; <leader>uh toggles them (ui.nix)

        # nvf's <leader>l… LSP keys moved to LazyVim's <leader>c… ones; null where Neovim's or LazyVim's own key covers it
        # (gd/gD/gr/gI/gy below, K hover, ]d/[d diagnostics, <leader>ss/sS symbols in navigation.nix)
        mappings = {
          codeAction = "<leader>ca";
          renameSymbol = "<leader>cr";
          format = "<leader>cf";
          openDiagnosticFloat = "<leader>cd";
          signatureHelp = "gK";
          toggleFormatOnSave = "<leader>uf";
          addWorkspaceFolder = "<leader>cwa";
          removeWorkspaceFolder = "<leader>cwr";
          listWorkspaceFolders = "<leader>cwl";
          goToDefinition = null;
          goToDeclaration = null;
          goToType = null;
          listImplementations = null;
          listReferences = null;
          nextDiagnostic = null;
          previousDiagnostic = null;
          documentHighlight = null;
          listDocumentSymbols = null;
          listWorkspaceSymbols = null;
          hover = null;
        };

        trouble = {
          enable = true;
          # LSP results (definitions, references, …) open on the right
          setupOpts.modes.lsp.win.position = "right";
          mappings = {
            workspaceDiagnostics = "<leader>xx";
            documentDiagnostics = "<leader>xX";
            symbols = "<leader>cs";
            lspReferences = null; # <leader>cS below, Trouble's combined LSP view
            locList = "<leader>xL";
            quickfix = "<leader>xQ";
          };
        };

        # <leader>cO: LSP for code embedded in other files, e.g. a Nix string marked with a /* bash */ or /* lua */ comment.
        # Only for complete scripts: the Lua snippets in nvf's keymaps aren't valid Lua on their own and show false errors.
        otter-nvim = {
          enable = true;
          mappings.toggle = "<leader>cO";
        };
      };
      languages = {
        enableFormat = true;
        enableTreesitter = true;
        enableExtraDiagnostics = true;
        enableDAP = true;

        nix = {
          enable = true;
          lsp.servers = ["nixd"];
        };
        bash.enable = true;
        fish.enable = true; # the login shell
        lua = {
          enable = true;
          # Neovim's Lua API (the `vim` global) for lua-language-server
          extensions.lazydev.enable = true;
        };
        markdown = {
          enable = true;
          extensions.render-markdown-nvim = {
            enable = true; # headings, lists, tables and code blocks rendered in the buffer; <leader>um toggles
            setupOpts = {
              code = {
                sign = false;
                width = "block";
                right_pad = 1;
              };
              heading = {
                sign = false;
                icons = [];
              };
              checkbox.enabled = false;
            };
          };
        };
        python = {
          enable = true;
          lsp.servers = ["basedpyright" "ruff"];
          format.type = ["ruff"];
        };
        rust = {
          enable = true;
          extensions.crates-nvim.enable = true;
        };
        clang.enable = true;
        docker.enable = true;
        # Bundles all of Julia, since its language server is a Julia package
        julia.enable = true;
        tex.enable = true;
        typst.enable = true; # includes typst-preview.nvim (<leader>cp below)
        typescript.enable = true;
        html.enable = true;
        css.enable = true;
        json.enable = true;
        yaml.enable = true;
        toml.enable = true;
      };

      lsp.servers = {
        # LazyVim's lua_ls settings: inlay hints for parameter types (not names), call snippets, no third-party prompts
        lua-language-server.settings.Lua = {
          workspace.checkThirdParty = false;
          codeLens.enable = true;
          completion.callSnippet = "Replace";
          doc.privateName = ["^_"];
          hint = {
            enable = true;
            setType = false;
            paramType = true;
            paramName = "Disable";
            semicolon = "Disable";
            arrayIndex = "Disable";
          };
        };

        # The NixOS config adds its own option completion (NixOS, Home Manager, flake-parts) through mkNeovim's `modules`.
        # Store path, so formatting also works from `nix run` without alejandra on PATH.
        nixd.settings.nixd.formatting.command = [(lib.getExe pkgs.alejandra)];

        # nvf's Julia server command broke with LanguageServer.jl 6: it passes the depot path as a 4th argument
        # (now the error handler) and sets the removed `runlinter` field, so the server crashed on start.
        julia-languageserver.cmd = lib.mkForce (lib.generators.mkLuaInline ''
          {
            '${lib.getExe (pkgs.julia.withPackages ["LanguageServer"])}',
            '--startup-file=no',
            '--history-file=no',
            '-e',
            [[
              using LanguageServer
              project_path = dirname(something(
                  Base.load_path_expand((p = get(ENV, "JULIA_PROJECT", nothing);
                      p === nothing || isempty(p) ? nothing : p)),
                  Base.current_project(),
                  get(Base.load_path(), 1, nothing),
                  Base.load_path_expand("@v#.#"),
              ))
              server = LanguageServer.LanguageServerInstance(stdin, stdout, project_path)
              run(server)
            ]],
          }
        '');
      };

      treesitter = {
        # Git files (commit messages, rebase todo, config, ignore), which no language module covers
        grammars = with pkgs.vimPlugins.nvim-treesitter.grammarPlugins; [
          gitcommit
          git_rebase
          git_config
          gitignore
          gitattributes
          diff
        ];
      };

      debugger.nvim-dap = {
        enable = true;
        ui.enable = true;
        # LazyVim's keys (nvf's dg…/dv… prefixes would make <leader>dg wait)
        mappings = {
          continue = "<leader>dc";
          toggleBreakpoint = "<leader>db";
          runToCursor = "<leader>dC";
          stepInto = "<leader>di";
          stepOut = "<leader>do";
          stepOver = "<leader>dO";
          goDown = "<leader>dj";
          goUp = "<leader>dk";
          runLast = "<leader>dl";
          toggleRepl = "<leader>dr";
          terminate = "<leader>dt";
          hover = "<leader>dw";
          toggleDapUI = "<leader>du";
          restart = "<leader>dR";
          stepBack = null;
        };
      };
      # LazyVim's debugger look: its breakpoint and stopped-line icons, the stopped line highlighted, and variable values
      # shown inline while debugging (nvim-dap-virtual-text)
      extraPlugins.nvim-dap-virtual-text = {
        package = pkgs.vimPlugins.nvim-dap-virtual-text;
        setup = ''
          require("nvim-dap-virtual-text").setup({})
          vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
          for name, sign in pairs(LazyVimIcons.dap) do
            sign = type(sign) == "table" and sign or { sign }
            vim.fn.sign_define("Dap" .. name, { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] })
          end
        '';
      };

      # Loads devenv/direnv environments, so project LSPs and tools are found
      utility.direnv.enable = true;

      # Browser preview of Markdown (Typst's comes with its language module); <leader>cp in those buffers only
      utility.preview.markdownPreview.enable = true;
      autocmds = [
        {
          event = ["FileType"];
          pattern = ["markdown"];
          desc = "Markdown preview key";
          callback = lib.generators.mkLuaInline ''
            function(event)
              vim.keymap.set("n", "<leader>cp", "<cmd>MarkdownPreviewToggle<cr>", { buffer = event.buf, desc = "Markdown preview" })
            end
          '';
        }
        {
          event = ["FileType"];
          pattern = ["typst"];
          desc = "Typst preview key";
          callback = lib.generators.mkLuaInline ''
            function(event)
              vim.keymap.set("n", "<leader>cp", "<cmd>TypstPreviewToggle<cr>", { buffer = event.buf, desc = "Typst preview" })
            end
          '';
        }
      ];

      keymaps = [
        # Code
        # nvf maps <leader>ca in normal mode only; LazyVim also runs it on a selection
        ((lua "<leader>ca" "Code action" "vim.lsp.buf.code_action") // {mode = "x";})
        (lua "<leader>cl" "LSP info" "function() Snacks.picker.lsp_config() end")
        (cmd "<leader>cS" "LSP references/definitions/... (Trouble)" "Trouble lsp toggle")
        ((lua "<leader>cc" "Run codelens" "vim.lsp.codelens.run") // {mode = ["n" "x"];})
        (lua "<leader>cC" "Refresh & display codelens" "function() vim.lsp.codelens.enable(true, { bufnr = 0 }) end")
        (lua "<leader>cA" "Source action" "function() vim.lsp.buf.code_action({ context = { only = { 'source' }, diagnostics = {} } }) end")
        (lua "<leader>co" "Organize imports" "function() vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' }, diagnostics = {} }, apply = true }) end")
        (lua "gai" "Calls incoming" "function() Snacks.picker.lsp_incoming_calls() end")
        (lua "gao" "Calls outgoing" "function() Snacks.picker.lsp_outgoing_calls() end")
        {
          key = "<C-k>";
          mode = "i";
          desc = "Signature help";
          lua = true;
          action = "vim.lsp.buf.signature_help";
        }
        # Next/previous use of the word under the cursor (Snacks words)
        (lua "]]" "Next reference" "function() Snacks.words.jump(vim.v.count1) end")
        (lua "[[" "Previous reference" "function() Snacks.words.jump(-vim.v.count1) end")
        (lua "<A-n>" "Next reference" "function() Snacks.words.jump(vim.v.count1, true) end")
        (lua "<A-p>" "Previous reference" "function() Snacks.words.jump(-vim.v.count1, true) end")

        # Diagnostics (]d/[d are Neovim's own)
        (lua "]e" "Next error" (diagnosticJump 1 "vim.diagnostic.severity.ERROR"))
        (lua "[e" "Previous error" (diagnosticJump (-1) "vim.diagnostic.severity.ERROR"))
        (lua "]w" "Next warning" (diagnosticJump 1 "vim.diagnostic.severity.WARN"))
        (lua "[w" "Previous warning" (diagnosticJump (-1) "vim.diagnostic.severity.WARN"))
        # Open or close the location/quickfix list
        (lua "<leader>xl" "Location list" "function() local ok, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen) if not ok and err then vim.notify(err, vim.log.levels.ERROR) end end")
        (lua "<leader>xq" "Quickfix list" "function() local ok, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen) if not ok and err then vim.notify(err, vim.log.levels.ERROR) end end")
        # Previous/next item in Trouble when it's open, else in the quickfix list
        (lua "[q" "Previous trouble/quickfix item" "function() if require('trouble').is_open() then require('trouble').prev({ skip_groups = true, jump = true }) else local ok, err = pcall(vim.cmd.cprev) if not ok then vim.notify(err, vim.log.levels.ERROR) end end end")
        (lua "]q" "Next trouble/quickfix item" "function() if require('trouble').is_open() then require('trouble').next({ skip_groups = true, jump = true }) else local ok, err = pcall(vim.cmd.cnext) if not ok then vim.notify(err, vim.log.levels.ERROR) end end end")

        # Debugger, the keys nvf has no option for
        (lua "<leader>dB" "Breakpoint condition" "function() require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: ')) end")
        (lua "<leader>da" "Run with args" ''
          function()
            require("dap").continue({
              before = function(config)
                local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
                local args_str = type(args) == "table" and table.concat(args, " ") or args
                config = vim.deepcopy(config)
                config.args = function()
                  local new_args = vim.fn.expand(vim.fn.input("Run with args: ", args_str))
                  return require("dap.utils").splitstr(new_args)
                end
                return config
              end,
            })
          end
        '')
        (lua "<leader>dg" "Go to line (no execute)" "function() require('dap').goto_() end")
        (lua "<leader>dP" "Pause" "function() require('dap').pause() end")
        (lua "<leader>ds" "Session" "function() require('dap').session() end")
        ((lua "<leader>de" "Eval" "function() require('dapui').eval() end") // {mode = ["n" "x"];})

        # LazyVim's LSP jumps (Snacks pickers); gd/gD fall back to Vim's own in buffers without a language server
        {
          key = "gd";
          mode = "n";
          desc = "Go to definition";
          lua = true;
          action = "function() if next(vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/definition' })) then Snacks.picker.lsp_definitions() else vim.cmd('normal! gd') end end";
        }
        {
          key = "gD";
          mode = "n";
          desc = "Go to declaration";
          lua = true;
          action = "function() if next(vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/declaration' })) then vim.lsp.buf.declaration() else vim.cmd('normal! gD') end end";
        }
        # Replaces Neovim's gr* prefix (grn, gra, gri, …), as in LazyVim; those are <leader>cr, <leader>ca, gI
        {
          key = "gr";
          mode = "n";
          desc = "References";
          nowait = true;
          lua = true;
          action = "function() Snacks.picker.lsp_references() end";
        }
        {
          key = "gI";
          mode = "n";
          desc = "Go to implementation";
          lua = true;
          action = "function() Snacks.picker.lsp_implementations() end";
        }
        {
          key = "gy";
          mode = "n";
          desc = "Go to type definition";
          lua = true;
          action = "function() Snacks.picker.lsp_type_definitions() end";
        }
      ];
    };
  }
