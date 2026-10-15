# LESSONS — nvim-config

本 repo 的**專案級教訓**：踩過的坑，以及遇到它時該做什麼。

**讀取時機**（任一成立就先讀對應節，不要憑印象動手）：

- 升級 `nvim`／`tmux`
- 改 `ghostty.conf`／`tmux.conf`／`vimrc.lua`／`nvim.d/**`
- 改 `bin/**` 腳本，或接到「按了沒反應／顏色變怪／popup 一閃即關／pane 叫錯」的回報

> **規則本體在 `AGENTS.md`**；本檔只放「坑與其行動」，不重述規則。
> **跨專案通則不在這裡** —— 它們住 opencode-config 的 `memories/global/`（例：tmux 擴展鍵降級、design language、報告格式）。

---

## 1. 升級後必做（每一步都會靜默失敗）

依序執行，跳過任一步都不會報錯，只會在之後某個時刻以奇怪症狀出現。

1. **裝 `tree-sitter` CLI** —— 否則 `:TSUpdate` 只下載、不編譯，舊 `.so` 留著，query 之後才炸（例：`Invalid field name operator`）。
   ```bash
   npm install -g tree-sitter-cli --prefix ~/.local   # 確認 ~/.local/bin 在 PATH
   ```
2. **重建全部 parser**：`:TSUpdate`
3. **掃棄用 API**：`:checkhealth vim.deprecated` → 對照 §2
4. **重啟 nvim**，確認零 startup error
5. **改了 tmux binding 就重載 tmux** → §3.3

## 2. nvim 0.12 遷移

**總原則：加 alias，不要改 plugin 原始碼。** plugin 的改動會被 `:PackerSync` 抹掉。

### 2.1 棄用 API 對照表（唯一一份，其他處只指向本節）

放在 `vimrc.lua` 頂部：

```lua
vim.tbl_islist = vim.islist
vim.tbl_flatten = function(t) return vim.iter(t):flatten():totable() end
```

| 舊 | 新 |
|---|---|
| `vim.tbl_islist(t)` | `vim.islist(t)` |
| `vim.tbl_flatten(t)` | `vim.iter(t):flatten():totable()` |
| `vim.lsp.with(h, opts)` | 手寫 wrapper → §2.2 |
| `nvim-treesitter.ts_utils` | 內建 `vim.treesitter.*` → §2.2 |

**為什麼用 alias 而非逐個改 caller**：packer、bufferline、nvim-cmp、plenary、schemastore 都還在呼叫 `vim.tbl_islist`；改 caller 既脆弱又會被下次 `:PackerSync` 清掉，一行 alias 一次性解決。

### 2.2 LSP 專屬細節

- `vim.lsp.with()` 已棄用；替代**不是** `vim.lsp.config()`（那是設定 server 用的），而是手寫 wrapper：
  ```lua
  vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx)
    vim.lsp.handlers.hover(err, result, ctx, { border = "rounded" })
  end
  ```
- `lspconfig.setup` → `vim.lsp.config(server, {...})` 宣告 ＋ `vim.lsp.enable(server)` 啟用；keymap 改用全域 `LspAttach` autocmd（取代逐 server 的 `on_attach`）。Mason 只裝 binary，`mason-lspconfig.setup` 不再帶 `handlers`。
- `ts_utils` 移除：`ts.get_node_at_cursor()` → `vim.treesitter.get_node({ bufnr = 0 })`，但它在 0.12 **可能回 nil**；較穩的是 `root:named_descendant_for_range(row-1, col, row-1, col)`。`ts.get_node_text(node)` → `vim.treesitter.get_node_text(node, bufnr)`。
- capabilities 用 `require("cmp_nvim_lsp").default_capabilities()`，傳進 `vim.lsp.config()`。

## 3. tmux 3.8

### 3.1 `theme` 選項造成「偏白」

**症狀**：升 3.8 後，未被 config 顯式指定的顏色變偏白（最明顯是 popup 與 display-panes 邊框）。

**原因**：3.8 新增 server 選項 `theme`（`detect`｜`terminal`｜`light`｜`dark`），預設 `detect` 會依終端挑主題；未指定顏色改吃「主題色名」（`themedarkgrey` 等），逐名對應 `dark-theme-*`／`light-theme-*`。受影響預設：`popup-style`、`popup-border-style`、`menu-style`、`display-panes-border-style`。

**修法**：`set -s theme dark` ＋ 指定 `dark-theme-{black,dark-grey,light-grey,white}`；或 `set -s theme terminal`（沿用終端 ANSI 色＝3.7 以前行為）。可用色共 10 個（black/white/light-grey/dark-grey/green/yellow/red/blue/cyan/magenta）。

