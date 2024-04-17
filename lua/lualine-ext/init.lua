local m = {}

local lsp_info = {
    ["textDocument/references"] = "",
    ["textDocument/implementation"] = "",
    ["textDocument/hover"] = "",
}

m.list_or_jump = function(action, f, param)
    local lspParam = vim.lsp.util.make_position_params(vim.fn.win_getid())
    lspParam.context = { includeDeclaration = false }
    vim.lsp.buf_request(vim.api.nvim_get_current_buf(), action, lspParam, function(err, result, ctx, _)
        if err then
            vim.api.nvim_err_writeln("Error when executing " .. action .. " : " .. err.message)
            return
        end
        local flattened_results = {}
        if result then
            -- textDocument/definition can return Location or Location[]
            if not vim.tbl_islist(result) then
                flattened_results = { result }
            end

            vim.list_extend(flattened_results, result)
        end

        local offset_encoding = vim.lsp.get_client_by_id(ctx.client_id).offset_encoding

        if #flattened_results == 0 then
            return
            -- definitions will be two result in lua, i think first is pretty goods
        elseif #flattened_results == 1 or action == "textDocument/definition" then
            if type(param) == "table" then
                if param.jump_type == "vsplit" then
                    vim.cmd("vsplit")
                elseif param.jump_type == "tab" then
                    vim.cmd("tab split")
                end
            end
            vim.lsp.util.jump_to_location(flattened_results[1], offset_encoding)
            require('telescope.actions').center()
        else
            f(param)
        end
    end)
end

m.init_noice = function()
    local old = require("lualine").get_config()
    table.insert(old.sections.lualine_x, 1, {
        require("noice").api.status.mode.get,
        cond = function()
            local msg = require("noice").api.status.mode.get()
            if msg == nil then
                return false
            end
            if string.match(msg, "recording") == "recording" then
                return true
            else
                return false
            end
        end,
        color = { fg = "#ff9e64" },
    })
    table.insert(old.sections.lualine_x, 1, {
        require("noice").api.status.command.get,
        cond = require("noice").api.status.command.has,
        color = { fg = "#ff9e64" },
    })
    require("lualine").setup(old)
end

m.init_lsp = function()
    local augroup = vim.api.nvim_create_augroup("LualineLspExt", { clear = true })
    vim.api.nvim_create_autocmd(
        { "CursorHold" },
        {
            pattern = { "*.*" },
            callback = function()
                local lspParam = vim.lsp.util.make_position_params(vim.fn.win_getid())
                lspParam.context = { includeDeclaration = false }
                for k in pairs(lsp_info) do
                    lsp_info[k] = ""
                    local clients = vim.lsp.get_active_clients({ bufnr = vim.api.nvim_get_current_buf() })
                    if not vim.tbl_islist(clients) or #clients == 0 then
                        goto continue
                    end

                    for _, client in ipairs(clients) do
                        if not client.supports_method(k) then
                            goto continue
                        end
                    end

                    vim.lsp.buf_request(vim.api.nvim_get_current_buf(), k, lspParam, function(err, result, _, _)
                        if err then
                            return
                        end

                        if not result then
                            return
                        end

                        if k == "textDocument/hover" then
                            if not result.contents then
                                return
                            end

                            local value
                            if type(result.contents) == 'string' then   -- MarkedString
                                value = result.contents
                            elseif result.contents.language then        -- MarkedString
                                value = result.contents.value
                            elseif vim.tbl_islist(result.contents) then -- MarkedString[]
                                if vim.tbl_isempty(result.contents) then
                                    return
                                end
                                local values = {}
                                for _, ms in ipairs(result.contents) do
                                    table.insert(values, type(ms) == 'string' and ms or ms.value)
                                end
                                value = table.concat(values, '\n')
                            elseif result.contents.kind then -- MarkupContent
                                value = result.contents.value
                            end

                            if not value or #value == 0 then
                                return
                            end
                            local content = vim.split(value, '\n', { trimempty = true })
                            if clients[1].name == "rust-analyzer" then
                                if #content > 2 then
                                    lsp_info[k] = content[2]
                                    if #content > 6 and content[5] == "```rust" then
                                        lsp_info[k] = lsp_info[k] .. "  "
                                    elseif #content == 4 then
                                        lsp_info[k] = content[3] .. content[2]
                                    else
                                        return
                                    end
                                    for i = 6, #content, 1 do
                                        if content[i] == "```" then
                                            break
                                        end
                                        lsp_info[k] = lsp_info[k] ..
                                            string.match(vim.trim(content[i]), ".*[^,]$*") .. " "
                                    end
                                end
                            else
                                if #content > 1 then
                                    lsp_info[k] = string.match(content[2], ".*[^{ ]$*")
                                end
                            end
                        elseif vim.tbl_islist(result) then
                            lsp_info[k] = tostring(#result)
                            return
                        end
                    end)
                    ::continue::
                end
            end,
            group = augroup,
        }
    )

    local old = require("lualine").get_config()
    table.insert(old.sections.lualine_c, #old.sections.lualine_c + 1, {
        function()
            return "󰁞 " .. lsp_info["textDocument/references"]
        end,
        cond = function()
            return lsp_info["textDocument/references"] ~= ""
        end,
        on_click = m.config.init_lsp.references_on_click
    })
    table.insert(old.sections.lualine_c, #old.sections.lualine_c + 1, {
        function()
            return " " .. lsp_info["textDocument/implementation"]
        end,
        cond = function()
            return lsp_info["textDocument/implementation"] ~= ""
        end,
        on_click = m.config.init_lsp.implementations_on_click
    })
    table.insert(old.sections.lualine_c, #old.sections.lualine_c + 1, {
        function()
            return " " .. lsp_info["textDocument/hover"]
        end,
        cond = function()
            return lsp_info["textDocument/hover"] ~= ""
        end,
        on_click = m.config.init_lsp.document_on_click,
    })
    require("lualine").setup(old)
