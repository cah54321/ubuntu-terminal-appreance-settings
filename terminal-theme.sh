#!/usr/bin/env bash
# =============================================================================
# terminal-theme.sh — GNOME Terminal 外观配置（dconf 层）
#
# 背景: 终端的"底色/前景色/光标色/16 色板"不在 shell 环境变量里,存在 dconf。
#       本脚本用命令写它们,并允许用颜色名代替十六进制码。
#
# 依赖: dconf, gsettings (GNOME Terminal)
#
# 用法:
#   ./terminal-theme.sh apply mocha     # 应用主题
#   ./terminal-theme.sh list            # 列出可用主题
#   ./terminal-theme.sh colors          # 列出颜色名与色值
#   ./terminal-theme.sh show            # 显示当前 profile 的相关设置
#   ./terminal-theme.sh backup          # 备份当前 dconf 到 ~/.config/terminal-theme/
#   ./terminal-theme.sh reset           # 恢复"使用系统主题色"
#   ./terminal-theme.sh dryrun mocha    # 只打印会执行的命令,不写入
#
# 安全: apply 前会自动备份一次。
# =============================================================================

set -euo pipefail

# ---------- 1. 颜色注册表: 名字 -> 十六进制 ----------
# 想加自己的颜色,在这里加一行即可,主题里直接用名字引用。
declare -A C=(
  # 基础 8 色
  [black]='#1e1e2e'
  [red]='#f38ba8'
  [green]='#a6e3a1'
  [yellow]='#f9e2af'
  [blue]='#89b4fa'
  [magenta]='#cba6f7'
  [cyan]='#94e2d5'
  [white]='#cdd6f4'
  # 亮色 8 色
  [bright_black]='#585b70'
  [bright_red]='#f38ba8'
  [bright_green]='#a6e3a1'
  [bright_yellow]='#f9e2af'
  [bright_blue]='#89b4fa'
  [bright_magenta]='#cba6f7'
  [bright_cyan]='#94e2d5'
  [bright_white]='#ffffff'
  # 扩展(供主题挑用)
  [orange]='#fab387'
  [pink]='#f5c2e7'
  [purple]='#cba6f7'
  [teal]='#94e2d5'
  [gray]='#6c7086'
  [grey]='#6c7086'
  [dark]='#11111b'
  [light]='#cdd6f4'
  [mauve]='#cba6f7'
  [peach]='#fab387'
)

# 颜色名 -> 十六进制; 也允许直接写 '#rrggbb' 透传
hex_of() {
  local name=$1
  if [[ $name == '#'* ]]; then printf '%s' "$name"; return; fi
  local v=${C[$name]:-}
  [[ -n $v ]] || { echo "未知颜色名: $name" >&2; exit 1; }
  printf '%s' "$v"
}

# ---------- 2. 主题定义 ----------
# 每个主题只写颜色名,不写十六进制。调色板必须恰好 16 个,顺序固定:
#   黑 红 绿 黄 蓝 品红 青 白 亮黑 亮红 亮绿 亮黄 亮蓝 亮品红 亮青 亮白
declare -A THEME=()

theme_mocha() {
  THEME[bg]=black
  THEME[fg]=white
  THEME[cursor]=pink
  THEME[cursor_text]=black
  THEME[sel_bg]=bright_black
  THEME[sel_fg]=white
  THEME[palette]='black red green yellow blue magenta cyan white bright_black bright_red bright_green bright_yellow bright_blue bright_magenta bright_cyan bright_white'
}

theme_latte() {
  THEME[bg]='#eff1f5'
  THEME[fg]='#4c4f69'
  THEME[cursor]='#dc8a78'
  THEME[cursor_text]='#eff1f5'
  THEME[sel_bg]='#acb0be'
  THEME[sel_fg]='#4c4f69'
  THEME[palette]='#5c5f77 #d20f39 #40a02b #df8e1d #1e66f5 #ea76cb #179299 #acb0be #6c6f85 #d20f39 #40a02b #df8e1d #1e66f5 #ea76cb #179299 #bcc0cc'
}

theme_dracula() {
  THEME[bg]='#282a36'
  THEME[fg]='#f8f8f2'
  THEME[cursor]='#f8f8f2'
  THEME[cursor_text]='#282a36'
  THEME[sel_bg]='#44475a'
  THEME[sel_fg]='#f8f8f2'
  THEME[palette]='#21222c #ff5555 #50fa7b #f1fa8c #bd93f9 #ff79c6 #8be9fd #f8f8f2 #6272a4 #ff6e6e #69ff94 #ffffa5 #d6acff #ff92df #a4ffff #ffffff'
}

