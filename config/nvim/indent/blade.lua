-- nvim-treesitter's blade indent query only knows directives and ignores the HTML (disabled in
-- lua/plugins/treesitter.lua). Use Vim's HTML indent and indent blade block directives on top of it.
vim.cmd "runtime! indent/html.vim"

-- directives that open a block closed by @end<name> (or continued by @else/@elseif/@empty)
local block_directives = {
  "if", "elseif", "else", "unless", "isset", "empty", "auth", "guest", "env", "production",
  "foreach", "forelse", "for", "while", "switch", "case", "default", "section", "push", "prepend",
  "once", "verbatim", "component", "slot", "error", "can", "cannot", "canany", "fragment", "session",
}

local function opens_block(line)
  local directive = line:match("^%s*@(%a+)")
  if not directive or not vim.tbl_contains(block_directives, directive) then
    -- @php opens a block only without arguments, @php($x = 1) is inline
    return line:match("^%s*@php%s*$") ~= nil
  end
  -- one-liners like @if(...)...@endif and @section('title', 'Text') do not open a block
  return not line:find("@end") and not line:match("^%s*@section%s*%(.*,")
end

local function closes_block(line)
  return line:match("^%s*@end") or line:match("^%s*@else") or line:match("^%s*@empty%s*$")
end

function _G.blade_indent()
  local indent = vim.fn.HtmlIndent()
  local previous = vim.fn.getline(vim.fn.prevnonblank(vim.v.lnum - 1))
  if opens_block(previous) then indent = indent + vim.fn.shiftwidth() end
  if closes_block(vim.fn.getline(vim.v.lnum)) then indent = indent - vim.fn.shiftwidth() end
  return math.max(indent, 0)
end

vim.bo.indentexpr = "v:lua.blade_indent()"
vim.bo.indentkeys = vim.bo.indentkeys .. ",0=@end,0=@else,0=@empty"