**驗證**：先在「會用到該色」的地方用**極端值**（如 `colour24`）確認管線有通，再收斂到目標值 —— 否則微調幾階根本看不出來。

**受影響的預設（皆吃主題色）**：`popup-style=bg=themedarkgrey,fg=themewhite`、`popup-border-style=bg=themedarkgrey,fg=themelightgrey`、`menu-style=bg=themedarkgrey,fg=themewhite`、`display-panes-border-style=bg=themedarkgrey,fg=themelightgrey`。色名（`themeblack`／`themedarkgrey`／`themelightgrey`…）逐名對應到 `dark-theme-dark-grey` 之類的 server 選項，共 10 名。

**本 repo 現值**：`set -s theme dark` ＋ `dark-theme-black=colour232`、`dark-theme-dark-grey=colour238`、`dark-theme-light-grey=colour250`、`dark-theme-white=colour255`。

### 3.2 `display-panes` 由 overlay 變成 per-pane mode

3.8 的 commit `1a02c9957c` 把 display-panes 從 overlay 改成 **panes-mode**：**不想用 mode 就等於不能用這個指令**。

- `-b`（非阻塞）被移除 → 舊 binding 會噴 `unknown flag -b`。3.8 旗標：`[-kNZ] [-d duration] [-s source-window] [-t target-pane] [template]`。
- **為何會 resize**：不給 `-Z` 時會 `window_zoom(wp)`（把 window 佈局換成只有該 pane），被放大的 pane 收 SIGWINCH → 全螢幕 TUI 會重排一次（shell 幾乎無感）。實測：`p0` 由 50x24 → 100x24，結束後還原。

| 旗標 | 外觀 | pane 尺寸 |
|---|---|---|
| 不給 `-Z` | 1:1 全版面 + 編號（像舊 overlay）| 會被 resize 兩次 |
| `-Z` | 整個 window 被縮圖塞進單一 pane | 不變 |

- **殘留 mode 的 bug**（upstream #5715）：panes-mode 屬 **pane** 而非 window → 每次切 pane 都新開一個、舊的不關。建議先退出：
  ```tmux
  bind-key -n M-J if-shell -F '#{==:#{pane_mode},panes-mode}' 'send q' \; select-pane -t :.- \; display-panes
  ```
- 3.8 沒有「直接 overlay」可用：upstream 明言要移除 overlay，剩下的 popup/menu 是單框且不透明，無法在各 pane 上分別作畫。

**原始碼位置**：實作在 `window-panes.c`（3.8 已刪 `cmd-display-panes.c`）。`window_panes_init` 把 `data->screen` 初始化成**目標 pane 的尺寸**；不給 `-Z` 時呼叫 `window_zoom(wp)`（原佈局存進 `saved_layout_root`）；pane 變大後由 `window_panes_resize()` 把畫布 resize 成整個 window，才能 1:1 重畫全部 pane。

### 3.3 設定重載與 binding 的兩個硬要求

tmux server 把 config 留在記憶體 → 改 `tmux.conf` 必須 `source-file` 才生效。

| 改了什麼 | 要重載？ |
|---|---|
| `tmux.conf` 的 binding | ✅ `source-file` |
| `bin/` 新增腳本 | ❌（PATH 已含）|
| 重新命名腳本（binding 引用舊名） | ✅ |
| `.zshrc`／`.bashrc` 的 PATH | ✅ 重啟 tmux server |

**兩個硬要求**：

1. **binding 一律用絕對路徑**。`run-shell` 用的是 **tmux server 啟動時的 PATH**，未必等於你 shell 的：
   ```tmux
   # 脆弱：bind-key -n C-o run-shell "toggle-opencode"
   bind-key -n C-o run-shell "$HOME/drake/nvim-config/bin/toggle-opencode '#{window_id}'"
   ```
2. **`'#{window_id}'` 是必要參數，不是裝飾**。沒有 target 時，toggle 內部的 `tmux display-message -p '#{window_id}'` 會對到「最活躍 client」→ 可能讀到別的 session 的 window → stash/restore 指錯 void session。

**查 binding**：`tmux list-keys | grep C-o`。❗ `list-keys` **沒有 `-n` 旗標**（tmux 3.7b 會回 `unknown flag`）。

