return {
  {
    "Saghen/blink.cmp",
    dependencies = {
      "supermaven-inc/supermaven-nvim",
    },
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.default = vim.list_extend(opts.sources.default or {}, { "supermaven" })
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.supermaven = {
        name = "supermaven",
        module = "blink.compat.source",
        score_offset = 1000,
        async = true,
      }
      -- copilot: re-enable when subscription is active
      opts.sources.providers.copilot = vim.tbl_extend("force", opts.sources.providers.copilot or {}, {
        enabled = false,
        score_offset = 1000,
      })
      return opts
    end,
  },
  {
    "supermaven-inc/supermaven-nvim",
    opts = {
      disable_inline_completion = true,
      disable_keymaps = true,
    },
  },
}
