local MiniReverse = {}
local H = {}

-- Default configuration
MiniReverse.config = {
	mappings = { toggle = "tr" },
	reverse_pairs = {
		["left"] = "right",
		["right"] = "left",
		["up"] = "down",
		["down"] = "up",
		["true"] = "false",
		["false"] = "true",
		["+"] = "-",
		["-"] = "+",
		["^"] = "_",
		["_"] = "^",
		["/"] = "\\",
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

MiniReverse.setup = function(config)
	_G.MiniReverse = MiniReverse
	config = H.setup_config(config)
	H.apply_config(config)
	H.create_autocommands()
end

-- Core function: Reverse content
MiniReverse.toggle = function(mode)
	if H.is_disabled() then
		return
	end

	local range = H.get_target_range(mode)
	if not range then
		H.message("Found no reversible contents")
		return
	end

	-- Get current content in the range
	local current = vim.api.nvim_buf_get_text(0, range.start_row, range.start_col, range.end_row, range.end_col, {})[1]
	if not current or current == "" then
		return
	end

	-- Get reversed value
	local reversed = H.get_reversed(current)
	if not reversed then
		H.message("No matched reverse pair: " .. current)
		return
	end

	-- Replace with reversed content
	vim.api.nvim_buf_set_text(0, range.start_row, range.start_col, range.end_row, range.end_col, { reversed })

	-- Set cursor to the end of reversed content
	H.set_cursor(
		range.end_row + 1, -- 1-based row
		range.start_col + #reversed -- 0-based column (end of reversed text)
	)
end

H.setup_config = function(config)
	config = vim.tbl_deep_extend("force", vim.deepcopy(MiniReverse.config), config or {})
	H.check_type("mappings", config.mappings, "table")
	H.check_type("reverse_pairs", config.reverse_pairs, "table")
	H.check_type("ignore_case", config.ignore_case, "boolean")
	H.check_type("silent", config.silent, "boolean")
	return config
end

H.apply_config = function(config)
	MiniReverse.config = config
	local m = config.mappings

	-- Normal mode mapping: reverse single character under cursor
	if m.toggle ~= "" then
		vim.keymap.set("n", m.toggle, function()
			MiniReverse.toggle("normal")
		end, {
			desc = "Reverse single character under cursor",
			silent = true,
		})
	end

	-- Visual mode mapping: reverse all pairs in selection
	if m.toggle ~= "" then
		vim.keymap.set("v", m.toggle, ":<C-u>lua MiniReverse.toggle('visual')<CR>", {
			desc = "Reverse all pairs in selection",
			silent = true,
		})
	end
end

H.create_autocommands = function()
	local augroup = vim.api.nvim_create_augroup("MiniReverse", { clear = true })
end

H.is_disabled = function()
	return vim.g.minireverse_disable == true or vim.b.minireverse_disable == true
end

-- Get target range based on mode
H.get_target_range = function(mode)
	if mode == "visual" then
		return H.get_visual_range()
	else
		return H.get_normal_range()
	end
end

-- Visual mode: get range of selected content
H.get_visual_range = function()
	local start_pos = vim.api.nvim_buf_get_mark(0, "<") -- {1-based row, 0-based col}
	local end_pos = vim.api.nvim_buf_get_mark(0, ">") -- {1-based row, 0-based col}

	-- Only support single-line selection
	if start_pos[1] ~= end_pos[1] then
		H.message("Multi-line reversal not supported")
		return nil
	end

	return {
		start_row = start_pos[1] - 1, -- 0-based row
		start_col = start_pos[2], -- 0-based start column
		end_row = end_pos[1] - 1, -- 0-based row
		end_col = end_pos[2] + 1, -- 0-based end column (exclusive)
	}
end

-- Normal mode: get range of single character under cursor
H.get_normal_range = function()
	local cursor_pos = vim.api.nvim_win_get_cursor(0) -- {1-based row, 0-based col}
	local row = cursor_pos[1] - 1 -- 0-based row
	local col = cursor_pos[2] -- 0-based column

	-- Get current line content
	local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
	if not line or col < 0 or col >= #line then
		return nil -- Cursor out of bounds
	end

	-- Get single character under cursor
	local char = line:sub(col + 1, col + 1) -- 1-based substring
	if not char or char == "" then
		return nil
	end

	-- Return range for this single character
	return {
		start_row = row,
		start_col = col, -- 0-based start
		end_row = row,
		end_col = col + 1, -- 0-based end (exclusive)
	}
end

-- Get reversed value (with case preservation)
H.get_reversed = function(current)
	if not MiniReverse.config.ignore_case then
		return MiniReverse.config.reverse_pairs[current]
	end

	-- Case-insensitive matching
	local current_lower = current:lower()
	for k, v in pairs(MiniReverse.config.reverse_pairs) do
		if k:lower() == current_lower then
			-- Preserve original capitalization
			if current:upper() == current then
				return v:upper()
			elseif current:sub(1, 1):upper() == current:sub(1, 1) then
				return v:sub(1, 1):upper() .. v:sub(2)
			else
				return v:lower()
			end
		end
	end
	return nil
end

-- Set cursor position (0-based column)
H.set_cursor = function(line, col)
	vim.api.nvim_win_set_cursor(0, { line, col-1 })
end

-- Show notification message
H.message = function(msg)
	if not MiniReverse.config.silent then
		vim.notify("[mini.reverse] " .. msg, vim.log.levels.INFO)
	end
end

-- Type validation
H.check_type = function(name, val, expected_type)
	if type(val) ~= expected_type then
		error(("mini.reverse: %s must be %s, got %s"):format(name, expected_type, type(val)))
	end
end

return MiniReverse
