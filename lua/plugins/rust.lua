return {
    "mrcjkb/rustaceanvim",
    version = "^5", -- keep in sync with README
    ft = { "rust" },
    init = function()
        -- Configure before the plugin loads
        vim.g.rustaceanvim = {
            server = {
                -- Reuse your cmp capabilities so completion works the same as other LSPs
                capabilities = require("cmp_nvim_lsp").default_capabilities(),
                -- Your normal on_attach things (you already set global LspAttach keymaps, so this can be empty)
                on_attach = function(client, bufnr)
                    local map = function(mode, lhs, rhs, desc)
                        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
                    end

                    -- Hover actions (code lens-y popover with actions)
                    map("n", "K", "<cmd>RustLsp hover actions<CR>", "Rust Hover Actions")

                    -- Go-to & friends (use your global LSP keys if you prefer)
                    map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
                    map("n", "gr", vim.lsp.buf.references, "References")

                    -- Runnables / Testables / Debuggables
                    map("n", "<leader>rr", "<cmd>RustLsp runnables<CR>", "Rust Runnables")
                    map("n", "<leader>rt", "<cmd>RustLsp testables<CR>", "Rust Testables")
                    map("n", "<leader>rd", "<cmd>RustLsp debuggables<CR>", "Rust Debuggables")

                    -- Macro expansion & crate graph (super handy when codegen is heavy)
                    map("n", "<leader>rm", "<cmd>RustLsp expandMacro<CR>", "Expand Macro")
                    map("n", "<leader>rg", "<cmd>RustLsp crateGraph<CR>", "Crate Graph")

                    -- Error help & docs
                    map("n", "<leader>re", "<cmd>RustLsp explainError<CR>", "Explain Error")
                    map("n", "<leader>ro", "<cmd>RustLsp openDocs<CR>", "Open Docs (Item)")

                    -- Inlay hints toggle (types, parameter names)
                    map("n", "<leader>ri", "<cmd>RustLsp inlayHints<CR>", "Toggle Inlay Hints")
                end,
                -- v5+ uses default_settings
                default_settings = {
                    ["rust-analyzer"] = {
                        cargo = { allFeatures = true },
                        check = { command = "clippy" },
                    },
                },
            },
            tools = {
                hover_actions = { auto_focus = true },
            },
        }
    end,
}