**驗證選項值的陷阱**：`tmux show-options -g | grep <option>` **不是**可靠驗證 —— `show-options` 只列**非預設值**；`allow-passthrough` 更極端，即使設成非預設的 `on`，它**也不會出現在清單裡**（3.7b 實測 0 命中）。要 query 值一律用 `show-options -gv <option>`；要驗「config 那一行到底有沒有生效」，用**拋棄式 server**：

```bash
tmux -L probe -f /dev/null new-session -d
tmux -L probe set -g <option> <非預設值>
tmux -L probe source-file ~/.tmux.conf
tmux -L probe show-options -gv <option>   # 應回到 config 的值
tmux -L probe kill-server
```

## 4. 按鍵傳遞（terminal → tmux → pane）

### 4.1 `Ctrl+Shift+L` → opencode reset-session

**症狀**：在 opencode pane 按 `Ctrl+Shift+L`，得到**普通新 session**，不是 reset-session。

**根因**：`Ctrl+Shift+字母` 在 legacy 編碼**沒有位置**（`Ctrl+L` = 單一位元組 `0x0C`，shift 無處編碼），只能用 kitty 協議 CSI-u 表達（`ESC[108;6u`）。實測鏈路：

```text
Ghostty      需明確指定才會送 ESC[108;6u        （keybind=csi:108;6u）
tmux         解得成 C-S-l                        ✅ shift 到這裡還活著
tmux → pane  pane 回報 VT10x（未開擴展鍵）→ 重編碼成 0x0C   ❌ shift 死在這裡
opencode     收到 0x0C → 命中內建 session_new    → 開普通新 session
```

**修法（兩層，缺一不可）**：

1. `ghostty.conf`：`keybind = ctrl+shift+l=csi:108;6u`
2. `tmux.conf`：root binding `C-S-l`，用 `if-shell` 判斷焦點 pane 是否 opencode：
   - 是 → `send-keys -H 1b 5b 31 30 38 3b 36 75`（CSI-u 原樣灌進 pane）
   - 否 → `send-keys -H 0c`（維持舊行為，不搶鍵）

**為何不用 `extended-keys`**：`on` 無效（opencode 從不請求，所有 pane 恆為 `VT10x`）；`always` 技術上可行但**全域生效、無法 per-window**，且所有程式的修飾鍵回報方式一起改變（shell 會收到 escape 序列而非 legacy 位元組）；且 `extended-keys-format` 預設是 `xterm`，還得額外改成 `csi-u`。兩層 surgical 修法的爆炸半徑小得多。

**殘留風險**：① 兩層耦合 —— 任一層被移除會**靜默**退回「開普通新 session」（兩個檔案都有註解註明）；② `send-keys -H` 的位元組是硬編碼 CSI-u，opencode 若改鍵位解析方式要跟著改。

> 完整診斷順序與原理（含 `Ctrl+Tab` 的變體）→ opencode-config 的 `memories/global/tmux/ctrl-tab-and-extended-keys`。

> `extended-keys-format` 預設**實測為 `xterm`**（`^[[27;6;108~`），不是 opencode 認得的 csi-u —— 用 `always` 還得額外改 format。

### 4.2 鍵位分工：為什麼是這幾顆鍵（三層歸屬）

分工原則：**一個動作只由一層持有** —— terminal（Ghostty）／multiplexer（tmux）／app（opencode）。
跨層轉譯（terminal 編碼 → tmux 直通 → app 解讀）只在必要時做，且**只在最外層做一次**。

| 動作 | 鍵 | 由哪一層持有（檔案） |
|---|---|---|
| Ghostty 自己的 tab 切換 | `ctrl+shift+←/→` | Ghostty（`ghostty.conf` 的 `next_tab`／`previous_tab`，**明確寫出**不靠預設） |
| opencode session tab 切換 | `ctrl+tab`／`ctrl+shift+tab` | Ghostty 編碼 → tmux 直通 → opencode 預設 `Alt+Down/Up`（`ghostty.conf` 的 `csi:1;3B`／`csi:1;3A`） |
| opencode agent 循環 | `tab`／`shift+tab` | opencode（`cli.json` 的 `agent.cycle`；還原 V1 手感） |
| 開新 session | `ctrl+l` | opencode（`cli.json` 的 `session.new`） |
| 離開 opencode | `ctrl+q` | opencode（`cli.json` 的 `app.exit`；原含 `ctrl+c`／`ctrl+w`／`<leader>q`） |
| opencode 重置（開新 session ＋ 重載） | `ctrl+shift+l` | 見 §4.1 |
| opencode 服務重啟 | `ctrl+space` ＋ `ctrl+\``（兩個鍵名都綁） | opencode（`cli.json` 的 `service.restart`） |

