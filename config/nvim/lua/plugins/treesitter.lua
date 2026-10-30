-- Customize Treesitter
-- --------------------
-- Treesitter customizations are handled with AstroCore
-- as nvim-treesitter simply provides a download utility for parsers.
-- Tree inspection is built in: :InspectTree, :Inspect

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      highlight = true,
      -- blade indent query ignores the HTML; indent/blade.lua uses Vim's HTML indent instead
      indent = function(lang) return lang ~= "blade" end,
      auto_install = true,
      ensure_installed = {
        "lua",
        "vim",
        "bash",
        "c",
        "javascript",
        "json",
        "php",
        "html",
        "python",
        "typescript",
        "css",
        "scss",
        "rust",
        "java",
        "yaml",
        "graphql",
        "blade",
        "pug",
      },
    },
  },
}
