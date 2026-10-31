--- @since 26.8.15
---
--- folder-notes.yazi —— 给文件夹（也支持文件）加"用途备注"，并直接显示在 yazi 里。
---
--- 备注保存在一个纯文本文件里（默认 ~/.config/yazi/folder-notes.conf），格式：
---
---   # 以 # 开头是注释，空行会被忽略
---   ~/Downloads       = 下载目录：安装包、临时文件，定期清理
---   /data/Developments = 开发项目：按语言/用途分类
---   ~/Pictures        = 图片：截图、壁纸
---
--- 规则：
---   * 路径支持绝对路径和 ~/ 开头（~ 指用户主目录）
---   * 一行一条，第一个 = 之后的所有内容都算备注
---   * 备注本身可以包含空格、中文、= 等
---
--- 用法（命令行参数）：
---   plugin folder-notes                 显示/隐藏备注（toggle）
---   plugin folder-notes -- set          给"光标所在项"设置/编辑备注，留空则删除
---   plugin folder-notes -- set-cwd      给"当前目录"设置/编辑备注
---   plugin folder-notes -- delete       删除光标所在项的备注
---   plugin folder-notes -- reload       重新加载备注文件
---   plugin folder-notes -- edit         用 $EDITOR 打开备注文件
---
--- 显示位置（可在 setup 里开关）：
---   * inline    列表中直接跟文件夹名后面（默认开启，不另占一列）
---   * linemode  列表右侧单独一列（可选）
---   * status    状态栏（光标悬停项的备注）
---   * header    标题栏（当前目录的备注）

local M = {
	notes = {}, -- 归一化后的绝对路径 -> 备注
	shown = true,
	opts = {},
}

---------------------------------------------------------------------- 基础工具

local IS_WINDOWS = ya.target_os() == "windows"

-- 主目录只取一次（每帧都会做路径归一化，避免反复调用 getenv）
local HOME
local function home()
	if HOME == nil then
		HOME = os.getenv("HOME") or os.getenv("USERPROFILE") or ""
		if IS_WINDOWS then
			HOME = HOME:gsub("\\", "/")
		end
	end
	return HOME
end

local function config_dir()
	if IS_WINDOWS then
		return (os.getenv("APPDATA") or (home() .. "/AppData/Roaming")) .. "/yazi"
	end
	return (os.getenv("XDG_CONFIG_HOME") or (home() .. "/.config")) .. "/yazi"
end

---@param s string
---@return string
local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- 把路径展开 ~ 并去掉结尾多余的 /，作为内部使用的规范 key。
---@param path string
---@return string
local function normalize(path)
	if type(path) ~= "string" then
		return ""
	end
	path = trim(path)
	if IS_WINDOWS then
		-- 统一分隔符，避免同一路径出现两种写法
		path = path:gsub("\\", "/")
	end

	local h = home()
	if h ~= "" then
		if path == "~" then
			path = h
		elseif path:sub(1, 2) == "~/" then
			path = h .. path:sub(2)
		end
	end

	if #path > 1 then
		path = path:gsub("/+$", "")
	end
	return path
end

