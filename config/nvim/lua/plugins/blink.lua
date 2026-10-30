-- AI completion via minuet, shown either as inline ghost text (Copilot style) or as an item in the blink menu.
-- <Leader>uG toggles ghost/menu, <Leader>uM toggles codestral/claude.
vim.g.ai_completion_mode = vim.g.ai_completion_mode or "ghost"

local function ghost_mode() return vim.g.ai_completion_mode == "ghost" end

local function apply_ghost_trigger(buffer) vim.b[buffer].minuet_virtual_text_auto_trigger = ghost_mode() end

return {
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.default = vim.list_extend(opts.sources.default or {}, { "minuet" })
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.minuet = {
        name = "minuet",
        module = "minuet.blink",
        enabled = function() return not ghost_mode() end,
        async = true,
        timeout_ms = 3000, -- matches minuet request_timeout
        score_offset = 1000,
      }
      -- avoid firing an AI request on every InsertEnter
      opts.completion = vim.tbl_deep_extend("force", opts.completion or {}, { trigger = { prefetch_on_insert = false } })
      -- ghost mode: menu above the cursor so it does not cover multi-line ghost text below
      opts.completion.menu = opts.completion.menu or {}
      opts.completion.menu.direction_priority = function() return ghost_mode() and { "n", "s" } or { "s", "n" } end
      -- VS Code rule: <Tab> accepts AI ghost text when shown, otherwise keeps its usual behaviour.
      -- In leading whitespace, a suggestion that itself starts with at least one indent level makes
      -- <Tab> indent towards it instead (VS Code: inlineSuggestionHasIndentationLessThanTabSize).
      opts.keymap = opts.keymap or {}
      table.insert(opts.keymap["<Tab>"] or {}, 1, function()
        local virtualtext = require("minuet.virtualtext")
        if not virtualtext.action.is_visible() then return end
        local text_before_cursor = vim.api.nvim_get_current_line():sub(1, vim.api.nvim_win_get_cursor(0)[2])
        if text_before_cursor:match("^%s*$") then
          local mark = vim.api.nvim_buf_get_extmarks(0, virtualtext.ns_id, 0, -1, { details = true })[1]
          local first_chunk = mark and mark[4].virt_text and mark[4].virt_text[1]
          local first_line = first_chunk and first_chunk[1] or ""
          if vim.fn.strdisplaywidth(first_line:match("^%s*")) >= vim.fn.shiftwidth() then return end
        end
        virtualtext.action.accept()
        return true
      end)
      -- VS Code style: <S-Tab> in insert mode unindents when no menu/snippet uses it (instead of inserting a tab)
      local shift_tab = opts.keymap["<S-Tab>"] or {}
      table.insert(shift_tab, #shift_tab, function()
        if vim.api.nvim_get_mode().mode == "i" then return vim.api.nvim_replace_termcodes("<C-d>", true, false, true) end
      end)
      -- copilot: re-enable when subscription is active
      opts.sources.providers.copilot = vim.tbl_extend("force", opts.sources.providers.copilot or {}, {
        enabled = false,
        score_offset = 1000,
      })
      return opts
    end,
  },
  {
    -- codestral: free, faster (CODESTRAL_API_KEY). claude: better, paid per request (ANTHROPIC_API_KEY)
    "milanglacier/minuet-ai.nvim",
    lazy = false, -- must be loaded before the first buffer's FileType event
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      {
        "<Leader>uM",
        function()
          local minuet = require("minuet")
          minuet.change_provider(minuet.config.provider == "codestral" and "claude" or "codestral")
        end,
        desc = "Toggle AI completion provider (codestral/claude)",
      },
      {
        "<Leader>uG",
        function()
          vim.g.ai_completion_mode = ghost_mode() and "menu" or "ghost"
          for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buffer) then apply_ghost_trigger(buffer) end
          end
          vim.notify("AI completion shown as: " .. vim.g.ai_completion_mode)
        end,
        desc = "Toggle AI completion display (ghost/menu)",
      },
    },
    opts = {
      provider = "codestral",
      provider_options = {
        -- haiku thinks by default and then returns no text block
        claude = { optional = { thinking = { type = "disabled" } } },
      },
      virtualtext = {
        show_on_completion_menu = true,
        -- accept is <Tab> (see blink keymap), dismiss is <Esc> (leaving insert mode clears it)
        -- <C-]> cycles alternatives (wraps around), or requests a suggestion if none is shown
        keymap = {
          next = "<C-]>",
        },
      },
    },
    config = function(_, opts)
      require("minuet").setup(opts)
      vim.api.nvim_create_autocmd("FileType", {
        desc = "Enable AI ghost text per buffer according to vim.g.ai_completion_mode",
        callback = function(event) apply_ghost_trigger(event.buf) end,
      })
    end,
  },
}
