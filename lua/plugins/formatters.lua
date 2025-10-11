return {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    config = function()
        require("conform").setup({
            formatters_by_ft = {
                python = { "black" },
                lua = { "stylua" },
            },
        })

        vim.api.nvim_create_autocmd("BufWritePre", {
            pattern = "*",
            callback = function()
                require("conform").format({ async = false, timeout_ms = 1000 })
            end,
        })
    end,
}