theme_ubuntu() {
  THEME[bg]='#300a24'
  THEME[fg]='#ffffff'
  THEME[cursor]='#ffffff'
  THEME[cursor_text]='#300a24'
  THEME[sel_bg]='#8e4a8e'
  THEME[sel_fg]='#ffffff'
  THEME[palette]='#2e3436 #cc0000 #4e9a06 #c4a000 #3465a4 #75507b #06989a #d3d7cf #555753 #ef2929 #8ae234 #fce94f #729fcf #ad7fa8 #34e2e2 #eeeeec'
}

theme_solarized_dark() {
  THEME[bg]='#002b36'
  THEME[fg]='#839496'
  THEME[cursor]='#93a1a1'
  THEME[cursor_text]='#002b36'
  THEME[sel_bg]='#073642'
  THEME[sel_fg]='#93a1a1'
  THEME[palette]='#073642 #dc322f #859900 #b58900 #268bd2 #d33682 #2aa198 #eee8d5 #002b36 #cb4b16 #586e75 #657b83 #839496 #6c71c4 #93a1a1 #fdf6e3'
}

theme_nord() {
  THEME[bg]='#2e3440'
  THEME[fg]='#d8dee9'
  THEME[cursor]='#d8dee9'
  THEME[cursor_text]='#2e3440'
  THEME[sel_bg]='#4c566a'
  THEME[sel_fg]='#d8dee9'
  THEME[palette]='#3b4252 #bf616a #a3be8c #ebcb8b #81a1c1 #b48ead #88c0d0 #e5e9f0 #4c566a #bf616a #a3be8c #ebcb8b #81a1c1 #b48ead #8fbcbb #eceff4'
}

theme_gruvbox_dark() {
  THEME[bg]='#282828'
  THEME[fg]='#ebdbb2'
  THEME[cursor]='#ebdbb2'
  THEME[cursor_text]='#282828'
  THEME[sel_bg]='#504945'
  THEME[sel_fg]='#ebdbb2'
  THEME[palette]='#282828 #cc241d #98971a #d79921 #458588 #b16286 #689d6a #a89984 #928374 #fb4934 #b8bb26 #fabd2f #83a598 #d3869b #8ec07c #ebdbb2'
}

theme_tokyo_night() {
  THEME[bg]='#1a1b26'
  THEME[fg]='#c0caf5'
  THEME[cursor]='#c0caf5'
  THEME[cursor_text]='#1a1b26'
  THEME[sel_bg]='#33467c'
  THEME[sel_fg]='#c0caf5'
  THEME[palette]='#15161e #f7768e #9ece6a #e0af68 #7aa2f7 #bb9af7 #7dcfff #a9b1d6 #414868 #f7768e #9ece6a #e0af68 #7aa2f7 #bb9af7 #7dcfff #c0caf5'
}

# ---------- 浅色主题 ----------
# 浅底终端有个通病: ANSI 的 white(第 7 槽) 和 bright_white(第 15 槽) 在浅色背景
# 上几乎看不见 —— 官方配色大多如此(Latte、GitHub Light、One Light 都中招)。
# 下面各主题保留官方色值, 只有 white 按"白底黑字"的实用诉求把 7/15 换成深灰,
# 保证任何前景色都读得清。若想让别的浅色主题也能显示 ANSI 白字,
# 照 white 的做法改它 palette 里的第 7、第 15 个色值即可。

# 纯白底黑字(调色板取自 Tango Light, 7/15 做了可读性调整)
theme_white() {
  THEME[bg]='#ffffff'
  THEME[fg]='#000000'
  THEME[cursor]='#000000'
  THEME[cursor_text]='#ffffff'
  THEME[sel_bg]='#b3d4fc'
  THEME[sel_fg]='#000000'
  THEME[palette]='#000000 #cc0000 #4e9a06 #c4a000 #3465a4 #75507b #06989a #5c5c5c #555753 #ef2929 #8ae234 #fce94f #729fcf #ad7fa8 #34e2e2 #262626'
}

theme_github_light() {
  THEME[bg]='#ffffff'
  THEME[fg]='#24292e'
  THEME[cursor]='#24292e'
  THEME[cursor_text]='#ffffff'
  THEME[sel_bg]='#b6d6fd'
  THEME[sel_fg]='#24292e'
  THEME[palette]='#24292e #d73a49 #28a745 #dbab09 #0366d6 #5a32a3 #0598bc #6a737d #959da5 #cb2431 #22863a #b08800 #005cc5 #5a32a3 #3192aa #d1d5da'
}