**三個關鍵取捨（否決的替代方案）**：

1. **為何把 `ctrl+tab` 給 opencode session tab、`ctrl+shift+←/→` 給 Ghostty**（2026-10-12 交換）：
   原案相反（`ctrl+tab` 給 Ghostty）。改成現案的理由＝ Tab 系列更符合「切 tab」的直覺，且
   `ctrl+tab`／`ctrl+shift+tab` 與 `ctrl+shift+←/→` **同屬 Ghostty 能明確區分的類型**；
   底層路徑（Ghostty `csi:` → tmux 直通 → `Alt+Down/Up` → opencode session tab）
   在原案已實測可通 ⇒ 交換只重新指派觸發鍵，無新增風險。
2. **為何選方向鍵而非字母鍵**：`Ctrl+Shift+字母` 可能與 `Ctrl+字母` **同編碼**
   （例：`ctrl+shift+l` 長期無法確認可用），而 Ghostty 天生能區分「修飾鍵 ＋ 方向鍵」。
3. **為何 `service.restart` 要綁兩個名字**：tmux 會把收到的擴展鍵**降級（re-encode）**後才寫入 pane，
   pane 內程式看到的是 `ctrl+space` 而非反引號；裸終端（不經 tmux）才會送真正的反引號 ⇒ **兩個名字都綁可覆蓋兩種情境**。
   位元組層細節與隔離測試法請參閱指標 → `mem:global/tmux/ctrl-tab-and-extended-keys`。

**為何 Ghostty 設定檔納入本 repo**（2026-10-12）：
①該檔 3.7 KB、當日被改動多次，卻**完全不在任何 git repo**（真檔），備份只在 `/tmp`；
②本 repo 已是「終端 ＋ 編輯器設定」的家（`tmux.conf`、`kitty.conf` 皆 symlink）；
③檔名不是慣例的 `config` —— `strace` 實測 Ghostty 開啟的**就是** `config.ghostty`，
  故 symlink 必須沿用該檔名。

**驗證**：`ghostty +list-keybinds`（確認覆寫生效、symlink 被跟隨）。

## 5. 腳本與 UI

### 5.1 多層 script 除錯：每層獨立輸出

一條按鍵可能穿過 `nvim keymap → Lua → io.popen → tmux CLI → target pane`，任一層的錯在其他層都看不見（使用者只看到「沒反應」）。**原則：逐層加獨立 debug，不要用當前層的錯誤去猜下一層。** 每層只回答三題：這層到了嗎？收到什麼？傳出什麼？

| 層 | 手法 |
|---|---|
| Lua | `vim.notify("[layer] pane=" .. tostring(paneId), vim.log.levels.WARN)` |
| tmux CLI | `_G.run_cmd`（`nvim.d/my/utilities.lua`）已 `2>&1`，把回傳字串 surface 出來，不要猜 |
| 落地 | append 到 `/tmp/debug.log` |

**不要一次加滿**：從第一層開始，確認通了再往下一層。

### 5.2 pane 偵測用 marker，不用順序

> 範圍：**只限 nvim → tmux 的 `console_ctl` 層**（marker `leftpane`）。鍵位 toggle 用的是另一套（`bin/tmux-panes.sh` 的 `left-<type>` ＋ `pane_left` 幾何）→ `memories/global/tmux/pane-toggle-unified-model`。

**別用位置挑 pane**：`tmux list-panes | grep -v active | head -n1` 在 ≥3 個 pane 時會抓錯。正解是 marker：`console_ctl` 開 pane 時注入 `echo leftpane > /dev/null`，之後用 `#{pane_start_command}` 比對。

**兩條會咬人的規則**：

1. **不要剝掉 `%` 前綴**。`#{pane_id}` 是 `%37`，`%` 是 ID 的一部分；`gsub('%%','')` 會得到 `37` → `can't find pane: 37`。
2. **插值前先跳脫引號**。`run_cmd` 經 `io.popen` 進 `zsh -c '...'`，`cmd` 內未跳脫的 `"` 會破壞外層引號（`string.gsub(cmd, '"', '\\"')`）。

**三分支**：工具已在 → 關掉它；無 marker pane → `splitw -dh`；marker pane 是另一個工具 → `splitw -dv -t "<paneId>"` 再關掉舊的。

### 5.3 `fzf-tmux-popup` 的引號地雷

