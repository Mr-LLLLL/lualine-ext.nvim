# lualine-ext.nvim

> Show more information on [lualine](https://github.com/nvim-lualine/lualine.nvim)  for Neovim

- Show cursor symbol references, implementations, hover in lualine_c.

![Screenshot](https://github.com/Mr-LLLLL/media/blob/master/lualine-ext/lsp.png)

- Show projects name in tabline_a of lualine.
  
![Screenshot](https://github.com/Mr-LLLLL/media/blob/master/lualine-ext/projects.png)

- Show date details in tabline_z of lualine.

![Screenshot](https://github.com/Mr-LLLLL/media/blob/master/lualine-ext/date.png)

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
            separator = {
                left = "",
                right = "",
            },
            init_tab_project = {
                disabled = false,
                -- set this for your colorscheme. I have not default setting in diff colorcheme. 
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

- Show navic in tabline_c of lualine but need [nvim-navic](https://github.com/SmiteshP/nvim-navic)

![Screenshot](https://github.com/Mr-LLLLL/media/blob/master/lualine-ext/navic.png)

``` lua
    {
        "SmiteshP/nvim-navic",
        event = "VeryLazy",
        dependencies = {
            "nvim-lualine/lualine.nvim",
        },
        config = function()
            ...
            require("lualine-ext").init_tab_navic()
            ...
        end
    }

```

- Show git blame in tabline_x of lualine but need [gitsigns](https://github.com/lewis6991/gitsigns.nvim)

![Screenshot](https://github.com/Mr-LLLLL/media/blob/master/lualine-ext/git_blame.png)


``` lua
{
        'lewis6991/gitsigns.nvim',
        event = "VeryLazy",
        dependencies = {
            "nvim-lualine/lualine.nvim",
        },
        config = function()
            ...
            require("lualine-ext").init_tab_blame()
            ...
        end
    }

```

- Show key command and recording mode in section_x of lualine but need [noice.nvim](https://github.com/folk/noice.nvim)

![Screenshot](https://github.com/Mr-LLLLL/media/blob/master/lualine-ext/noice.png)

``` lua
{
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = {
            "nvim-lualine/lualine.nvim",
        },
        config = function()
            ...
            require("lualine-ext").init_noice()
            ...
        end
    }

```
