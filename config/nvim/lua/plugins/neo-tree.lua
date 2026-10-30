-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

---@type LazySpec
return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
    { "MunifTanjim/nui.nvim", lazy = true },
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings
        -- maps.n["<Leader>e"] = { "<Cmd>Neotree toggle<CR>", desc = "Toggle Explorer" }
        maps.n["<Leader>e"] = {
          function()
            if vim.bo.filetype == "neo-tree" then
              -- vim.cmd.wincmd "p"
              vim.cmd.Neotree "close"
            else
              vim.cmd.Neotree "focus"
            end
          end,
          desc = "Toggle Explorer",
        }
        maps.n["<Leader>o"] = nil
      end,
    },
  },
  cmd = "Neotree",
  -- init = function()
  --   vim.api.nvim_create_autocmd('BufNewFile', {
  --     group = vim.api.nvim_create_augroup('RemoteFile', {clear = true}),
  --     callback = function()
  --       local f = vim.fn.expand('%:p')
  --       for _, v in ipairs{'sftp', 'scp', 'ssh', 'dav', 'fetch', 'ftp', 'http', 'rcp', 'rsync'} do
  --         local p = v .. '://'
  --         if string.sub(f, 1, #p) == p then
  --           -- vim.cmd[[
  --           --   unlet g:loaded_netrw
  --           --   unlet g:loaded_netrwPlugin
  --           --   runtime! plugin/netrwPlugin.vim
  --           --   silent Explore %
  --           -- ]]
  --
  --           vim.g.loaded_netrw = 0
  --           vim.g.loaded_netrwPlugin = 0
  --           -- vim.cmd("runtime! plugin/netrw.vim")
  --           vim.cmd("runtime! plugin/netrwPlugin.vim")
  --           -- vim.cmd("silent Explore %")
  --
  --           vim.api.nvim_clear_autocmds{group = 'RemoteFile'}
  --           break
  --         end
  --       end
  --     end
  --   })
  -- end,
  opts = function(plugin, opts)
    -- like the built-in next/prev_git_modified, but untracked files count as changed too
    local function focus_changed_file(state, step)
      local current_path = state.tree:get_node():get_id()
      local _, worktree = require("neo-tree.git").find_existing_worktree(current_path)
      if not worktree then return end

      local utils = require("neo-tree.utils")
      local paths = { current_path }
      for path, status in pairs(worktree.status) do
        local stat = vim.uv.fs_stat(path)
        if path ~= current_path and status ~= "!" and stat and stat.type == "file" and utils.is_subpath(state.path, path) then
          table.insert(paths, path)
        end
      end
      if #paths == 1 then return end

      local sorted_paths = utils.sort_by_tree_display(paths)
      local current_index = 1
      for index, path in ipairs(sorted_paths) do
        if path == current_path then current_index = index end
      end
      local target = sorted_paths[(current_index - 1 + step) % #sorted_paths + 1]
      if state.tree:get_node(target) then
        require("neo-tree.ui.renderer").focus_node(state, target)
      else
        require("neo-tree.sources.filesystem").navigate(state, state.path, target, nil, false)
      end
    end

    -- same keys as next/prev git hunk, but jumping between changed files
    opts.filesystem = opts.filesystem or {}
    opts.filesystem.commands = vim.tbl_extend("force", opts.filesystem.commands or {}, {
      next_changed_file = function(state) focus_changed_file(state, 1) end,
      prev_changed_file = function(state) focus_changed_file(state, -1) end,
    })
    opts.filesystem.window = opts.filesystem.window or {}
    opts.filesystem.window.mappings = vim.tbl_extend("force", opts.filesystem.window.mappings or {}, {
      ["<Leader>gj"] = "next_changed_file",
      ["<Leader>gk"] = "prev_changed_file",
    })

    table.insert(opts.event_handlers, {
      event = "file_opened",
      handler = function(file_path)
        -- auto close
        -- vimc.cmd("Neotree close")
        -- OR
        require("neo-tree.command").execute { action = "close" }
      end,
    })
  end,
}
