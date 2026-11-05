-- Blade / Livewire / Alpine support.
-- Filetype, blade parser and blade-formatter come from astrocommunity.pack.blade (community.lua).

---@type LazySpec
return {
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      -- php_only: PHP inside {{ }} and @directives
      treesitter = { ensure_installed = { "blade", "php_only", "html", "javascript" } },
    },
  },
  -- gf + completion for <x-component>, <livewire:name>, @include, route(), view(), config(), __()
  {
    "ricardoramirezr/blade-nav.nvim",
    ft = { "blade", "php" },
    opts = {},
  },
  -- wire: directive/modifier completion, warnings for wire: typos and unknown component members, gd to components/members
  {
    "fistbumpfromdestiny/livewire.nvim",
    ft = "blade",
    opts = {
      -- laravel_lsp already resolves <x-…> components, avoid a duplicate gd answer
      definition = { blade_components = false },
    },
  },
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.sources.providers["blade-nav"] = { name = "blade-nav", module = "blade-nav.integrations.blink" }
      -- rank Livewire items above buffer words and snippets
      opts.sources.providers.livewire = { name = "Livewire", module = "livewire.blink", score_offset = 100 }
      opts.sources.per_filetype = opts.sources.per_filetype or {}
      opts.sources.per_filetype.blade = { "blade-nav", "livewire", inherit_defaults = true }
      opts.sources.per_filetype.php = { "blade-nav", inherit_defaults = true }
      return opts
    end,
  },
}
