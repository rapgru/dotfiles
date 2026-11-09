-- ~/.config/nvim/lua/plugins/gitlab.lua
return {
  {
    "harrisoncramer/gitlab.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "stevearc/dressing.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    ---@type GitlabSettings
    opts = {},
    keys = {
      -- Group label
      { "<leader>gl", "", desc = "+GitLab" },

      -- MR workflow
      {
        "<leader>glM",
        function()
          require("gitlab").choose_merge_request()
        end,
        desc = "Choose MR",
      },
      {
        "<leader>glC",
        function()
          require("gitlab").create_mr()
        end,
        desc = "Create MR",
      },
      {
        "<leader>glr",
        function()
          require("gitlab").review()
        end,
        desc = "Review",
      },
      {
        "<leader>gls",
        function()
          require("gitlab").summary()
        end,
        desc = "Summary",
      },
      {
        "<leader>glA",
        function()
          require("gitlab").approve()
        end,
        desc = "Approve",
      },
      {
        "<leader>glR",
        function()
          require("gitlab").revoke()
        end,
        desc = "Revoke",
      },
      {
        "<leader>glm",
        function()
          require("gitlab").merge()
        end,
        desc = "Merge",
      },

      -- Comments & discussions
      {
        "<leader>glc",
        function()
          require("gitlab").create_comment()
        end,
        desc = "Create Comment",
      },
      {
        "<leader>glc",
        function()
          require("gitlab").create_multiline_comment()
        end,
        desc = "Multiline Comment",
        mode = "v",
      },
      {
        "<leader>gln",
        function()
          require("gitlab").create_note()
        end,
        desc = "Create Note",
      },
      {
        "<leader>gld",
        function()
          require("gitlab").toggle_discussions()
        end,
        desc = "Discussions",
      },

      -- Pipeline & info
      {
        "<leader>glp",
        function()
          require("gitlab").pipeline()
        end,
        desc = "Pipeline",
      },
      {
        "<leader>glb",
        function()
          require("gitlab").open_in_browser()
        end,
        desc = "Open in Browser",
      },

      -- MR management
      {
        "<leader>glu",
        function()
          require("gitlab").copy_mr_url()
        end,
        desc = "Copy MR URL",
      },
      {
        "<leader>glP",
        function()
          require("gitlab").publish_all_drafts()
        end,
        desc = "Publish All Drafts",
      },

      -- Assignees & reviewers
      {
        "<leader>glaa",
        function()
          require("gitlab").add_assignee()
        end,
        desc = "Add Assignee",
      },
      {
        "<leader>glad",
        function()
          require("gitlab").delete_assignee()
        end,
        desc = "Delete Assignee",
      },
      {
        "<leader>glra",
        function()
          require("gitlab").add_reviewer()
        end,
        desc = "Add Reviewer",
      },
      {
        "<leader>glrd",
        function()
          require("gitlab").delete_reviewer()
        end,
        desc = "Delete Reviewer",
      },

      -- Labels
      {
        "<leader>glla",
        function()
          require("gitlab").add_label()
        end,
        desc = "Add Label",
      },
      {
        "<leader>glld",
        function()
          require("gitlab").delete_label()
        end,
        desc = "Delete Label",
      },
    },
  },
}
