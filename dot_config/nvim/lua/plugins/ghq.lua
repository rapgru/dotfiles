return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>fP",
        function()
          local root = vim.fn.system("ghq root"):gsub("\n", "")
          Snacks.picker({
            title = "ghq",
            finder = "proc",
            cmd = "ghq",
            args = { "list" },
            format = "text",
            preview = "none",
            transform = function(item)
              item.file = root .. "/" .. item.text
            end,
            confirm = function(picker, item)
              picker:close()
              if item then
                vim.cmd("cd " .. item.file)
                vim.notify("cd → " .. item.file)
              end
            end,
          })
        end,
        desc = "Projects (ghq)",
      },
    },
  },
}
