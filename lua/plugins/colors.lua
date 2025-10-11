local function enable_transparency()
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
end

return {
    {
        "loctvl842/monokai-pro.nvim",
        config = function()
            vim.cmd.colorscheme "monokai-pro"
            vim.cmd('hi Directory guibg=NONE')
            vim.cmd('hi SignColumn guibg=NONE')
            enable_transparency()
        end
    },
    -- {
    --     "Mofiqul/vscode.nvim",
    --     name = 'vscode',
    --     config = function()
    --         vim.cmd.colorscheme "vscode"
    --         vim.cmd('hi Directory guibg=NONE')
    --         vim.cmd('hi SignColumn guibg=NONE')
    --         enable_transparency()
    --     end
    -- }
}
