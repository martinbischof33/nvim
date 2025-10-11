return {
    'neovim/nvim-lspconfig',
    dependencies = {
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
        -- autocompletion
        'hrsh7th/nvim-cmp',
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'saadparwaiz1/cmp_luasnip',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-nvim-lua',
        -- snippets
        'l3mon4d3/luasnip',
        'rafamadriz/friendly-snippets',
        -- optional formatter plugin
        -- 'stevearc/conform.nvim',
    },

    config = function()
        ---------------------------------------------------------------------------
        -- Autoformat-on-save for selected filetypes (Lua)
        ---------------------------------------------------------------------------
        local autoformat_filetypes = { "lua" }

        vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if not client then return end

                if vim.tbl_contains(autoformat_filetypes, vim.bo[args.buf].filetype) then
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        buffer = args.buf,
                        callback = function()
                            vim.lsp.buf.format({
                                bufnr = args.buf,
                                id = client.id,
                                formatting_options = { tabSize = 4, insertSpaces = true },
                            })
                        end,
                    })
                end
            end,
        })

        ---------------------------------------------------------------------------
        -- LSP UI: borders & diagnostics
        ---------------------------------------------------------------------------
        vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
            vim.lsp.handlers.hover,
            { border = 'rounded' }
        )
        vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
            vim.lsp.handlers.signature_help,
            { border = 'rounded' }
        )

        vim.diagnostic.config({
            virtual_text = true,
            severity_sort = true,
            float = {
                style = 'minimal',
                border = 'rounded',
                header = '',
                prefix = '',
            },
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = '✘',
                    [vim.diagnostic.severity.WARN]  = '▲',
                    [vim.diagnostic.severity.HINT]  = '⚑',
                    [vim.diagnostic.severity.INFO]  = '»',
                },
            },
        })

        ---------------------------------------------------------------------------
        -- Capabilities (nvim-cmp)
        ---------------------------------------------------------------------------
        local lspconfig = require('lspconfig')
        local lsp_defaults = lspconfig.util.default_config
        lsp_defaults.capabilities = vim.tbl_deep_extend(
            'force',
            lsp_defaults.capabilities,
            require('cmp_nvim_lsp').default_capabilities()
        )

        ---------------------------------------------------------------------------
        -- Keymaps (only when LSP is attached)
        ---------------------------------------------------------------------------
        vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(event)
                local opts = { buffer = event.buf, silent = true, noremap = true }
                vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
                vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
                vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
                vim.keymap.set('n', 'go', vim.lsp.buf.type_definition, opts)
                vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
                vim.keymap.set('n', 'gs', vim.lsp.buf.signature_help, opts)
                vim.keymap.set('n', 'gl', vim.diagnostic.open_float, opts)
                vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, opts)
                vim.keymap.set({ 'n', 'x' }, '<F3>', function() vim.lsp.buf.format({ async = true }) end, opts)
                vim.keymap.set('n', '<F4>', vim.lsp.buf.code_action, opts)
            end,
        })

        ---------------------------------------------------------------------------
        -- mason + mason-lspconfig
        ---------------------------------------------------------------------------
        require('mason').setup({})

        require('mason-lspconfig').setup({
            ensure_installed = {
                'lua_ls',
                'ts_ls',
                'eslint',
                'ruff', -- Ruff LSP (Python linter/fixer)
            },

            handlers = {
                -- default handler for all servers
                function(server_name)
                    if server_name == 'lua_ls' or server_name == 'ruff' then return end
                    lspconfig[server_name].setup({})
                end,

                -- Lua LSP
                lua_ls = function()
                    lspconfig.lua_ls.setup({
                        settings = {
                            Lua = {
                                runtime = { version = 'LuaJIT' },
                                diagnostics = { globals = { 'vim' } },
                                workspace = { library = { vim.env.VIMRUNTIME } },
                                telemetry = { enable = false },
                            },
                        },
                    })
                end,

                -- Ruff LSP (Python) — keep hover enabled since Pyright is NOT used
                ruff = function()
                    lspconfig.ruff.setup({})
                end,
            },
        })

        ---------------------------------------------------------------------------
        -- Ruff: apply fixes/import-sorting on save WITHOUT a prompt
        ---------------------------------------------------------------------------
        local function apply_ruff_actions(bufnr, kinds)
            bufnr = bufnr or vim.api.nvim_get_current_buf()
            -- Only talk to Ruff clients on this buffer
            local clients = vim.lsp.get_active_clients({ bufnr = bufnr, name = "ruff" })
            if #clients == 0 then return end

            for _, kind in ipairs(kinds) do
                local params = vim.lsp.util.make_range_params()
                params.context = { only = { kind } }

                -- sync request so we can apply immediately
                local results = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 3000)
                if results then
                    for client_id, res in pairs(results) do
                        local client = vim.lsp.get_client_by_id(client_id)
                        if res and res.result then
                            for _, action in ipairs(res.result) do
                                if action.edit then
                                    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
                                end
                                local command = action.command or action
                                if command then
                                    vim.lsp.buf.execute_command(command)
                                end
                            end
                        end
                    end
                end
            end
        end

        vim.api.nvim_create_autocmd("BufWritePre", {
            pattern = "*.py",
            callback = function(args)
                apply_ruff_actions(args.buf, { "source.fixAll", "source.organizeImports" })
            end,
        })

        ---------------------------------------------------------------------------
        -- Optional: full code formatter (e.g. Black or Ruff formatter via conform)
        ---------------------------------------------------------------------------
        -- require("conform").setup({
        --   formatters_by_ft = {
        --     python = { "ruff_format" }, -- or { "black" } if you prefer Black
        --   },
        -- })
        -- vim.api.nvim_create_autocmd("BufWritePre", {
        --   pattern = "*.py",
        --   callback = function()
        --     require("conform").format({ async = false, timeout_ms = 1000 })
        --   end,
        -- })

        ---------------------------------------------------------------------------
        -- nvim-cmp (completion)
        ---------------------------------------------------------------------------
        local cmp = require('cmp')
        require('luasnip.loaders.from_vscode').lazy_load()
        vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

        cmp.setup({
            preselect = 'item',
            completion = { completeopt = 'menu,menuone,noinsert' },
            window = { documentation = cmp.config.window.bordered() },
            sources = {
                { name = 'path' },
                { name = 'nvim_lsp' },
                { name = 'buffer',  keyword_length = 3 },
                { name = 'luasnip', keyword_length = 2 },
            },
            snippet = {
                expand = function(args) require('luasnip').lsp_expand(args.body) end,
            },
            formatting = {
                fields = { 'abbr', 'menu', 'kind' },
                format = function(entry, item)
                    item.menu = (entry.source.name == 'nvim_lsp') and '[LSP]' or ('[' .. entry.source.name .. ']')
                    return item
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<CR>'] = cmp.mapping.confirm({ select = false }),
                ['<C-f>'] = cmp.mapping.scroll_docs(5),
                ['<C-u>'] = cmp.mapping.scroll_docs(-5),
                ['<C-e>'] = cmp.mapping(function()
                    if cmp.visible() then cmp.abort() else cmp.complete() end
                end),
                ['<Tab>'] = cmp.mapping(function(fallback)
                    local col = vim.fn.col('.') - 1
                    if cmp.visible() then
                        cmp.select_next_item({ behavior = 'select' })
                    elseif col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
                        fallback()
                    else
                        cmp.complete()
                    end
                end, { 'i', 's' }),
                ['<S-Tab>'] = cmp.mapping.select_prev_item({ behavior = 'select' }),
                ['<C-d>'] = cmp.mapping(function(fallback)
                    local ls = require('luasnip')
                    if ls.jumpable(1) then ls.jump(1) else fallback() end
                end, { 'i', 's' }),
                ['<C-b>'] = cmp.mapping(function(fallback)
                    local ls = require('luasnip')
                    if ls.jumpable(-1) then ls.jump(-1) else fallback() end
                end, { 'i', 's' }),
            }),
        })
    end,
}
