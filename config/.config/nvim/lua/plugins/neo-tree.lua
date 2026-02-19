return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = function(_, opts)
      opts.sources = { "filesystem", "buffers", "git_status", "document_symbols" }
      opts.document_symbols = {
        follow_cursor = true,
      }
      opts.source_selector = vim.tbl_deep_extend("force", opts.source_selector or {}, {
        winbar = true, -- 또는 statusline = true
        sources = {
          { source = "filesystem" },
          { source = "buffers" },
          { source = "git_status" },
          { source = "document_symbols" },
        },
      })

      local ok_utils, utils = pcall(require, "neo-tree.utils")
      local ok_ls, ls_files = pcall(require, "neo-tree.git.ls-files")
      if ok_utils and ok_ls and not ls_files._home_gitignore_patched then
        local home = utils.normalize_path(vim.fn.expand("~"))
        local uv = vim.uv or vim.loop
        local home_git_marker = utils.path_join(home, ".git")
        local home_has_git = uv.fs_stat(home_git_marker) ~= nil
        if not home_has_git then
          return opts
        end

        local original_ignored = ls_files.ignored
        local original_ignored_job = ls_files.ignored_job

        ls_files.ignored = function(worktree_root)
          local normalized_root = utils.normalize_path(worktree_root)
          if normalized_root == home then
            return {}
          end
          return original_ignored(worktree_root)
        end

        ls_files.ignored_job = function(context, on_parsed)
          local normalized_root = utils.normalize_path(context.worktree_root)
          if normalized_root == home then
            on_parsed({})
            return
          end
          return original_ignored_job(context, on_parsed)
        end

        ls_files._home_gitignore_patched = true
      end

      return opts
    end,
  },
}
