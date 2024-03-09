# lualine-ext.nvim

> A extensions of [lualine](https://github.com/nvim-lualine/lualine.nvim)  for neovim

![Screenshot](https://github.com/Mr-LLLLL/media/blob/master/lualine-ext/lsp.png)

- show LSP references, implementation, hover.

![Screenshot](https://github.com/Mr-LLLLL/media/blob/master/lualine-ext/projects.png)

- show projects name in tabline_a of lualine

![Screenshot](https://github.com/Mr-LLLLL/media/blob/master/lualine-ext/date.png)

- show date details in tabline_z of lualine

## Installation

With [lazy.nvim](https://github.com/folk/lazy.nvim):

``` lua
    {
        "Mr-LLLLL/lualine-ext.nvim",
        event = "VeryLazy",
        dependencies = {
            "nvim-lualine/lualine.nvim",
            -- if you want to open telescope window when click on LSP info of lualine, uncomment it
            -- "nvim-telescope/telescope.nvim"
        },
        opts = {
            init_tab_project = {
                disabled = false,
                tabs_color = {
                    inactive = {
                        fg = "#9da9a0",
                        bg = "#4f5b58",
                    },
                }
            },
            init_lsp = {
                disabled = false,
            },
            init_tab_date = true,
        }
    }
```

![Screenshot](https://github.com/Mr-LLLLL/media/blob/master/lualine-ext/projects.png)

show navic in tabline_c of lualine but need [nvim-navic](https://github.com/SmiteshP/nvim-navic)

``` lua
    {
        "SmiteshP/nvim-navic",
        event = "VeryLazy",
        dependencies = {
            "nvim-lualine/lualine.nvim",
        },
        config = function()
            require("lualine-ext").init_tab_navic()
        end
    }

```

![Screenshot](https://github.com/Mr-LLLLL/media/blob/master/lualine-ext/date.png)

show git blame in tabline_x of lualine but need [gitsigns](https://github.com/lewis6991/gitsigns.nvim)

``` lua
{
        'lewis6991/gitsigns.nvim',
        event = "VeryLazy",
        dependencies = {
            "nvim-lualine/lualine.nvim",
        },
        config = function()
            require("lualine-ext").init_tab_blame()
        end
    }

```