end

m.init_tab_project = function()
    local old = require("lualine").get_config()
    if not old.tabline.lualine_a then
        old.tabline.lualine_a = {}
    end
    old.tabline.lualine_a = { {
        "tabs",
        max_length = vim.o.columns * 2 / 3,
        mode = 2,
        fmt = function(_, context)
            local emptyName = '[No Name]'
            local buflist = vim.fn.tabpagebuflist(context.tabnr)
            local winnr = vim.fn.tabpagewinnr(context.tabnr)
            local bufnr = buflist[winnr]
            local winid = vim.fn.win_getid(winnr, context.tabnr)
            local bufferPath = vim.fn.bufname(bufnr)
            local project_icon = vim.fn.tabpagenr() == context.tabnr and " " or " "
            local file_icon = vim.fn.tabpagenr() == context.tabnr and " " or " "
            if bufferPath == "" then
                return emptyName .. file_icon
            end
            if vim.api.nvim_buf_get_option(bufnr, 'buftype') == "nofile" then
                return bufferPath .. file_icon
            end

            if bufferPath:sub(1, 1) ~= '/' then
                bufferPath = vim.fn.getcwd() .. "/" .. bufferPath

                local title = vim.fn.findfile('.git', bufferPath .. ';')
                if title == "" then
                    title = vim.fn.finddir('.git', bufferPath .. ';')
                end
                title = vim.fn.getcwd() .. "/" .. title
                return vim.fn.fnamemodify(title, ':h:t') .. project_icon
            end

            local title = vim.fn.findfile('.git', bufferPath .. ';')
            if title == "" then
                title = vim.fn.finddir('.git', bufferPath .. ';')
            end

            if title == "" then
                if vim.fn.getqflist({ ['qfbufnr'] = 0 }).qfbufnr == bufnr then
                    return '[Quickfix List]'
                elseif winid and vim.fn.getloclist(winid, { ['qfbufnr'] = 0 }).qfbufnr == bufnr then
                    return '[Location List]'
                end
                return vim.fn.fnamemodify(bufferPath, ':p:t') .. file_icon
            end

            return vim.fn.fnamemodify(title, ':h:t') .. project_icon
        end,
        separator = { left = m.config.separator.left, right = m.config.separator.right },
        tabs_color = m.config.init_tab_project.tabs_color,
    } }
    require("lualine").setup(old)
end

m.init_tab_date = function()
    local old = require("lualine").get_config()
    if not old.tabline.lualine_y then
        old.tabline.lualine_y = {}
    end
    if not old.tabline.lualine_z then
        old.tabline.lualine_z = {}
    end
    local weeks = {
        ["0"] = "Sun",
        ['1'] = "Mon",
        ["2"] = "Tue",
        ["3"] = "Wed",
        ["4"] = "Thu",
        ["5"] = "Fri",
        ["6"] = "Sat",
    }
    table.insert(old.tabline.lualine_y, #old.tabline.lualine_y + 1, {
        function() return "󰕶 " .. weeks[os.date('%w')] .. "  " .. os.date('%y-%m-%d') end,
        separator = { left = m.config.separator.left },
    })
    table.insert(old.tabline.lualine_z, #old.tabline.lualine_z + 1, {
        function() return "󰔛 " .. os.date('%H:%M:%S') end,
        separator = { right = m.config.separator.right }
    })
    require("lualine").setup(old)