--- 写入文件时，主目录下的路径显示成 ~/...
---@param key string
---@return string
local function display_key(key)
	local h = home()
	if h ~= "" then
		if key == h then
			return "~"
		elseif key:sub(1, #h + 1) == h .. "/" then
			return "~" .. key:sub(#h + 1)
		end
	end
	return key
end

local function notify(content, level)
	ya.notify {
		title = "folder-notes",
		content = content,
		timeout = 3,
		level = level or "info",
	}
end

---------------------------------------------------------------------- 读写备注

---@param file string
---@return string[]
local function read_lines(file)
	local lines = {}
	local f = io.open(file, "r")
	if not f then
		return lines
	end
	for line in f:lines() do
		lines[#lines + 1] = line
	end
	f:close()
	return lines
end

--- 解析 "路径 = 备注"
---@param line string
---@return string? key
---@return string? note
local function parse_line(line)
	if line:match("^%s*#") or line:match("^%s*$") then
		return nil, nil
	end

	local lhs, rhs = line:match("^%s*([^=]+)%s*=%s*(.-)%s*$")
	if not lhs then
		return nil, nil
	end

	local key = normalize(lhs)
	if key == "" then
		return nil, nil
	end
	return key, rhs
end

---@param file string
---@return table<string, string>
local function load_notes(file)
	local notes = {}
	for _, line in ipairs(read_lines(file)) do
		local key, note = parse_line(line)
		if key and note and note ~= "" then
			notes[key] = note
		end
	end
	return notes
end

--- 更新备注文件中的一条记录（保留注释和其它行）。
--- value 为 nil 表示删除。
---@param file string
---@param key string 归一化后的路径
---@param value string?
---@return boolean ok
local function save_note(file, key, value)
	local lines = read_lines(file)

	-- 找到已存在的行（比较归一化后的路径）
	local idx
	for i, line in ipairs(lines) do
		local existing = line:match("^%s*([^=]+)%s*=")
		if existing and not existing:match("^%s*#") and normalize(existing) == key then
			idx = i
			break
		end
	end

	if value == nil then
		if idx then
			table.remove(lines, idx)
		end
	else
		local newline = display_key(key) .. " = " .. (value:gsub("\r?\n", " "))
		if idx then
			lines[idx] = newline
		else
			lines[#lines + 1] = newline
		end
	end

	local out, err = io.open(file, "w")
	if not out then
		notify("无法写入备注文件: " .. tostring(err), "error")
		return false
	end
	for _, line in ipairs(lines) do
		out:write(line, "\n")
	end
	out:close()
	return true
end

---------------------------------------------------------------------- 显示

local function update_theme()
	local t = th.folder_notes or {}
	-- 主题里可以写 [folder-notes] note = { fg = "darkgray", italic = true } / prefix = "▏"
	M.style = (t.note ~= nil and type(t.note) ~= "string") and t.note or ui.Style():fg("darkgray"):italic()
	M.prefix = (type(t.prefix) == "string") and t.prefix or "▏"
end

---@param path string
---@return string?
local function note_for(path)
	if not M.shown then
		return nil
	end
	local note = M.notes[normalize(path)]
	if not note or note == "" then
		return nil
	end
	return note
end

---@param text string
---@param max integer
---@return string
local function clip(text, max)
	if max and max > 0 then
		return ui.truncate(text, { max = max })
	end
	return text
end

-- 列表：备注直接跟在文件名后面（不额外占用右侧 linemode 列）
local function render_inline(self)
	local file = self._file
	if not file.in_current then
		return ""
	end

	local note = note_for(tostring(file.url))
	if not note then
		return ""
	end

	local text = clip(M.prefix .. note, M.opts.inline_width)
	if file.is_hovered then
		return ui.Line { " ", ui.Span(text) }
	end
	return ui.Line { " ", ui.Span(text):style(M.style) }
end

-- linemode 右侧备注列（可选的另一种显示方式）
local function render_linemode(self)
	local file = self._file
	if not file.in_current then
		return ""
	end

	local note = note_for(tostring(file.url))
	if not note then
		return ""
	end

	local text = clip(M.prefix .. note, M.opts.linemode_width)
	if file.is_hovered then
		return ui.Line { " ", ui.Span(text) }
	end
	return ui.Line { " ", ui.Span(text):style(M.style) }
end

-- 状态栏：显示光标悬停项的备注
local function render_status(self)
	local h = self._current.hovered
	if not h then
		return ""
	end

	local note = note_for(tostring(h.url))
	if not note then
		return ""
	end

	return ui.Line {
		"  ",
		ui.Span(clip(M.prefix .. note, M.opts.status_width)):style(M.style),
	}
end

-- 标题栏：显示当前目录的备注
local function render_header(self)
	local note = note_for(tostring(self._current.cwd))
	if not note then
		return ""
	end

	return ui.Line { "  ", ui.Span("(" .. clip(note, M.opts.header_width) .. ")"):style(M.style) }
end

---------------------------------------------------------------------- 交互操作
--
-- 注意：yazi 的插件入口（M:entry）运行在一个独立的 Lua 实例里，而负责渲染的
-- Linemode / Status / Header 运行在主 Lua 实例里，两者不共享 Lua 变量。
-- 所以共享状态（notes / shown）和 ui.render() 都必须通过 ya.sync 在主实例里操作。

local hovered = ya.sync(function()
	local h = cx.active.current.hovered
	return h and tostring(h.url) or nil
end)

local current_dir = ya.sync(function()
	return tostring(cx.active.current.cwd)
end)

local get_file = ya.sync(function(st)
	return st.file or ""
end)

local get_note = ya.sync(function(st, key)
	return st.notes[key] or ""
end)

--- 在主实例里更新状态 + 写文件 + 刷新界面；value 为空表示删除
local apply_note = ya.sync(function(st, key, value)
	value = (value ~= nil and value ~= "") and value or nil

	if value == nil then
		if st.notes[key] == nil then
			return "noop"
		end
		if not save_note(st.file, key, nil) then
			return "error"
		end
		st.notes[key] = nil
		ui.render()
		return "deleted"
	end

	if not save_note(st.file, key, value) then
		return "error"
	end
	st.notes[key] = value
	ui.render()
	return "saved"
end)

local toggle_notes = ya.sync(function(st)
	st.shown = not st.shown
	ui.render()
	return st.shown
end)

local reload_notes = ya.sync(function(st)
	st.notes = load_notes(st.file)
	ui.render()

	local n = 0
	for _ in pairs(st.notes) do
		n = n + 1
	end
	return n
end)

--- 给指定路径设置/编辑备注（输入为空则删除）
---@param path string?
local function set_entry(path)
	if not path or path == "" then
		notify("没有可标注的项", "warn")
		return
	end

	local key = normalize(path)
	local old = get_note(key)
	local value, event = ya.input {
		title = "备注 " .. ya.readable_path(path) .. ":",
		value = old,
		pos = { "top-center", y = 2, w = 60 },
	}
	if event ~= 1 then
		return
	end

	local result = apply_note(key, trim(value))
	if result == "saved" then
		notify("已保存备注: " .. ya.readable_path(path))
	elseif result == "deleted" then
		notify("已删除备注: " .. ya.readable_path(path))
	elseif result == "error" then
		notify("保存失败（写入备注文件出错）", "error")
	end
end

local function delete_entry(path)
	if not path or path == "" then
		notify("没有可标注的项", "warn")
		return
	end

	local result = apply_note(normalize(path), "")
	if result == "noop" then
		notify("该项还没有备注", "warn")
	elseif result == "deleted" then
		notify("已删除备注: " .. ya.readable_path(path))
	elseif result == "error" then
		notify("保存失败（写入备注文件出错）", "error")
	end
end

--- 用 $EDITOR 打开备注文件
local function edit_file()
	local file = get_file()
	if file == "" then
		return
	end

	local editor = os.getenv("EDITOR") or os.getenv("VISUAL") or "vi"
	local cmd = string.format("%s '%s'", editor, file:gsub("'", "'\\''"))
	ya.emit("shell", { run = cmd, block = true })
	notify("编辑完成后执行 -- reload 重新加载（切换目录时也会自动加载）")
end

---------------------------------------------------------------------- 入口

function M:setup(opts)
	opts = opts or {}

	M.opts = {
		file = opts.file or (config_dir() .. "/folder-notes.conf"),
		inline = opts.inline ~= false,
		linemode = opts.linemode == true,
		status = opts.status ~= false,
		header = opts.header ~= false,
		shown = opts.shown ~= false,
		order = opts.order or 1600,
		inline_width = opts.inline_width or 0, -- 0 = 不预截断，由 yazi 按剩余空间裁剪
		linemode_width = opts.linemode_width or 20,
		status_width = opts.status_width or 80,
		header_width = opts.header_width or 48,
	}
	M.file = normalize(M.opts.file)
	M.notes = load_notes(M.file)
	M.shown = M.opts.shown

	update_theme()

	ps.sub("theme", update_theme)
	-- 每次目录加载完成后自动重读备注文件（外部修改后无需手动 reload）
	ps.sub("load", function()
		M.notes = load_notes(M.file)
	end)

	if M.opts.inline then
		Entity:children_add(render_inline, 7000)
	end

	if M.opts.linemode then
		Linemode:children_add(render_linemode, M.opts.order)
	end

	if M.opts.status then
		-- 左侧：在文件名之后显示；如果和你的其它插件冲突，可改 order
		Status:children_add(render_status, 3500, Status.LEFT)
	end

	if M.opts.header then
		Header:children_add(render_header, M.opts.order, Header.LEFT)
	end
end

function M:entry(job)
	local action = (job and job.args and job.args[1]) or "toggle"

	if action == "toggle" then
		local shown = toggle_notes()
		notify(shown and "已显示文件夹备注" or "已隐藏文件夹备注")
	elseif action == "set" then
		set_entry(hovered())
	elseif action == "set-cwd" then
		set_entry(current_dir())
	elseif action == "delete" then
		delete_entry(hovered())
	elseif action == "reload" then
		notify(string.format("已重新加载 %d 条备注", reload_notes()))
	elseif action == "edit" then
		edit_file()
	else
		notify("未知参数: " .. tostring(action), "warn")
	end
end

return M
