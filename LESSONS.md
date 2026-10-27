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
6. **跑 `bin/deps-audit`**（唯讀）：確認 plugin 未落後、config `require` 的模組全部解析成功、npm 無漂移
7. **跑 `bin/config-audit`**（唯讀）：確認沒有絕對家目錄路徑、overlay 載入線仍在檔尾、overlay 載得起來

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
| `require('vim.highlight').on_yank(opts)` | `vim.hl.on_yank(opts)` |

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

### 2.3 nvim-treesitter `main` 分支：`configs` 模組已消失（靜默失效）

**症狀**：啟動零錯誤，但 `.js`／`.py` **完全沒有 tree-sitter 高亮**，indent 也沒套用。畫面上仍有顏色（Vim regex syntax），所以看不出來。

**根因（兩層，缺一不可）**：

1. `main` 分支（nvim 0.12 必需）**已移除 `nvim-treesitter.configs`**。舊設定開頭 `pcall(require, "nvim-treesitter.configs")` 失敗 → 整份設定 `return`，`ensure_installed`／`highlight`／`indent` 全部沒生效。
2. `TS.setup()` 現在**只設定 parser 安裝路徑**，不註冊 autocmd、不開高亮。高亮與 indent 要自己接。
3. 附帶陷阱：`main` 分支把 query 放在 `<plugin>/runtime/queries/`；packer 安裝時 `runtime/` **不在 `runtimepath`** → `queries/{highlights,indents}.scm` 解析成 `nil`，即使接了 autocmd，indent 仍會靜默失效。

**為何不能只靠 nvim 0.12 原生**：原生只覆蓋**內建 parser**（`lua`、`vim`…）。實測 `.js` → `attached=false`（parser 存在，但沒人呼叫 `vim.treesitter.start`）。

**修法**（現值見 `nvim.d/my/treesitter.lua`）：

```lua
vim.opt.rtp:append(plugin_dir .. "/runtime")        -- ① query 才找得到
require("nvim-treesitter").setup {}                 -- ② 不是 .configs
vim.api.nvim_create_autocmd("FileType", {           -- ③ 高亮 ＋ indent 自己接
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
    if vim.treesitter.language.add(lang) == nil then return end
    pcall(vim.treesitter.start, ev.buf)
    vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
```

**兩個量測陷阱**（我自己踩過）：

- `require("nvim-treesitter").indentexpr()` **直接呼叫一定回 0** —— 它讀 `v:lnum`，而 `v:lnum` 只在 Vim 求值 indentexpr 時才有值。要驗證必須 `normal! ==` 後看行首縮排。
- 驗高亮看 `require("vim.treesitter.highlighter").active[buf]`，不要看畫面顏色。

**javascript 例外**：不套 treesitter indent（原設定即如此：`indents.scm` 對 embedded SQL 失效），保留 Vim 的 `GetJavascriptIndent()`。

### 2.4 packer 的兩個非互動陷阱

**① `:PackerClean`／`:PackerSync` 的移除步驟會走 `vim.fn.confirm`** —— 非互動（headless、腳本）下拿不到回答就**直接跳過**：指令回報成功、輸出乾淨，但 plugin 目錄還在，`packer_compiled.lua` 也還引用它。

```bash
ls ~/.local/share/nvim/site/pack/packer/start/<plugin>          # 目錄還在？
grep -c '<plugin>' ~/.config/nvim/plugin/packer_compiled.lua    # 還被引用？
```

修法（依序）：

```bash
rm -rf ~/.local/share/nvim/site/pack/packer/start/<plugin>
nvim --headless -c 'PackerCompile' -c 'sleep 3' -c 'qa!'
grep -c '<plugin>' ~/.config/nvim/plugin/packer_compiled.lua    # 應為 0
```

**② `:PackerCompile` 是非同步寫檔** —— `nvim --headless +PackerCompile +qa` 會在寫入前就退出，`packer_compiled.lua` 的 mtime 不變，看起來像「沒生效」。一律用上面的 `-c 'PackerCompile' -c 'sleep 3'` 形式，並以 **mtime ＋ `grep -c`** 驗證，不要看指令有沒有報錯。

> `packer_compiled.lua` 住 `~/.config/nvim/plugin/`（**不在本 repo**，`~/.config/nvim` 只有 `init.lua`／`lua` 等是指向 repo 的 symlink）。

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
| **移除** binding | ✅ `source-file` **不會**移除它 → 另跑 `tmux unbind-key -n <key>` |
| `bin/` 新增腳本 | ❌（PATH 已含）|
| 重新命名腳本（binding 引用舊名） | ✅ |
| `.zshrc`／`.bashrc` 的 PATH | ✅ 重啟 tmux server |