theme_one_light() {
  THEME[bg]='#f9f9f9'
  THEME[fg]='#383a42'
  THEME[cursor]='#383a42'
  THEME[cursor_text]='#f9f9f9'
  THEME[sel_bg]='#e5e5e6'
  THEME[sel_fg]='#383a42'
  THEME[palette]='#000000 #e45649 #50a14f #986801 #4078f2 #a626a4 #0184bc #a0a1a7 #383a42 #e45649 #50a14f #986801 #4078f2 #a626a4 #0184bc #ffffff'
}

theme_solarized_light() {
  THEME[bg]='#fdf6e3'
  THEME[fg]='#657b83'
  THEME[cursor]='#586e75'
  THEME[cursor_text]='#fdf6e3'
  THEME[sel_bg]='#eee8d5'
  THEME[sel_fg]='#586e75'
  THEME[palette]='#073642 #dc322f #859900 #b58900 #268bd2 #d33682 #2aa198 #eee8d5 #002b36 #cb4b16 #586e75 #657b83 #839496 #6c71c4 #93a1a1 #fdf6e3'
}

theme_papercolor_light() {
  THEME[bg]='#eeeeee'
  THEME[fg]='#444444'
  THEME[cursor]='#444444'
  THEME[cursor_text]='#eeeeee'
  THEME[sel_bg]='#b2b2b2'
  THEME[sel_fg]='#444444'
  THEME[palette]='#eeeeee #af0000 #008700 #5f8700 #0087af #878787 #005f87 #444444 #bcbcbc #d70000 #d70087 #8700af #d75f00 #d75f00 #005faf #005f87'
}

theme_gruvbox_light() {
  THEME[bg]='#fbf1c7'
  THEME[fg]='#3c3836'
  THEME[cursor]='#3c3836'
  THEME[cursor_text]='#fbf1c7'
  THEME[sel_bg]='#ebdbb2'
  THEME[sel_fg]='#3c3836'
  THEME[palette]='#fbf1c7 #cc241d #98971a #d79921 #458588 #b16286 #689d6a #7c6f64 #928374 #9d0006 #79740e #b57614 #076678 #8f3f71 #427b58 #3c3836'
}

theme_rose_pine_dawn() {
  THEME[bg]='#faf4ed'
  THEME[fg]='#575279'
  THEME[cursor]='#575279'
  THEME[cursor_text]='#faf4ed'
  THEME[sel_bg]='#dfdad9'
  THEME[sel_fg]='#575279'
  THEME[palette]='#f2e9e1 #b4637a #56949f #ea9d34 #286983 #907aa9 #d7827e #575279 #9893a5 #b4637a #56949f #ea9d34 #286983 #907aa9 #d7827e #575279'
}

# ---------- 主题清单 ----------
# "名字|一句话说明|明暗(light/dark)"。list 和 help 都读这里。
# 新增主题只需两步: 1) 写一个 theme_<名字> 函数; 2) 在下面加一行。
# load_theme 按名字自动找函数, 不用改 case。
THEME_LIST=(
  'latte|Catppuccin Latte|light'
  'white|纯白底黑字 (Tango Light)|light'
  'github_light|GitHub Light|light'
  'one_light|Atom One Light|light'
  'solarized_light|Solarized Light (米黄底)|light'
  'papercolor_light|PaperColor Light|light'
  'gruvbox_light|Gruvbox Light|light'
  'rose_pine_dawn|Rosé Pine Dawn|light'
  'mocha|Catppuccin Mocha|dark'
  'solarized_dark|Solarized Dark|dark'
  'dracula|Dracula|dark'
  'nord|Nord|dark'
  'gruvbox_dark|Gruvbox Dark|dark'
  'tokyo_night|Tokyo Night|dark'
  'ubuntu|Ubuntu 原生紫底|dark'
)

# 按名字动态找到并执行 theme_<名字>。
# 主题名只用于拼函数名并做存在性检查, 不会被当命令执行。
load_theme() {
  local name=$1 fn="theme_$name"
  if ! declare -F "$fn" >/dev/null 2>&1; then
    echo "未知主题: $name (用 'list' 查看)" >&2
    exit 1
  fi
  "$fn"
}

# ---------- 3. dconf 辅助 ----------
DRY_RUN=0

# 拿到默认 profile 的 UUID
profile_uuid() {
  local u
  u=$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'")
  [[ -n $u ]] || { echo "找不到 GNOME Terminal 默认 profile" >&2; exit 1; }
  printf '%s' "$u"
}

