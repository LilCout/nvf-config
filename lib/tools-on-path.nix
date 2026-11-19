# The light package's tools: given the evaluated configuration, an nvf module that turns every language server,
# formatter, linter and debugger command from a store path into its bare name, looked up on PATH at runtime (a
# project's dev shell through direnv, or the system), so the tools aren't part of the package. Generic over whatever the
# language modules enable, so arguments and settings stay nvf's own.
lib: config: let
  inherit (builtins) isAttrs isList isString split storeDir unsafeDiscardStringContext;

  # A string with each /nix/store/<hash>-<name>/bin/ prefix removed, and without those store paths as dependencies.
  # A store path left over (a library, a data file) can't be found on PATH: such a value stays bundled, with a warning
  # to override it in languages.nix's light-only settings (as for codelldb's liblldb).
  strip = s: let
    stripped = unsafeDiscardStringContext (lib.concatStrings (lib.filter isString (split "${storeDir}/[a-z0-9]{32}-[^/]*/bin/" s)));
  in
    if lib.hasInfix storeDir stripped
    then lib.warn "nvf-config: stays bundled, its store path isn't a command: ${stripped}" s
    else stripped;

  hasStorePath = v:
    if isString v
    then lib.hasInfix storeDir v
    else if isList v
    then lib.any hasStorePath v
    else if isAttrs v && !lib.isDerivation v
    then lib.any hasStorePath (lib.attrValues v)
    else false;

  # Lua code ({_type = "lua-inline"; expr}) is rewritten like any other attribute set
  rewrite = v:
    if isString v
    then strip v
    else if isList v
    then map rewrite v
    else if isAttrs v && !lib.isDerivation v
    then lib.mapAttrs (_: rewrite) v
    else v;

  # mkForce overrides for just the values naming a store path, recursing into attribute sets (servers' submodules,
  # settings); lists and Lua code are replaced whole. Leaving the rest alone keeps other modules' definitions merging.
  overrides = lib.concatMapAttrs (name: v:
    if !hasStorePath v
    then {}
    else if isAttrs v && !(v ? _type)
    then {${name} = overrides v;}
    else {${name} = lib.mkForce (rewrite v);});

  inherit (config) vim;
in {
  vim = {
    lsp.servers = overrides vim.lsp.servers;
    formatter.conform-nvim.setupOpts.formatters = overrides (vim.formatter.conform-nvim.setupOpts.formatters or {});
    diagnostics.nvim-lint.linters = overrides vim.diagnostics.nvim-lint.linters;
    debugger.nvim-dap.adapters = overrides vim.debugger.nvim-dap.adapters;
    # typst-preview.nvim's tinymist and websocat
    languages.typst.extensions.typst-preview-nvim.setupOpts = overrides vim.languages.typst.extensions.typst-preview-nvim.setupOpts;
  };
}
