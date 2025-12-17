-- =======================================================
-- Neovim Configuration for React.js & Next.js Development
-- =======================================================
--
-- "For I know the plans I have for you," declares the Lord, "plans to prosper you and not to harm you, plans to give you hope and a future." - Jeremiah 29:11
--
-- Bootstrap Lazy.nvim Plugin Manager (needed before loading plugins)
-- ===================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath
    })
end
vim.opt.rtp:prepend(lazypath)

-- Load plugins from general config
-- ==================================
-- Load the general config early to access the global plugins table
local home_dir = vim.fn.expand("~")
local general_config_path = home_dir .. "/.config/nvim-general/plugins.lua"
local general_plugins = {}
local ok, err = pcall(function()
    dofile(general_config_path)
    general_plugins = plugins or {}
end)
if not ok then
    vim.notify("Could not load general config: " .. tostring(err),
        vim.log.levels.ERROR)
end

-- Plugin Configuration
-- =====================
require("lazy").setup({
    -- Plugins from general config (loaded without importing entire file)
    general_plugins,
    -- LSP Base
    { "neovim/nvim-lspconfig" },     -- Dart Syntax Support
    { "dart-lang/dart-vim-plugin" }, -- Debugging Tools
    { "mfussenegger/nvim-dap" }, {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
        require("dapui").setup({
            layouts = {
                {
                    elements = {
                        { id = "scopes",      size = 0.25 },
                        { id = "breakpoints", size = 0.25 },
                        { id = "stacks",      size = 0.25 },
                        { id = "watches",     size = 0.25 }
                    },
                    position = "left",
                    size = 40
                }, {
                elements = {
                    { id = "repl",    size = 0.5 },
                    { id = "console", size = 0.5 }
                },
                position = "bottom",
                size = 10
            }
            },
            icons = {
                expanded = "▾",
                collapsed = "▸",
                current_frame = "▸"
            }
        })

        -- Auto-open/close DAP UI on debug session start/end
        local dap, dapui = require("dap"), require("dapui")
        dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
        end
    end
}, {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = {
        "mfussenegger/nvim-dap", "nvim-treesitter/nvim-treesitter"
    },
    config = function()
        require("nvim-dap-virtual-text").setup({
            enabled = true,
            enable_commands = true,
            highlight_changed_variables = true,
            highlight_new_as_changed = false,
            show_stop_reason = true,
            commented = false,
            only_first_definition = true,
            all_references = false,
            display_callback = function(variable, _buf, _stackframe, _node)
                return variable.name .. " = " .. variable.value
            end,
            virt_text_pos = "eol",
            all_frames = false,
            virt_lines = false,
            virt_text_win_col = nil
        })
    end
}, -- Flutter Tools Integration
    {
        "akinsho/flutter-tools.nvim",
        lazy = false,
        dependencies = { "nvim-lua/plenary.nvim", "stevearc/dressing.nvim" },
        config = function()
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
            if cmp_nvim_lsp_ok then
                capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
            end

            require("flutter-tools").setup({
                ui = { border = "rounded" },
                closing_tags = { enabled = true },
                debugger = { enabled = true, run_via_dap = true },
                dev_log = { enabled = false },
                lsp = {
                    capabilities = capabilities,
                    settings = { showTodos = true, completeFunctionCalls = true }
                }
            })

            -- Flutter keymaps
            local map = vim.keymap.set

            map("n", "<leader>fr", function()
                vim.cmd(
                    "FlutterRun -d web-server --web-port=8008 --web-hostname=localhost --dart-define=ENVIRONMENT=dev")
            end, { desc = "Flutter Run (Web Server)" })

            map("n", "<leader>fq", "<cmd>FlutterQuit<CR>",
                { desc = "Flutter Quit" })

            -- DAP debug keymaps
            local dap = require("dap")
            map("n", "<leader>db", "<cmd>FlutterDebug<CR>",
                { desc = "Start Flutter Debug" })
            map("n", "<leader>de", dap.continue, { desc = "Continue" })
            map("n", "<leader>do", dap.step_over, { desc = "Step Over" })
            map("n", "<leader>di", dap.step_into, { desc = "Step Into" })
            map("n", "<leader>du", dap.step_out, { desc = "Step Out" })
            map("n", "<leader>dr", dap.restart, { desc = "Restart" })
            map("n", "<leader>ds", dap.stop, { desc = "Stop" })
            map("n", "<leader>dt", function()
                require("dapui").toggle()
            end, { desc = "Toggle DAP UI" })
            map("n", "<leader>dBp", dap.toggle_breakpoint,
                { desc = "Toggle Breakpoint" })
            map("n", "<leader>dBP", function()
                dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
            end, { desc = "Breakpoint with Condition" })
        end
    }, -- Tree-sitter (Syntax Highlighting)
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = { "dart", "lua", "vim", "vimdoc" },
                highlight = { enable = true },
                indent = { enable = true }
            })
        end
    }
})

-- Import general Neovim configuration
-- ====================================
local home_dir = vim.fn.expand("~")
dofile(home_dir .. "/.config/nvim-general/config.lua")

-- Neoterm Configuration
-- =====================
vim.g.neoterm_size = tostring(math.floor(0.4 * vim.o.columns))
vim.g.neoterm_default_mod = 'botright vertical'
vim.g.neoterm_autoinsert = 1

-- Diagnostics Configuration
-- ==========================
vim.diagnostic.config({
    virtual_text = {
        severity = { min = vim.diagnostic.severity.WARN },
        source = "always",
        prefix = "●",
        spacing = 4
    },
    signs = {
        { name = "DiagnosticSignError", text = "✗" },
        { name = "DiagnosticSignWarn", text = "⚠" },
        { name = "DiagnosticSignHint", text = "💡" },
        { name = "DiagnosticSignInfo", text = "ℹ" }
    },
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = { border = "rounded", source = "always", header = "", prefix = "" }
})

-- Comment String Configuration
-- =============================
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "dart", "lua" },
    callback = function()
        if vim.bo.filetype == "dart" then
            vim.bo.commentstring = "// %s"
        elseif vim.bo.filetype == "lua" then
            vim.bo.commentstring = "-- %s"
        end
    end
})

-- DAP Visual Signs Configuration
-- ================================
vim.fn.sign_define("DapBreakpoint", {
    text = "●",
    texthl = "DapBreakpoint",
    linehl = "",
    numhl = ""
})

vim.fn.sign_define("DapBreakpointCondition", {
    text = "◆",
    texthl = "DapBreakpointCondition",
    linehl = "",
    numhl = ""
})

vim.fn.sign_define("DapBreakpointRejected", {
    text = "○",
    texthl = "DapBreakpointRejected",
    linehl = "",
    numhl = ""
})

vim.fn.sign_define("DapStopped", {
    text = "→",
    texthl = "DapStopped",
    linehl = "DapStoppedLine",
    numhl = "DapStoppedLine"
})

vim.fn.sign_define("DapLogPoint", {
    text = "◆",
    texthl = "DapLogPoint",
    linehl = "",
    numhl = ""
})
