# Git and Jujutsu: signs, diffs, lazygit (Snacks), jjui, jj's diff editor, with LazyVim's keys
let
  inherit (import ../lib/keys.nix) cmd lua picker;
in
  {
    lib,
    pkgs,
    ...
  }: {
    vim = {
      # On PATH so <leader>gg/gG (lazygit) and <leader>gj (jjui) work from `nix run` too, without the NixOS config's packages
      extraPackages = [pkgs.lazygit pkgs.jjui];

      git = {
        enable = true;
        gitsigns = {
          enable = true;
          codeActions.enable = false; # prints debug messages
          # LazyVim's signs (thin bars) and keys, set per buffer when gitsigns attaches; nvf's own keys are off
          mappings = {
            nextHunk = null;
            previousHunk = null;
            stageHunk = null;
            undoStageHunk = null;
            resetHunk = null;
            stageBuffer = null;
            resetBuffer = null;
            previewHunk = null;
            blameLine = null;
            diffThis = null;
            toggleBlame = null;
            toggleDeleted = null;
            diffProject = null;
          };
          setupOpts = {
            signs = {
              add.text = "▎";
              change.text = "▎";
              delete.text = "";
              topdelete.text = "";
              changedelete.text = "▎";
              untracked.text = "▎";
            };
            signs_staged = {
              add.text = "▎";
              change.text = "▎";
              delete.text = "";
              topdelete.text = "";
              changedelete.text = "▎";
            };
            on_attach = lib.generators.mkLuaInline ''
              function(buffer)
                local gs = package.loaded.gitsigns
                local function map(mode, l, r, desc)
                  vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc, silent = true })
                end
                map("n", "]h", function()
                  if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end
                end, "Next Hunk")
                map("n", "[h", function()
                  if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end
                end, "Prev Hunk")
                map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
                map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")
                map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
                map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
                map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
                map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
                map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
                map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
                map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
                map("n", "<leader>ghB", function() gs.blame() end, "Blame Buffer")
                map("n", "<leader>ghd", gs.diffthis, "Diff This")
                map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
                map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
                map("n", "<leader>uB", gs.toggle_current_line_blame, "Toggle line blame")
              end
            '';
          };
        };
        # Conflict choices off <leader>c… (LazyVim's code group); nvf's defaults also had ]x/[x swapped
        git-conflict.mappings = {
          ours = "<leader>gxo";
          theirs = "<leader>gxt";
          both = "<leader>gxb";
          none = "<leader>gx0";
          nextConflict = "]x";
          prevConflict = "[x";
        };
        # :DiffEditor, jj's diff editor (set as ui.diff-editor in the NixOS config) for jj split / squash -i
        hunk-nvim.enable = true;
      };
      utility.diffview-nvim.enable = true;
      keymaps = [
        # Git and GitHub pickers (Snacks), as in LazyVim; the GitHub ones use the gh CLI (installed by the NixOS config)
        (picker "<leader>fg" "Find files (git-files)" "git_files" "")
        (picker "<leader>gs" "Git status" "git_status" "")
        (picker "<leader>gS" "Git stash" "git_stash" "")
        (picker "<leader>gl" "Git log" "git_log" "{ cwd = ProjectRoot() }")
        (picker "<leader>gL" "Git log (cwd)" "git_log" "")
        (picker "<leader>gf" "Git current file history" "git_log_file" "")
        (picker "<leader>gd" "Git diff (hunks)" "git_diff" "")
        (picker "<leader>gD" "Git diff (origin)" "git_diff" "{ base = 'origin', group = true }")
        (picker "<leader>gi" "GitHub issues (open)" "gh_issue" "")
        (picker "<leader>gI" "GitHub issues (all)" "gh_issue" "{ state = 'all' }")
        (picker "<leader>gp" "GitHub pull requests (open)" "gh_pr" "")
        (picker "<leader>gP" "GitHub pull requests (all)" "gh_pr" "{ state = 'all' }")
        (cmd "<leader>gv" "Diffview" "DiffviewOpen")

        (picker "<leader>gb" "Git blame line" "git_log_line" "")

        # Lazygit through Snacks, as in LazyVim: it gets the colorscheme's colors, and `e` on a file opens it in this
        # Neovim instead of a second one inside the float. At the repo root, or at Neovim's current directory.
        (lua "<leader>gg" "Lazygit (repo root)" "function() Snacks.lazygit({ cwd = ProjectRoot() }) end")
        (lua "<leader>gG" "Lazygit (cwd)" "function() Snacks.lazygit() end")
        # jjui in a floating Snacks terminal at the repo root; quitting it closes the float
        (lua "<leader>gj" "jjui (repo root)" "function() Snacks.terminal('jjui', { cwd = ProjectRoot(), win = { position = 'float' } }) end")
      ];

      # :J runs jj commands
      lazy.plugins."jj.nvim" = {
        package = pkgs.vimPlugins.jj-nvim;
        setupModule = "jj";
        setupOpts = {};
        cmd = ["J"];
      };
    };
  }