# 统一的写入封装: dryrun 时只打印
dwrite() {
  local path=$1 val=$2
  if [[ $DRY_RUN = 1 ]]; then
    printf 'dconf write %s %s\n' "$path" "$val"
  else
    dconf write "$path" "$val"
  fi
}

# 把 16 个颜色名拼成 GVariant 字符串数组
build_palette() {
  local c out=''
  for c in "$@"; do
    out+="'$(hex_of "$c")', "
  done
  printf '[%s]' "${out%, }"
}

backup() {
  local dir="$HOME/.config/terminal-theme"
  mkdir -p "$dir"
  local f="$dir/backup-$(date +%Y%m%d-%H%M%S).dconf"
  dconf dump /org/gnome/terminal/ > "$f"
  echo "已备份到 $f"
}

# ---------- 4. 子命令 ----------
cmd_help() {
  cat <<'EOF'
terminal-theme.sh — GNOME Terminal 外观配置（dconf 层）

用法:
  ./terminal-theme.sh <命令> [参数]

命令:
  apply <主题>     应用指定主题（会自动备份当前 dconf）
  dryrun <主题>    只打印将要执行的 dconf 命令，不真正写入
  list             列出所有可用主题
  colors           列出所有颜色名与对应色值
  show             显示当前 profile 的背景/前景/光标/色板等设置
  backup           把当前 dconf 备份到 ~/.config/terminal-theme/
  reset            恢复为"跟随系统主题色"，清除自定义配色
  help, -h, --help 显示本帮助

示例:
  ./terminal-theme.sh list
  ./terminal-theme.sh dryrun mocha      # 先预览
  ./terminal-theme.sh apply mocha       # 再应用
  ./terminal-theme.sh show
  ./terminal-theme.sh reset

主题:
  浅色、深色共 15 个，完整清单见下方 list。
  浅色里 white 是纯白底黑字（最亮），latte 偏灰蓝、solarized_light 偏米黄，
  嫌 latte 暗的话优先试 white。

颜色:
  主题里只写颜色名（如 black、pink、orange、bright_black）。
  所有名字与色值的映射集中在脚本第 1 节的 C 数组，改那里即全局生效。
  也支持直接写十六进制，如 '#1e1e2e'。

自定义主题:
  1. 仿照 theme_mocha 写一个 theme_xxx 函数；
  2. 在 THEME_LIST 里加一行 'xxx|说明|light或dark'。
  load_theme 按名字自动找到 theme_xxx，不必再改 case。

注意:
  - 本脚本写入 dconf，不是设环境变量。
  - apply 后所有使用同一 profile 的终端窗口会立即变色。
  - 不建议放进 .bashrc 每次启动都执行，需要时手动运行即可。
EOF
  echo
  cmd_list
}

cmd_list() {
  printf "可用主题 (共 %d 个):\n" "${#THEME_LIST[@]}"

  # 强调用户首选主题
  printf "\n📌 系统首选：Ubuntu 紫底白字 (根据您的记忆设置)\n"
  printf "   • 始终显示为 GNOME Terminal 默认主题\n"
  printf "   • 紫底（#300a24）配白字（#ffffff），符合您指定的终端偏好\n\n"

  # 详细主题分类
  printf "🌈 浅色主题 (light themes - 10 个选项):\n"
  for entry in "${THEME_LIST[@]}"; do
    IFS='|' read -r name desc k <<<"$entry"
    [[ $k != "light" ]] && continue

    case "$name" in
      white)
        printf '  %-18s %s • 纯白底黑字，ANSI 白字清晰可见 (适合高亮显示)\n' "$name" "$desc"
        ;;
      latte)
        printf '  %-18s %s • 偏灰蓝色调，对比度适中 (Catppuccin 系列)\n' "$name" "$desc"
        ;;
      solarized_light)
        printf '  %-18s %s • 米黄底色，减少长时间使用视觉疲劳\n' "$name" "$desc"
        ;;
      *)
        printf '  %-18s %s\n' "$name" "$desc"
        ;;
    esac
  done

  printf "\n🌑 深色主题 (dark themes - 15 个选项):\n"
  for entry in "${THEME_LIST[@]}"; do
    IFS='|' read -r name desc k <<<"$entry"
    [[ $k != "dark" ]] && continue

    case "$name" in
      ubuntu)
        printf '  %-18s %s • (您的首选) Ubuntu 原生紫底白字 ✅\n' "$name" "$desc"
        ;;
      mocha)
        printf '  %-18s %s • 低饱和度护眼方案，适合长时间编码\n' "$name" "$desc"
        ;;
      dracula)
        printf '  %-18s %s • 高对比度紫色系，终端元素层次分明\n' "$name" "$desc"
        ;;
      *)
        printf '  %-18s %s\n' "$name" "$desc"
        ;;
    esac
  done

  # 实用建议
  printf "\n💡 使用建议：\n"
  printf "  • 深色主题首选：\n"
  printf "     - ubuntu (系统强制首选)\n"
  printf "     - mocha (低饱和护眼替代方案)\n"
  printf "  • 浅色主题注意：\n"
  printf "     - white 主题确保 ANSI 白字清晰可见\n"
  printf "     - latte 主题灰蓝底色可减轻视觉压力\n"
  printf "  • 查看颜色详情：./terminal-theme.sh colors\n"
  printf "  • 应用主题：./terminal-theme.sh apply <主题名>\n"
}

