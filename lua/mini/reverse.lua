local MiniReverse = {}
local H = {}

-- default config
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
		["^"] = "_", -- NOTE: for LaTex reason this is added to default config xd
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

-- NOTE: core fun: auto reverse
MiniReverse.toggle = function(mode)
	if H.is_disabled() then
		return
	end

	local range = H.get_target_range(mode)
	if not range then
		H.message("Found no reversable contents")
		return
	end

	local current = vim.api.nvim_buf_get_text(0, range.start_row, range.start_col, range.end_row, range.end_col, {})[1]
	if not current or current == "" then
		return
	end

	local reversed = H.get_reversed(current)
	if not reversed then
		H.message("Found no matched reversabled contents: " .. current)
		return
	end

	vim.api.nvim_buf_set_text(0, range.start_row, range.start_col, range.end_row, range.end_col, { reversed })

	H.set_cursor(range.end_row + 1, range.start_col + #reversed + 1)
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

	if m.toggle ~= "" then
		vim.keymap.set("n", m.toggle, function()
			MiniReverse.toggle("normal")
		end, {
			-- NOTE: normal mode
			desc = "Reverse the content in cursor",
			silent = true,
		})
	end

	if m.toggle ~= "" then
		vim.keymap.set("v", m.toggle, ":<C-u>lua MiniReverse.toggle('visual')<CR>", {
			-- NOTE: visual mode
			desc = "Reverse the content selected",
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

-- Get the range of the selected content
H.get_target_range = function(mode)
	if mode == "visual" then
		local start_pos = vim.api.nvim_buf_get_mark(0, "<")
		local end_pos = vim.api.nvim_buf_get_mark(0, ">")
		return {
			start_row = start_pos[1] - 1,
			start_col = start_pos[2],
			end_row = end_pos[1] - 1,
			end_col = end_pos[2] + 1,
		}
	else
		local word = H.get_cursor_word()
		if not word then
			return nil
		end

		local cursor_pos = vim.api.nvim_win_get_cursor(0)
		local row = cursor_pos[1] - 1
		local col = cursor_pos[2]
		local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
		if not line then
			return nil
		end

		local start_col, end_col = H.find_word_in_line(line, word, col)
		if not start_col then
			return nil
		end

		return {
			start_row = row,
			start_col = start_col,
			end_row = row,
			end_col = end_col,
		}
	end
end

-- Get the content in cursor
H.get_cursor_word = function()
	local line = vim.api.nvim_get_current_line()
	local cursor_col = vim.api.nvim_win_get_cursor(0)[2]

	local pattern = "[a-zA-Z0-9_]+|[<>!=]=?|[-+*/]"

	for start_pos, match, end_pos in line:gmatch("()(" .. pattern .. ")()") do
		local start_idx = start_pos - 1
		local end_idx = end_pos - 2

		if cursor_col >= start_idx and cursor_col <= end_idx then
			return match
		end
	end

	return line:sub(cursor_col + 1, cursor_col + 1)
end

H.find_word_in_line = function(line, word, col)
	local len = #word
	local search_start = math.max(1, col - len + 1) -- 1-based
	local search_end = math.min(#line, col + len)
	local search_str = line:sub(search_start, search_end)

	local start_in_search, end_in_search = search_str:find(word, 1, true)
	if not start_in_search then
		return nil
	end

	local start_col = search_start + start_in_search - 2
	local end_col = search_start + end_in_search - 1
	return start_col, end_col
end

H.get_reversed = function(current)
	if not MiniReverse.config.ignore_case then
		return MiniReverse.config.reverse_pairs[current]
	end

	local current_lower = current:lower()
	for k, v in pairs(MiniReverse.config.reverse_pairs) do
		if k:lower() == current_lower then
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

-- Set the position of cursor
H.set_cursor = function(line, col)
	vim.api.nvim_win_set_cursor(0, { line, col - 1 })
end

-- Display Hint
H.message = function(msg)
	if not MiniReverse.config.silent then
		vim.notify("[mini.reverse] " .. msg, vim.log.levels.INFO)
	end
end

-- Type checker
H.check_type = function(name, val, expected_type)
	if type(val) ~= expected_type then
		error(("mini.reverse: %s must be %s Type, but it is %s"):format(name, expected_type, type(val)))
	end
end

return MiniReverse
