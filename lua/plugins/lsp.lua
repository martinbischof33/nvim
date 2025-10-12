return {
    'neovim/nvim-lspconfig',
    dependencies = {
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',

        -- Autocompletion
        'hrsh7th/nvim-cmp',
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'saadparwaiz1/cmp_luasnip',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-nvim-lua',

        -- Snippets
        'L3MON4D3/LuaSnip',
        'rafamadriz/friendly-snippets',

        -- Formatter runner for Black + isort
        'stevearc/conform.nvim',
    },

    config = function()
        ---------------------------------------------------------------------------
        -- Mason
        ---------------------------------------------------------------------------
        require('mason').setup({ PATH = 'prepend' })

        ---------------------------------------------------------------------------
        -- Autoformat only for Lua via LSP (unchanged)
        ---------------------------------------------------------------------------
        local autoformat_filetypes = { 'lua' }
        vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(args)
                local client = vim.lsp.get_client_by_id(args.data.client_id)
                if not client then return end
                if vim.tbl_contains(autoformat_filetypes, vim.bo.filetype) then
                    vim.api.nvim_create_autocmd('BufWritePre', {
                        buffer = args.buf,
                        callback = function()
                            vim.lsp.buf.format({
                                formatting_options = { tabSize = 4, insertSpaces = true },
                                bufnr = args.buf,
                                id = client.id,
                            })
                        end,
                    })
                end
            end,
        })

        ---------------------------------------------------------------------------
        -- Borders for hover/signature + diagnostics UI
        ---------------------------------------------------------------------------
        vim.lsp.handlers['textDocument/hover'] =
            vim.lsp.with(vim.lsp.handlers.hover, { border = 'rounded' })
        vim.lsp.handlers['textDocument/signatureHelp'] =
            vim.lsp.with(vim.lsp.handlers.signature_help, { border = 'rounded' })

        vim.diagnostic.config({
            virtual_text = true,
            severity_sort = true,
            float = { style = 'minimal', border = 'rounded', header = '', prefix = '' },
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = '✘',
                    [vim.diagnostic.severity.WARN]  = '▲',
                    [vim.diagnostic.severity.HINT]  = '⚑',
                    [vim.diagnostic.severity.INFO]  = '»',
                },
            },
            underline = true,
        })

        -- Make “unused” diagnostics visibly faded in any colorscheme
        vim.api.nvim_set_hl(0, 'DiagnosticUnnecessary', { link = 'Comment', default = true })

        ---------------------------------------------------------------------------
        -- Capabilities (nvim-cmp)
        ---------------------------------------------------------------------------
        local lspconfig = require('lspconfig')
        local lspconfig_defaults = lspconfig.util.default_config
        lspconfig_defaults.capabilities = vim.tbl_deep_extend(
            'force',
            lspconfig_defaults.capabilities,
            require('cmp_nvim_lsp').default_capabilities()
        )

        ---------------------------------------------------------------------------
        -- LSP keymaps (unchanged)
        ---------------------------------------------------------------------------
        vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(event)
                local opts = { buffer = event.buf }
                vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
                vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
                vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
                vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
                vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
                vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
                vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
                vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>', opts)
                vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
                vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
                vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
            end,
        })

        ---------------------------------------------------------------------------
        -- mason-lspconfig
        ---------------------------------------------------------------------------
        require('mason-lspconfig').setup({
            ensure_installed = {
                'lua_ls',
                'ts_ls',
                'eslint',
                'pyright', -- Python IntelliSense
            },

            handlers = {
                -- default handler (skip the ones we configure below)
                function(server_name)
                    if server_name == 'lua_ls' or server_name == 'pyright' then return end
                    lspconfig[server_name].setup({})
                end,

                -- Lua
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

                -- Python: Pyright (completion, hover, go-to, semantic tokens)
                pyright = function()
                    local util = require('lspconfig.util')
                    lspconfig.pyright.setup({
                        root_dir = util.root_pattern(
                            'pyproject.toml', 'setup.cfg', 'setup.py', 'requirements.txt', '.git'
                        ),
                        on_attach = function(client, bufnr)
                            if client.server_capabilities.semanticTokensProvider then
                                pcall(vim.lsp.semantic_tokens.start, bufnr, client.id)
                            end
                        end,
                        settings = {
                            python = {
                                pythonPath = vim.fn.exepath('python'),
                                venvPath = '.',
                                venv = '.venv',
                                analysis = {
                                    autoSearchPaths = true,
                                    useLibraryCodeForTypes = true,
                                    diagnosticMode = 'workspace',
                                    typeCheckingMode = 'basic',
                                    diagnosticSeverityOverrides = {
                                        reportUnusedImport   = 'warning',
                                        reportUnusedVariable = 'warning',
                                    },
                                },
                            },
                        },
                    })
                end,
            },
        })

        ---------------------------------------------------------------------------
        -- nvim-cmp (unchanged)
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
            snippet = { expand = function(args) require('luasnip').lsp_expand(args.body) end },
            formatting = {
                fields = { 'abbr', 'menu', 'kind' },
                format = function(entry, item)
                    local n = entry.source.name
                    item.menu = (n == 'nvim_lsp') and '[LSP]' or '[' .. n .. ']'
                    return item
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ['<CR>']    = cmp.mapping.confirm({ select = false }),
                ['<C-f>']   = cmp.mapping.scroll_docs(5),
                ['<C-u>']   = cmp.mapping.scroll_docs(-5),
                ['<C-e>']   = cmp.mapping(function()
                    if cmp.visible() then cmp.abort() else cmp.complete() end
                end),
                ['<Tab>']   = cmp.mapping(function(fallback)
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
                ['<C-d>']   = cmp.mapping(function(fallback)
                    local luasnip = require('luasnip')
                    if luasnip.jumpable(1) then luasnip.jump(1) else fallback() end
                end, { 'i', 's' }),
                ['<C-b>']   = cmp.mapping(function(fallback)
                    local luasnip = require('luasnip')
                    if luasnip.jumpable(-1) then luasnip.jump(-1) else fallback() end
                end, { 'i', 's' }),
            }),
        })

        ---------------------------------------------------------------------------
        -- Conform: Python = isort → black on save (NO Ruff)
        ---------------------------------------------------------------------------
        require('conform').setup({
            formatters_by_ft = {
                python = { 'isort', 'black' }, -- run isort first, then black
                rust   = { 'rustfmt' },
            },
            notify_on_error = false,
        })

        -- Format Python files on save with isort+black only
        vim.api.nvim_create_autocmd('BufWritePre', {
            pattern = { '*.py', '*.rs' },
            callback = function(args)
                require('conform').format({
                    bufnr = args.buf,
                    lsp_fallback = false, -- don't fall back to LSP; use isort+black only
                })
            end,
        })
    end,
}
