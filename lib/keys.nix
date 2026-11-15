# Keymap constructors for the files in this folder (`import ./_keys.nix`); the leading _ keeps import-tree from loading it
# as a module. All make normal-mode maps; add `// {mode = [...];}` for other modes.
rec {
  # Runs an Ex command
  cmd = key: desc: command: {
    inherit key desc;
    mode = "n";
    action = "<cmd>${command}<cr>";
  };
  # Runs a Lua function (given as Lua source)
  lua = key: desc: action: {
    inherit key desc action;
    mode = "n";
    lua = true;
  };
  # Opens a Snacks picker (snacks.nix), with its options as a Lua table ("" for none)
  picker = key: desc: name: opts: lua key desc "function() Snacks.picker.${name}(${opts}) end";
}
