# mini-reverse

A lightweight Neovim plugin, aiming to auto **reverse** the paired content(i.e. `left`<->`right`,`true`<->`false`,`==`<->`!=`)

## Feature
- Normal mode(content in cursor) && Visual mode(content selected) are both SUPPORTED
- Customizable reversed pairs
- Support ignore case sensitivity(i.e. `Left`<->`Right`)

## Setup
### Using Lazy.nvim
```lua
{
  'MrKyomoto/mini-reverse.nvim',
  config = function()
    require('mini.reverse').setup({
      -- Custom key mapping (default is 'tr')
      mappings = { toggle = 'tr' },  -- 'tr' stands for "toggle reverse"

      -- Extend reverse pairs (defaults include left/right, <, >, etc.)
      reverse_pairs = {
        -- NOTE:Add new pairs while preserving defaults
        ['north'] = 'south',
        ['south'] = 'north',
        ['enable'] = 'disable',
        ['disable'] = 'enable',
        -- NOTE:Override default == ↔ != with == ↔ <> (useful for specific languages)
        ['=='] = '<>',
        ['<>'] = '==',
      },

      -- Enable case insensitivity (default: false)
      ignore_case = true,  -- Now works with Left → Right, LEFT → RIGHT

      -- Enable silent mode (no notifications, default: false)
      silent = true
    })
  end
}
```
## default settings
```lua
-- Default configuration
MiniReverse.config = {
	mappings = { toggle = "tr" },
	reverse_pairs = {
		["left"] = "right",
		["right"] = "left",
		["up"] = "down",
		["down"] = "up",
		["true"] = "false",
		["false"] = "true",                   i
		["+"] = "-",
		["-"] = "+",
		["^"] = "_", -- NOTE: for some LaTex reason it is added into the default config
		["_"] = "^",
		["/"] = "\\", -- NOTE: in case that you need to convert \ and /
		["\\"] = "/",
		["<"] = ">",
		[">"] = "<",
		["<="] = ">=",
		[">="] = "<=",
		["=="] = "!=",
		["!="] = "==",
		["==="] = "!==",
		["!=="] = "===",
		["on"] = "off",
		["off"] = "on",
	},
	ignore_case = false,
	silent = false,
}
```