❗ **`source-file` 只加不減**（3.8 實測）：把 `bind-key -n C-M-v …` 從 `tmux.conf` 刪掉再 `source-file`，回傳 0、零錯誤，但 `list-keys` 仍看得到舊 binding —— 因為 server 的 key table 是累加的，config 只是重播一次。要真的拿掉必須顯式 `tmux unbind-key -n C-M-v`（下次 server 重啟才會自然消失）。

**兩個硬要求**：

1. **binding 的路徑在執行期必須是絕對路徑**。`run-shell` 用的是 **tmux server 啟動時的 PATH**，未必等於你 shell 的，所以不能靠 PATH 找腳本：
   ```tmux
   # 脆弱：bind-key -n C-o run-shell "toggle-opencode"
   bind-key -n C-o run-shell "#{@nvc_bin}/toggle-opencode '#{window_id}'"
   ```
   `@nvc_bin` 由 `tmux.conf` 開頭一段 `run-shell` 從 `~/.tmux.conf` 的 symlink 反推 repo 路徑，找不到就以 `bin/toggle-opencode` 可執行為標記，依序試 `$HOME/drake/nvim-config`、`$HOME/drakecheung/nvim-config`、`$HOME/nvim-config` 三個既有佈局 —— 換機器不必改檔。實測：拋棄式 server 載入後 `show-options -gv @nvc_bin` 得到該 repo 的 `bin`。
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

**`source-file` 不展開路徑變數（3.8 實測）**：`source-file -q ~/x.conf` 與 `source-file -q '$HOME/x.conf'` 都回 **0、零錯誤，但什麼都沒載入**（另一支 server 查 `show-options -gv <opt>` 查不到）。只有「shell 已展開的絕對路徑」有效 → 主機專屬 overlay 的載入行必須包 `run-shell` 讓 shell 先展開：

```tmux
run-shell 'tmux source-file -q "$HOME/.tmux.local.conf"'
```

配套兩個已量測的性質：① `-q` **只吞「檔案不存在」**，overlay 內壞行仍 `rc=1` 且印 `invalid option`（不會靜默）；② `run-shell` 在 config 解析**之後**才執行 → overlay 能覆寫前面的 `set`，但**不能移除**已綁的鍵（`source-file` 只加不減）。

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
| opencode session tab 切換 | `alt+↑`／`alt+↓`（內建）＋ `alt+←`／`alt+→`（追加） | opencode（`cli.json` 的 `session.tab.previous`／`next`；終端與 tmux 都直通，不需任何改寫） |
| opencode agent 循環 | `tab`／`shift+tab` | opencode（`cli.json` 的 `agent.cycle`；還原 V1 手感） |
| 開新 session | `ctrl+l` | opencode（`cli.json` 的 `session.new`） |
| 離開 opencode | `ctrl+q` | opencode（`cli.json` 的 `app.exit`；原含 `ctrl+c`／`ctrl+w`／`<leader>q`） |
| opencode 重置（開新 session ＋ 重載） | `ctrl+shift+l` | 見 §4.1 |
| opencode 重置（送不出 shift 的終端） | `ctrl+alt+l` | tmux（`tmux.conf` 的 `M-C-l`：焦點是 opencode 時灌同一串 CSI-u，否則送 `ESC` ＋ `0x0c`）。沒有 kitty 協議的終端（Crostini／vshd）裡 `ctrl+shift+l` 與 `ctrl+l` 同為 `0x0c`，故留這顆可辨識的替代入口；binding 以 `list-keys` 驗證已註冊，端到端按鍵未實測 |
| opencode 服務重啟 | `ctrl+shift+\``（主力，需 Ghostty）／`ctrl+\`（備案，跨終端） | 前者：Ghostty 的 `text:\x1c` 改送 `0x1c` 位元組（Crostini 等無 Ghostty 的機器不可用）；後者：`0x1c` legacy → tmux 直通 → opencode（2026-10-27 本機與 Crostini 皆實測有效）。兩者都收在 `cli.json` 的 `service.restart`；`ctrl+space`／`ctrl+\`` 不可用 |

**三個關鍵取捨（否決的替代方案）**：

1. **為何把 `ctrl+tab` 交還 Ghostty、opencode 改用 `alt+方向鍵`**（2026-10-27，取代 2026-10-12 的交換）：
   舊案把 `ctrl+tab` 改寫成 `Alt+Down/Up` 送給 opencode，代價是**吃掉 Ghostty 自己的 `next_tab`**。
   現案反過來：終端不再改寫任何鍵，opencode 用它內建就有的 `alt+↑`／`alt+↓`，並在 `cli.json`
   追加 `alt+←`／`alt+→`。這四個鍵在 Ghostty 與 tmux **都沒有**預設綁定（已實測），
   所以「一個動作只由一層持有」仍然成立，而且少了一層轉譯。
   代價：`alt+←`／`alt+→` 原本是輸入框的「按詞移動」，改由 `ctrl+←`／`ctrl+→` 與 `alt+b`／`alt+f` 擔當。
