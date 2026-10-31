# folder-notes.yazi

[![Yazi](https://img.shields.io/badge/Yazi-%E2%89%A5%2026.8.15-blue)](https://github.com/sxyazi/yazi)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

一个 [Yazi](https://github.com/sxyazi/yazi) 插件：给**每个文件夹（文件也支持）显示用途备注**，
并且可以直接在 Yazi 里添加、修改、删除这些备注。

[English](README.md) | 简体中文

```
  Downloads ▏安装包、临时文件           - 2026-10-30 20:51
  Pictures  ▏截图、壁纸                 - 2026-10-30 17:54
  Projects                              - 2026-10-30 17:54
  ...

  ccjjxl@arch:~/Pictures (截图、壁纸)
```

## 功能

- **列表内联备注** —— 备注直接跟在文件夹名后面（默认），一眼就能看出每个目录是干什么的。
- **可选的右侧备注列** —— 也可以用独立的 linemode 列显示备注。
- **状态栏** —— 光标悬停项的完整备注（列表里被截断时看这里）。
- **标题栏** —— 当前目录自己的备注，随时知道自己在哪。
- **一个按键**就能添加 / 修改 / 删除备注，输入框留空即删除。
- **纯文本备注文件** —— 可以手写；插件保存时保留注释和顺序；文件被外部修改后自动重新加载。
- **支持主题** —— 备注样式、前缀都可以在 `theme.toml` 里改。
- **一键开关** —— 临时隐藏所有备注。

## 环境要求

- Yazi **26.8.15** 或更新版本。

## 安装

### 通过 `ya pkg`

```bash
ya pkg add ccjjxl/folder-notes
```

### 手动安装

```bash
git clone https://github.com/ccjjxl/folder-notes.yazi.git \
  ~/.config/yazi/plugins/folder-notes.yazi
```

如果要边改边用，建议软链接一份 checkout：

```bash
mkdir -p ~/.config/yazi/plugins
ln -sfn /path/to/folder-notes.yazi ~/.config/yazi/plugins/folder-notes.yazi
```

然后在 `~/.config/yazi/init.lua` 里启用：

```lua
require("folder-notes"):setup()
```

### 快捷键

`~/.config/yazi/keymap.toml`：

```toml
[[mgr.prepend_keymap]]
on   = "M"
run  = "plugin folder-notes -- set"
desc = "为光标所在项设置/编辑备注"

[[mgr.prepend_keymap]]
on   = [ "g", "M" ]
run  = "plugin folder-notes -- set-cwd"
desc = "为当前目录设置/编辑备注"

[[mgr.prepend_keymap]]
on   = "<C-n>"
run  = "plugin folder-notes -- toggle"
desc = "显示/隐藏文件夹备注"
```

## 使用

| 按键 | 作用 |
| --- | --- |
| `M` | 编辑光标所在项的备注；提交空值即删除。 |
| `g M` | 编辑当前目录本身的备注（刚进入某个目录时很方便）。 |
| `<C-n>` | 临时显示 / 隐藏所有备注。 |

打开输入框时会**预填已有备注**，可以直接追加或清空。保存后立即写入文件并刷新界面。

备注对**文件**同样有效 —— 想给某个重要文件写点说明也完全可以。

## 备注文件

默认位置：`~/.config/yazi/folder-notes.conf`（可以通过 `file` 选项修改）。

```conf
# 以 # 开头是注释，空行会被忽略
~/Downloads        = 安装包、临时文件，定期清理
/data/Developments = 开发项目：按语言/用途分类
/mnt/usb/backup    = 移动硬盘：每月初备份一次
```

规则：

- 一行一条：`路径 = 备注`。只按**第一个** `=` 分割，所以备注里可以有 `=`、空格、标点、中文等。
- 路径支持绝对路径和 `~/` 开头（展开为用户主目录）；结尾的 `/` 可写可不写。
- 路径是字面量，不支持通配符 / Lua 模式。
- 备注是单行的；保存时换行会被替换成空格。
- 保存只会改动匹配的那一行：注释、顺序和其它条目都会保留。
- 备注按**绝对路径**匹配，所以文件夹改名/移动后备注不会跟着走；软链接的文件夹有自己独立的备注。

## 配置

所有选项都是可选的：

```lua
require("folder-notes"):setup {
	file = "~/.config/yazi/folder-notes.conf", -- 备注文件
	inline = true,                             -- 在文件名后面显示备注
	inline_width = 0,                          -- 内联备注最大宽度（0 = 不预截断，交给 yazi 按空间裁剪）
	linemode = false,                          -- 额外在右侧独立一列显示备注
	linemode_width = 20,                       -- 右侧列最大宽度
	status = true,                             -- 状态栏显示悬停项备注
	status_width = 80,                         -- 状态栏最大宽度
	header = true,                             -- 标题栏显示当前目录备注
	header_width = 48,                         -- 标题栏最大宽度
	shown = true,                              -- 启动时是否显示
	order = 1600,                              -- linemode / 标题栏子项的排序权重
}
```

| 选项 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `file` | string | `~/.config/yazi/folder-notes.conf` | 备注文件路径，支持 `~/`。 |
| `inline` | boolean | `true` | 在列表中把备注跟在文件名后面。 |
| `inline_width` | integer | `0` | 内联备注最大宽度（单元格）。`0` = 不预截断，由 yazi 按面板宽度裁剪。 |
| `linemode` | boolean | `false` | 额外在右侧 linemode 列显示备注。 |
| `linemode_width` | integer | `20` | 右侧列最大宽度（单元格）。 |
| `status` | boolean | `true` | 状态栏显示悬停项备注。 |
| `status_width` | integer | `80` | 状态栏备注最大宽度。 |
| `header` | boolean | `true` | 标题栏显示当前目录备注。 |
| `header_width` | integer | `48` | 标题栏备注最大宽度。 |
| `shown` | boolean | `true` | 启动时是否显示备注。 |
| `order` | integer | `1600` | linemode / 标题栏子项的排序权重（和其它插件冲突时可改）。 |

## 命令

| 命令 | 说明 |
| --- | --- |
| `plugin folder-notes` | 显示 / 隐藏备注（等同于 `-- toggle`）。 |
| `plugin folder-notes -- set` | 设置 / 编辑光标所在项的备注，留空删除。 |
| `plugin folder-notes -- set-cwd` | 设置 / 编辑当前目录的备注。 |
| `plugin folder-notes -- delete` | 删除光标所在项的备注。 |
| `plugin folder-notes -- reload` | 重新加载备注文件。 |
| `plugin folder-notes -- edit` | 用 `$EDITOR` 打开备注文件。 |

每次目录加载完成后插件也会自动重读备注文件，所以外部修改会在你切换目录时立刻生效。

## 主题

`~/.config/yazi/theme.toml`：

```toml
[folder-notes]
# 备注文字样式（默认暗灰 + 斜体）
note = { fg = "darkgray", italic = true }
# 备注前面的前缀，设为 "" 则直接显示备注
prefix = "▏"
```

## 小技巧

- **备注尽量写短。** 内联备注和文件名共享空间，像 `存档项目`、`backup` 这样的标签就够用；
  写长了也没关系，状态栏和标题栏会显示更完整的版本。
- **面板太窄？** 按 `<C-n>` 一键隐藏；或者 `inline = false` 只在状态栏 / 标题栏显示；
  或者 `linemode = true, inline = false` 改成右侧独立一列；也可以调 `mgr.ratio` 给当前面板多点空间。
- **标注哪个路径？** `M` 标注光标所在的子项（在父目录里浏览时用），`g M` 标注自己当前所在的目录。
- **纳入版本管理。** `folder-notes.conf` 就是纯文本，可以直接和 dotfiles 一起提交。

## 实现说明

插件只是给 Yazi 现有组件挂了一些子项，不修改任何内置组件：

- 通过 `Entity`（内联备注）、`Linemode`（可选列）、`Status`、`Header` 的 `children_add` 注入内容。
- 备注读写只用 Lua 的 `io`，不启动任何外部命令。
- Yazi 的插件入口和负责渲染的 UI 运行在**不同的 Lua 实例**里，所以共享状态（已加载的备注、
  显示开关）都通过 `ya.sync()` 在主实例里更新，再调用 `ui.render()`。
- 订阅 `load` 事件重读备注文件，外部修改后无需手动刷新。

## 开发

```bash
git clone https://github.com/ccjjxl/folder-notes.yazi.git
ln -sfn "$PWD/folder-notes.yazi" ~/.config/yazi/plugins/folder-notes.yazi
```

Yazi 启动时会缓存插件代码，修改 `main.lua` 后需要重启 Yazi（只改备注文件的话执行
`plugin folder-notes -- reload` 即可）。

## 许可

[MIT](LICENSE)