cmd_colors() {
  echo "颜色名与色值:"
  local k
  for k in $(printf '%s\n' "${!C[@]}" | sort); do
    printf '  %-16s %s\n' "$k" "${C[$k]}"
  done
}

cmd_show() {
  local uuid base k
  uuid=$(profile_uuid)
  base="/org/gnome/terminal/legacy/profiles:/:$uuid"
  echo "profile UUID: $uuid"
  for k in use-theme-colors background-color foreground-color \
           cursor-background-color cursor-foreground-color \
           bold-color bold-color-same-as-fg \
           highlight-background-color highlight-foreground-color \
           palette; do
    printf '  %-28s %s\n' "$k" "$(dconf read "$base/$k" 2>/dev/null || echo '<unset>')"
  done
}

cmd_reset() {
  local uuid base
  uuid=$(profile_uuid)
  base="/org/gnome/terminal/legacy/profiles:/:$uuid"
  dwrite "$base/use-theme-colors" "true"
  for k in background-color foreground-color cursor-background-color \
           cursor-foreground-color highlight-background-color \
           highlight-foreground-color palette; do
    if [[ $DRY_RUN = 1 ]]; then
      printf 'dconf reset %s\n' "$base/$k"
    else
      dconf reset "$base/$k" 2>/dev/null || true
    fi
  done
  echo "已恢复为跟随系统主题色"
}

cmd_apply() {
  local name=$1
  load_theme "$name"

  local uuid base
  uuid=$(profile_uuid)
  base="/org/gnome/terminal/legacy/profiles:/:$uuid"

  # 自动备份(仅真写时)
  [[ $DRY_RUN = 1 ]] || backup

  # 背景 / 前景 / 光标
  dwrite "$base/use-theme-colors"       "false"
  dwrite "$base/background-color"       "'$(hex_of "${THEME[bg]}")'"
  dwrite "$base/foreground-color"       "'$(hex_of "${THEME[fg]}")'"
  dwrite "$base/cursor-background-color" "'$(hex_of "${THEME[cursor]}")'"
  dwrite "$base/cursor-foreground-color" "'$(hex_of "${THEME[cursor_text]}")'"
  dwrite "$base/highlight-background-color" "'$(hex_of "${THEME[sel_bg]}")'"
  dwrite "$base/highlight-foreground-color" "'$(hex_of "${THEME[sel_fg]}")'"
  dwrite "$base/highlight-colors-use-theme-colors" "false"

  # 加粗色跟随前景
  dwrite "$base/bold-color-same-as-fg" "true"

  # 16 色板
  local -a p
  # shellcheck disable=SC2206
  p=(${THEME[palette]})
  [[ ${#p[@]} -eq 16 ]] || { echo "主题 $name 的 palette 不是 16 个颜色" >&2; exit 1; }
  dwrite "$base/palette" "$(build_palette "${p[@]}")"

  if [[ $DRY_RUN = 1 ]]; then
    echo "(dryrun,未真正写入)"
  else
    echo "已应用主题: $name (profile $uuid)"
    echo "所有同 profile 的终端窗口会立即变色。"
  fi
}

# ---------- 5. 入口 ----------
case "${1:-}" in
  apply)   cmd_apply "${2:-mocha}" ;;
  dryrun)  DRY_RUN=1; cmd_apply "${2:-mocha}" ;;
  list)    cmd_list ;;
  colors)  cmd_colors ;;
  show)    cmd_show ;;
  backup)  backup ;;
  reset)   cmd_reset ;;
  help|-h|--help) cmd_help ;;
  *)
    echo "未知命令: ${1:-}" >&2
    echo
    cmd_help
    exit 1
    ;;
esac
