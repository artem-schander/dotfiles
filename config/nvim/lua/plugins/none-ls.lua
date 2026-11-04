-- Customize None-ls sources

-- Sheath is a per-project dev dependency: composer require fortephp/sheath --dev
local function has_sheath(bufname)
  local root = vim.fs.root(bufname, "artisan")
  return root ~= nil and vim.uv.fs_stat(root .. "/vendor/fortephp/sheath") ~= nil
end

---@type LazySpec
return {
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
      -- opts variable is the default configuration table for the setup function call
      local null_ls = require "null-ls"

      -- Check supported formatters and linters
      -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/formatting
      -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics

      -- Only insert new sources, do not replace the existing ones
      -- (If you wish to replace, use `opts.sources = {}` instead of the `list_insert_unique` function)
      opts.sources = require("astrocore").list_insert_unique(opts.sources, {
        -- HTML checks (duplicate attributes, invalid nesting, ...) in HTML and Blade;
        -- markuplint/blade-parser.mjs masks the Blade syntax, the config allows Alpine/Livewire attributes
        null_ls.builtins.diagnostics.markuplint.with {
          filetypes = { "html", "blade" },
          extra_args = { "--config", vim.fn.stdpath "config" .. "/markuplint/markuplint.json" },
          -- the builtin reports a zero-width range (invisible far right on long lines);
          -- span the reported source text instead, e.g. the duplicated attribute name
          on_output = function(params)
            local diagnostics = {}
            -- Sheath reports duplicate attributes too
            local skip_duplicates = has_sheath(params.bufname)
            for _, message in ipairs(params.output or {}) do
              if not (skip_duplicates and message.ruleId == "no-duplicate-attr") then
                table.insert(diagnostics, {
                  row = message.line,
                  col = message.col,
                  end_col = message.col + #(message.raw or ""):match "[^\n]*",
                  source = "markuplint",
                  code = message.ruleId,
                  message = message.message,
                  severity = message.severity == "error" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
                })
              end
            end
            return diagnostics
          end,
        },
        -- Blade-aware linting (a11y, Blade, Alpine/Livewire directives, duplicate attributes, ...)
        require("null-ls.helpers").make_builtin {
          name = "sheath",
          method = null_ls.methods.DIAGNOSTICS,
          filetypes = { "blade" },
          generator_opts = {
            command = "php",
            args = { "artisan", "sheath:lint", "--stdin", "--stdin-filename", "$FILENAME", "--format=json" },
            to_stdin = true,
            format = "json",
            ignore_stderr = true,
            -- exits non-zero when it finds problems
            check_exit_code = function() return true end,
            cwd = function(params) return vim.fs.root(params.bufname, "artisan") end,
            runtime_condition = function(params) return has_sheath(params.bufname) end,
            on_output = function(params)
              local severities = {
                error = vim.diagnostic.severity.ERROR,
                warning = vim.diagnostic.severity.WARN,
                info = vim.diagnostic.severity.INFO,
              }
              local diagnostics = {}
              for _, result in ipairs(params.output and params.output.results or {}) do
                for _, violation in ipairs(result.violations or {}) do
                  table.insert(diagnostics, {
                    row = violation.line,
                    col = violation.column,
                    end_row = violation.endLine,
                    end_col = violation.endColumn,
                    source = "sheath",
                    code = violation.ruleId,
                    message = violation.message,
                    severity = severities[violation.severity],
                  })
                end
              end
              return diagnostics
            end,
          },
          factory = require("null-ls.helpers").generator_factory,
        },
      })
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, { "markuplint" })
    end,
  },
}