2. **為何選方向鍵而非字母鍵**：`Ctrl+Shift+字母` 可能與 `Ctrl+字母` **同編碼**
   （例：`ctrl+shift+l` 長期無法確認可用），而 Ghostty 天生能區分「修飾鍵 ＋ 方向鍵」。
3. **為何 `service.restart` 由終端改送 `0x1c`**（2026-10-27 定案）：
   反引號的 ctrl 位元組是 `0x00`（與 `ctrl+space` 同值），tmux 的 VT10x pane 收不到 shift 資訊，
   所以 `ctrl+\`` 與 `ctrl+shift+\`` **都會**被命名為 `ctrl+space`；而 `ctrl+space` 在 Crostini
   又被 host 層的輸入法切換吃掉，且與 `ctrl+@`／`ctrl+2` 等所有 NUL 來源碰撞 ⇒ 此路不通。
   正解是：opencode 綁**實體 `ctrl+\`**（`0x1c`，legacy 直通），再讓終端把其他順手的 chord
   改送**同一個位元組** —— `ctrl+shift+backquote=text:\x1c`（Zig string literal）。
   這比「改寫成另一顆具名鍵」（曾試 `CSI 1;5H`＝Ctrl+Home）更穩：不必猜 app 端怎麼命名。
   位元組層細節與隔離測試法請參閱指標 → `mem:global/tmux/ctrl-tab-and-extended-keys`。

**為何 Ghostty 設定檔納入本 repo**（2026-10-12）：
①該檔 3.7 KB、當日被改動多次，卻**完全不在任何 git repo**（真檔），備份只在 `/tmp`；
②本 repo 已是「終端 ＋ 編輯器設定」的家（`tmux.conf`、`kitty.conf` 皆 symlink）；
③檔名不是慣例的 `config` —— `strace` 實測 Ghostty 開啟的**就是** `config.ghostty`，
  故 symlink 必須沿用該檔名。

**驗證**：`ghostty +list-keybinds`（確認覆寫生效、symlink 被跟隨）。

**overlay 載入線的兩個實測性質**（Ghostty 1.3.1，2026-10-27）：`config-file = ~/…` **會展開 `~`**；
但**指向不存在的檔案時靜默略過**（`rc=0`、零輸出）——所以「沒報錯」不代表 overlay 載入了，
判準只有 `ghostty +list-keybinds` 出現該 overlay 的鍵。

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

### 5.6 `nvim-uid`：ueberzug 已死 → chafa；puppeteer 25 → Node ≥ 22.12

**功用**：FIFO 收 `url <...>` → puppeteer 截圖到 `~/.nvim-uid/web.png` → 畫進當前 pane。FIFO 路徑 `/tmp/nvim-uid-<COMPOSE_PROJECT_NAME>.sock`。

**三個升級障礙**（都是「換環境才炸」型）：

1. **`ueberzug` 在 Python 3.12 已死**（RuntimeError，專案停止維護）→ 改 `chafa`：ANSI 區塊、不需 tmux passthrough、且 `tmux capture-pane` 可客觀驗證輸出。
2. **puppeteer 25 要求 Node ≥ 22.12** → 用 nvm 安裝一條滿足門檻的線（本機現值 `node -v` = v24.22.1，LTS `Krypton`；另有 20.20.2／24.16.0）。nvm 的全局套件是 per-version：切換前先 `npm ls -g --depth=0` 確認沒有要重裝的。
3. **Ubuntu 24.04 AppArmor 限制 unprivileged userns** → Chrome 起不來（`zygote_host_impl_linux.cc: No usable sandbox`）→ launch 加 `args: ['--no-sandbox']`。**只指向自家 dev server**：無沙箱渲染任意網頁等於開後門。

**兩個實作陷阱**：

- **`tmux display -p` 會指到錯的 client**（detached／多 client 時回錯值或直接拋錯）→ 一律 `tmux display-message -p -t "$TMUX_PANE"`。
- **FIFO 訊息不能用 `split(/\s+/)` 取 URL** —— URL 可含空白（`data:` URL 就是），會被截斷成半條字串，症狀是「畫面全白」。用第一個空白切分即可。

**用法**：`nvim-uid <url>` 單次渲染並結束；`nvim-uid` 常駐聽 FIFO。

**同一個渲染器也服務 telescope 的圖片預覽**：`_G.media_files()`（`nvim.d/my/telescope.lua`）用 `chafa` 當 termopen previewer，因此 `telescope-media-files.nvim`（內含 ueberzug wrapper）已不需要。

### 5.7 pane 的環境變數：非互動 shell 與 direnv 的兩個坑

**症狀**：pane 內工具少了 `COMPOSE_PROJECT_NAME`／`COMPOSE_FILE`，`docker compose`／`reboot-dev` 打到別的 stack（或看起來正常、其實打到目錄名 default）。

**根因 1 — toggle 開的 pane 是非互動 shell**：tmux 執行 pane 命令走 `zsh -c`（實測 `$-` = `569X`，沒有 `i`），不讀 `.zshrc` ⇒ 沒有 nvm 的 PATH，也**沒有 direnv hook**。所以 env 必須由該 pane 的啟動命令自己載，不能指望「shell 已經載好」。

**根因 2 — `eval "$(direnv export bash)"` 空輸出仍回 0**：direnv 未 allow、或目錄沒有 `.envrc` 時輸出為空且 **exit 0** ⇒ `eval ""` 回 0 ⇒ 後面的 `|| . ./.envrc` **永遠不會跑**，症狀是「靜默無 env」。必須先驗輸出非空：

```bash
[ -f .envrc ] && { _e=$(direnv export bash 2>/dev/null); [ -n "$_e" ] && eval "$_e" || . ./.envrc 2>/dev/null; }
```

**根因 3 — 裸 `source` 只加不減**：`cd` 離開後上一個 repo 的 `COMPOSE_*` 仍在，這正是打錯 stack 的成因。interactive shell 交給 direnv hook（`~/.zshrc`），它會 `unset` 不屬於當前目錄的變數；非互動 pane 沒有這個好處，只能選「明確覆寫」的 `.envrc`。

**現值**：`bin/open-project` 只開一個停在 repo 路徑的 shell（不啟編輯器、不載 env）；env 由該 shell 的 direnv hook 負責。`bin/toggle-opencode` 在 spawn 時自己載（direnv 優先、裸 source 退回）；`bin/toggle-nvim` 用裸 `source`（本 repo 的 `.envrc` 實測為純 shell，可通）。

**分割比例取決於「誰先佔滿視窗」**：nvim 全螢幕後切 60% → 40:60；opencode 全螢幕後切 **40%** → 40:60。要兩個順序一致，左側工具就必須是 40%（35% 會使後按的那序變成 35:65）。

**驗證**：拋棄式 server ＋ `TMUX=<socket>,0,0`，讓腳本打到探針而非現行 server：

```bash
tmux -L probe -f /dev/null new-session -d -x 200 -y 50
SOCK=$(tmux -L probe display -p '#{socket_path}')
TMUX="$SOCK,0,0" bin/open-project nvim-config      # 開窗、停在 repo 路徑
TMUX="$SOCK,0,0" bin/toggle-nvim "@1"              # 單一 main pane → 全螢幕接管
TMUX="$SOCK,0,0" bash -c 'source bin/tmux-panes.sh; pane_lib::toggle_pane opencode "sleep 60" 60% /tmp @1'
tmux -L probe list-panes -t @1 -F '#{pane_left}|#{pane_width}'   # 期望 0|79 / 80|120
```

### 5.8 主機相依的兩件事：外部工具、家目錄路徑（都會靜默失敗）

**① 呼叫外部工具前先 `executable()` 檢查**：`io.popen("xclip …", "w")` 在工具不存在時**不會回錯**，write 進去的東西直接消失 —— 症狀是「按了貼上沒反應」。

```lua
-- 實測（本機）：executable("xclip") == 0、xsel 存在 → 舊寫法靜默失效，改用偵測後挑一個
for _, cmd in ipairs({ "wl-copy", "xclip -selection clipboard", "xsel --clipboard --input", "pbcopy" }) do
  if vim.fn.executable(cmd:match("^(%S+)")) == 1 then … return true end
end
```

全都沒有時退回 `vim.fn.setreg("+", text)` 並 `vim.notify` 提示一次（用 flag 去重，避免每次操作都吵）。現值在 `nvim.d/my/send.lua` 的 `M.copy_to_clipboard`。

**② swap／undo 目錄不要寫死 `$HOME`**：`o.directory`／`o.undodir` 寫成 `/home/<user>/…` 時，在 `$HOME` 不同的機器上**兩者都靜默失效**（swap 落空、persistent undo 完全沒作用，且沒有錯誤訊息）。改用 nvim 自己的 state 目錄，並先建立：

```lua
local state_tmp = vim.fn.stdpath("state") .. "/tmp"
vim.fn.mkdir(state_tmp, "p")
o.directory = state_tmp
o.undodir = state_tmp
```

**通用判準**：設定檔裡只要出現「絕對家目錄路徑」就是換機定時炸彈 —— 用 `$HOME`／`stdpath`／symlink 反推（後者見 §3.3 的 `@nvc_bin`）。`bin/config-audit` 的第 1 項會掃出來（**連本機使用者的路徑也算違規**，因為換 device 一樣壞）。

