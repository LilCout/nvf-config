# Git and Jujutsu: signs, diffs, lazygit, jjui, jj's diff editor, with LazyVim's keys
let
  inherit (import ../lib/keys.nix) cmd lua picker;
in
  {pkgs, ...}: {
    vim = {
      # On PATH so <leader>gj (jjui) works from `nix run` too, without the NixOS config's packages
      extraPackages = [pkgs.lazygit pkgs.jjui];

      git = {
        enable = true;
        gitsigns = {
          enable = true;
          codeActions.enable = false; # prints debug messages
          # nvf's <leader>h… keys moved to LazyVim's <leader>gh… and ]h/[h
          mappings = {
            nextHunk = "]h";
            previousHunk = "[h";
            stageHunk = "<leader>ghs";
            undoStageHunk = "<leader>ghu";
            resetHunk = "<leader>ghr";
            stageBuffer = "<leader>ghS";
            resetBuffer = "<leader>ghR";
            previewHunk = "<leader>ghp";
            blameLine = "<leader>ghb";
            diffThis = "<leader>ghd";
            toggleBlame = "<leader>uB";
            toggleDeleted = null;
            diffProject = null;
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
      terminal.toggleterm.lazygit.enable = true; # <leader>gg

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

        (lua "<leader>gb" "Git blame line" "function() require('gitsigns').blame_line({ full = true }) end")
        (cmd "<leader>ghB" "Blame buffer" "Gitsigns blame")
        (lua "<leader>ghD" "Diff this ~" "function() require('gitsigns').diffthis('~') end")
        (lua "]H" "Last hunk" "function() require('gitsigns').nav_hunk('last') end")
        (lua "[H" "First hunk" "function() require('gitsigns').nav_hunk('first') end")

        (lua "<leader>gj" "jjui (repo root)" ''
          function()
            require("toggleterm.terminal").Terminal:new({
              cmd = "jjui",
              dir = ProjectRoot(),
              direction = "float",
              close_on_exit = true,
              on_open = function() vim.cmd("startinsert!") end,
            }):toggle()
          end
        '')
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
