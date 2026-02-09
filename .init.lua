vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    vim.cmd("make!")
  end,
})
