-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- AstroCommunity: import any community modules here
-- We import this file in `lazy_setup.lua` before the `plugins/` folder.
-- This guarantees that the specs are processed before any user plugins.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",
  -- { import = "astrocommunity.pack.lua" },
  -- import/override with your plugins folder
  -- available plugins can be found at https://github.com/AstroNvim/astrocommunity
  { import = "astrocommunity.colorscheme.catppuccin" },
  { import = "astrocommunity.colorscheme.tokyonight-nvim" },
  { import = "astrocommunity.colorscheme.tokyodark-nvim" },
  { import = "astrocommunity.colorscheme.kanagawa-nvim" },
  { import = "astrocommunity.colorscheme.kanagawa-paper-nvim" },
  { import = "astrocommunity.colorscheme.rose-pine" },
  { import = "astrocommunity.colorscheme.oldworld-nvim" },
  { import = "astrocommunity.colorscheme.onedarkpro-nvim" },

  { import = "astrocommunity.colorscheme.github-nvim-theme" },

  { import = "astrocommunity.completion.copilot-cmp" },
  -- { import = "astrocommunity.pack.laravel" }, -- pulls phpactor (dup of intelephense) + pint on save
  { import = "astrocommunity.pack.blade" },
  { import = "astrocommunity.pack.vue" },

  -- Python: basedpyright + ruff (lint/format), debugpy, neotest-python, venv-selector (<Leader>lv)
  { import = "astrocommunity.pack.python.base" },
  { import = "astrocommunity.pack.python.basedpyright" },
  { import = "astrocommunity.pack.python.ruff" },

  -- Live markdown preview in the browser (renders mermaid diagrams natively).
  -- Keymaps: <Leader>Mp preview, <Leader>Ms stop, <Leader>Mt toggle.
  { import = "astrocommunity.markdown-and-latex.markdown-preview-nvim" },
  -- the community build calls mkdp#util#install, which isn't on the rtp yet at build time (E117),
  -- so the server binary never gets downloaded; run the plugin's installer directly instead
  { "iamcco/markdown-preview.nvim", build = "cd app && ./install.sh" },
}