**症狀**：popup 一閃即關。**根因**：`opts=$(printf "%q " "${args[@]}")` ＋ 之後**未加引號展開** `"$fzf" $opts` → `%q` 插入的 `\` 不會被移除 → CLI args 含 `#`（hex 色）或空白時，fzf 收到 `bg+:\#1a5f68` → `invalid color specification` → 秒退。（實測：`--color='bg+:\#1a5f68'` exit 2；`bg+:#1a5f68` exit 0。）

**修法**：`eval \"$fzf $opts\"` 讓 `%q` 的跳脫被重新解析。**首選路徑**：走 `FZF_DEFAULT_OPTS`（以 `export` 寫進 argsf，再由 bash 重新解析）→ 反斜線正確還原、空白也保得住。

**`FZF_DEFAULT_OPTS` 的切分規則**：fzf 用 shell 規則切分該字串 → **尾隨空白會被當參數分隔符吃掉**（`--prompt=❯  ` 變成 `>fms`）。要保留空白**必須在字串內加引號**：`--prompt='❯  '`。

**popup 內不展開 tmux format**：`display-popup` 的 shell-command（以及 `-e`／`-T`）**不展開** `#{pane_index}` 之類的 format；要帶 format 值需用 `run-shell`（它會先展開）或其他外部通道。

**本 repo 現值**（`bin/open-project`）：

```bash
export FZF_DEFAULT_OPTS="--border=rounded --border-label=Projects --info=inline-right --prompt='❯  ' --pointer=${FZF_PTR:-🢖} --marker=✓ --color=fg:252,bg:#114b52,hl:114,fg+:255,bg+:${FZF_SELBG:-#1f1a1a},hl+:114,info:244,prompt:114,pointer:114,marker:114,spinner:114,header:244,border:#2b7d88,label:250"
```

tmux 端配合：`popup-border-lines none` + `popup-style bg=#114b52,fg=themewhite`；可覆寫通道 `FZF_PTR`（pointer）、`FZF_SELBG`（highlight 底）。

### 5.4 pane pointer／icon 選字：三個判準

1. **UCD `EastAsianWidth.txt`**：`N`=1 格、`W`=2 格、`A`=模糊（依終端）。
2. **tmux 實測佔格**（游標欄法，**必須有對照組**）：`printf 'XX<glyph>'; tmux display -p '#{cursor_x}'` → 欄位 − 2 = 佔格數；用 `x`(1)、`世`(2) 驗證方法有效。
3. **誰在畫它**：`fc-list ":charset=<碼位>" family`。由主字型畫 → 最穩；只有 fallback（如 Noto Sans Symbols2）→ 依賴單一來源。

**結論：箭頭無法「變大」。** 掃過箭頭／三角區塊，**沒有任何箭頭是 `Emoji_Presentation=Yes`**（＝沒有天生 2 格的箭頭）；大小完全由「哪個字型畫它」決定。要更大只有兩條路：① 換**填滿格子**的字符（`█` `▐` `e0b0`，由主字型畫、無 fallback 風險）；② 挑多來源涵蓋的字符，再調 ghostty 字型鏈順序讓「畫得大的字型」排前面。

現值：`bin/open-project` 的 `--pointer=${FZF_PTR:-🢖}`；`🢖`/`🡆` 的 fallback 來源都只有 Noto Sans Symbols2。

**實測（皆 1 格）**：`➤` U+27A4、`⮞` U+2B9E、`⮚` U+2B9A、`🢖` U+1F896、`🡆` U+1F846、`➜` U+279C 皆 EAW=N；`▶` U+25B6、`▌` U+258C 為 A（模糊），但 tmux 實測仍判 1 格。

### 5.5 Hererocks／LuaRocks

**錯誤**：`[packer.nvim] luarocks.lua:103: Failed to install hererocks`。**原因**：nvim 升級換 LuaJIT 版本後，版本字串不再被 hererocks 認得（`LuaJIT 2.1.1774638290` vs `-j 2.1.…`）。

**修法**：手動安裝並**只 pin major.minor**：
```bash
rm -rf ~/.cache/nvim/packer_hererocks/<new-version>
python3 ~/.cache/nvim/packer_hererocks/hererocks.py \
  -j 2.1 -r latest ~/.cache/nvim/packer_hererocks/<new-version>
```

**先問 rocks 是否真的需要**：`lua-cjson` 自 nvim 0.6 起已被 `vim.json` 取代；`f-strings` 只是裝飾性、沒有 plugin 依賴它。檢查 `nvim.d/my/plugin.lua` 的 `use_rocks` —— 沒人需要就刪掉那些行，整條 hererocks 依賴鏈一起消失。
