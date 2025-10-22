local MiniReverse = {}
local H = {}

-- 模块默认配置
MiniReverse.config = {
	mappings = { toggle = "tr" },
	reverse_pairs = {
		-- 方向类
		["left"] = "right",
		["right"] = "left",
		["up"] = "down",
		["down"] = "up",
		-- 符号类
		["<"] = ">",
		[">"] = "<",
		["<="] = ">=",
		[">="] = "<=",
		["=="] = "!=",
		["!="] = "==",
		["==="] = "!==",
		["!=="] = "===",
		-- 扩展类
		["on"] = "off",
		["off"] = "on",
	},
	ignore_case = false,
	silent = false,
}

-- 初始化函数
MiniReverse.setup = function(config)
	_G.MiniReverse = MiniReverse
	config = H.setup_config(config)
	H.apply_config(config)
	H.create_autocommands()
end

-- 核心功能：反转内容
MiniReverse.toggle = function(mode)
	if H.is_disabled() then
		return
	end

	local range = H.get_target_range(mode)
	if not range then
		H.message("未找到可反转的内容")
		return
	end

	local current = vim.api.nvim_buf_get_text(0, range.start_row, range.start_col, range.end_row, range.end_col, {})[1]
	if not current or current == "" then
		return
	end

	local reversed = H.get_reversed(current)
	if not reversed then
		H.message("无匹配的反转内容: " .. current)
		return
	end

	vim.api.nvim_buf_set_text(0, range.start_row, range.start_col, range.end_row, range.end_col, { reversed })

	H.set_cursor(range.end_row + 1, range.start_col + #reversed + 1)
end

-- 配置处理
H.setup_config = function(config)
	config = vim.tbl_deep_extend("force", vim.deepcopy(MiniReverse.config), config or {})
	H.check_type("mappings", config.mappings, "table")
	H.check_type("reverse_pairs", config.reverse_pairs, "table")
	H.check_type("ignore_case", config.ignore_case, "boolean")
	H.check_type("silent", config.silent, "boolean")
	return config
end

-- 应用配置（设置映射）
H.apply_config = function(config)
	MiniReverse.config = config
	local m = config.mappings

	if m.toggle ~= "" then
		vim.keymap.set("n", m.toggle, function()
			MiniReverse.toggle("normal")
		end, {
			desc = "反转光标下的内容",
			silent = true,
		})
	end

	if m.toggle ~= "" then
		vim.keymap.set("v", m.toggle, ":<C-u>lua MiniReverse.toggle('visual')<CR>", {
			desc = "反转选中的内容",
			silent = true,
		})
	end
end

-- 创建自动命令
H.create_autocommands = function()
	local augroup = vim.api.nvim_create_augroup("MiniReverse", { clear = true })
end

-- 检查是否禁用
H.is_disabled = function()
	return vim.g.minireverse_disable == true or vim.b.minireverse_disable == true
end

-- 获取目标内容范围
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

-- 获取光标下的单词/符号（彻底修复 iskeyword 问题）
H.get_cursor_word = function()
	-- 方法改进：不修改 iskeyword，直接通过正则匹配获取单词和符号
	local line = vim.api.nvim_get_current_line()
	local cursor_col = vim.api.nvim_win_get_cursor(0)[2] -- 0-based

	-- 匹配单词（字母、数字、下划线）和符号（其他字符）
	-- 正则模式：匹配单词或连续符号
	local pattern = "[a-zA-Z0-9_]+|[<>!=]=?|[-+*/]"

	-- 遍历所有匹配项，找到包含光标位置的项
	for start, finish in line:gmatch("()(" .. pattern .. ")()") do
		-- 转换为 0-based 索引
		local start_idx = start - 1
		local end_idx = finish - 2

		-- 检查光标是否在当前匹配项范围内
		if cursor_col >= start_idx and cursor_col <= end_idx then
			return line:sub(start, finish - 1)
		end
	end

	-- 如果没找到匹配，返回光标位置的单个字符
	return line:sub(cursor_col + 1, cursor_col + 1)
end

-- 在行中查找单词位置
H.find_word_in_line = function(line, word, col)
	local len = #word
	local search_start = math.max(1, col - len + 1) -- 1-based
	local search_end = math.min(#line, col + len)
	local search_str = line:sub(search_start, search_end)

	local start_in_search, end_in_search = search_str:find(word, 1, true)
	if not start_in_search then
		return nil
	end

	local start_col = search_start + start_in_search - 2 -- 转换为 0-based
	local end_col = search_start + end_in_search - 1
	return start_col, end_col
end

-- 获取反转后的值
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

-- 设置光标位置
H.set_cursor = function(line, col)
	vim.api.nvim_win_set_cursor(0, { line, col - 1 })
end

-- 显示提示信息
H.message = function(msg)
	if not MiniReverse.config.silent then
		vim.notify("[mini.reverse] " .. msg, vim.log.levels.INFO)
	end
end

-- 类型检查
H.check_type = function(name, val, expected_type)
	if type(val) ~= expected_type then
		error(("mini.reverse: %s 必须是 %s 类型，实际是 %s"):format(name, expected_type, type(val)))
	end
end

return MiniReverse