end

m.init_harpoon = function(opt)
    local old = require("lualine").get_config()
    if not old.tabline.lualine_c then
        old.tabline.lualine_c = { '%=' } -- make the indicator center
    end
    table.insert(old.tabline.lualine_c, #old.tabline.lualine_c + 1, opt or {
        "harpoon2",
        indicators = { "1", "2", "3", "4", "5", "6", "7", "8", "9" },
        active_indicators = { "[1]", "[2]", "[3]", "[4]", "[5]", "[6]", "[7]", "[8]", "[9]" },
    })
    require("lualine").setup(old)
end

m.init_tab_blame = function(opt)
    local old = require("lualine").get_config()
    if not old.tabline.lualine_x then
        old.tabline.lualine_x = {}
    end
    table.insert(old.tabline.lualine_x, 1, opt or {
        function() return vim.b.gitsigns_blame_line .. "  " end,
        cond = function() return vim.b.gitsigns_blame_line ~= nil end,
    })
    require("lualine").setup(old)
end

m.init_tab_navic = function()
    local navic = require("nvim-navic")
    navic.setup({
        icons = {
            File          = "󰈙 ",
            Module        = " ",
            Namespace     = "󰌗 ",
            Package       = " ",
            Class         = "󰌗 ",
            Method        = "󰆧 ",
            Property      = " ",
            Field         = " ",
            Constructor   = " ",
            Enum          = "󰕘",
            Interface     = "󰕘",
            Function      = "󰊕 ",
            Variable      = "󰆧 ",
            Constant      = "󰏿 ",
            String        = "󰀬 ",
            Number        = "󰎠 ",
            Boolean       = "◩ ",
            Array         = "󰅪 ",
            Object        = "󰅩 ",
            Key           = "󰌋 ",
            Null          = "󰟢 ",
            EnumMember    = " ",
            Struct        = "󰌗 ",
            Event         = " ",
            Operator      = "󰆕 ",
            TypeParameter = "󰊄 ",
        },
        lsp = {
            auto_attach = true,
            preference = nil,
        },
        highlight = false,
        separator = "",
        depth_limit = 0,
        depth_limit_indicator = "..",
        safe_output = true,
        lazy_update_context = false,
        click = true
    })

    local old = require("lualine").get_config()
    if not old.tabline.lualine_b then
        old.tabline.lualine_b = {}
    end
    table.insert(old.tabline.lualine_b, #old.tabline.lualine_b + 1, {
        function()
            return navic.get_location({ click = true })
        end,
        separator = { right = m.config.separator.right },
        cond = function()
            return navic.is_available()
        end,
        on_click = function()
            _G.navic_click_handler(api.nvim_get_current_win())
        end
    })
    require("lualine").setup(old)
end

m.config = {
    separator = {
        left = "",
        right = "",
    },
    init_tab_project = {
        disabled = false,
        -- modify by your colorschemo
        tabs_color = {
            inactive = {
                fg = "#9da9a0",
                bg = "#4f5b58",
            },
        }
    },
    init_lsp = {
        disabled = false,
        references_on_click = function()
            local has_tele, tele_builtin = pcall(require, 'telescope.builtin')
            if not has_tele then
                return
            end

            m.list_or_jump(
                "textDocument/references",
                tele_builtin.lsp_references,
                { include_declaration = false }
            )
        end,
        implementations_on_click = function()
            local has_tele, tele_builtin = pcall(require, 'telescope.builtin')
            if not has_tele then
                return
            end

            m.list_or_jump(
                "textDocument/implementation",
                tele_builtin.lsp_implementations
            )
        end,
        document_on_click = function()
            vim.lsp.buf.hover()
        end,
    },
    init_tab_date = true,
}

local get_default_config = function()
    return m.config
end

m.setup = function(opts)
    opts = opts or {}
    m.config = vim.tbl_deep_extend('force', get_default_config(), opts)

    if not m.config.init_tab_project.disabled then
        m.init_tab_project()
    end
    if not m.config.init_lsp.disabled then
        m.init_lsp()
    end
    if m.config.init_tab_date then
        m.init_tab_date()
    end
end

return m
