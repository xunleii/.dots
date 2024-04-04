return {
  {
    "akinsho/nvim-toggleterm.lua",
    keys = "<C-t>",
    event = "VeryLazy",
    init = function()
      -- Hide number column for
      -- vim.cmd [[au TermOpen * setlocal nonumber norelativenumber]]

      -- Esc twice to get to normal mode
      vim.cmd([[tnoremap <ESC> <C-\><C-N>]])
    end,
    opts = {
      size = 20,
      open_mapping = [[<C-t>]],
      shading_factor = 0.3, -- the degree by which to darken to terminal colour, default: 1 for dark backgrounds, 3 for light
      direction = "float",
    },
  },
}
