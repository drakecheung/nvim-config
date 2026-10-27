# nvim-config — Agent Guidelines

本 repo 是個人終端開發環境設定（nvim ＋ tmux ＋ ghostty），與 `opencode-config` 平級自治。

## 讀取順序（每個 session 的起點）

1. **本檔** —— agent 工作規則。
2. **`SKELETON.md`** —— 方法論契約（通則：原則、檔案地圖、md 檢查步驟、同步儀式）。本檔引用它。
3. **`LESSONS.md`** —— 本 repo 的專案級教訓（坑與其行動）。
   動 `ghostty.conf`／`tmux.conf`／`vimrc.lua`／`nvim.d/**`／`bin/**` 之前，先讀對應節。
4. **`opencode-config` 的 `memories/global/`** —— 跨專案通則（tmux 擴展鍵、design language、報告格式等）。本 repo 不重述。

## 分工（一條規則只有一個家）

| 住處 | 放什麼 |
|---|---|
| `SKELETON.md` | 方法論契約（原則／檔案地圖／同步儀式）；跨案**骨架**同版，本地增補以 `❗本 repo 增補` 標記 |
| `AGENTS.md`（本檔）| agent 工作規則、協定、驗證方式（**引用 `SKELETON.md`**）|
| `LESSONS.md` | 專案級坑與其行動（「遇到 X 就做 Y」）；**只由本檔引用** |
| `opencode-config` 的 `memories/global/` | 跨專案通則 |

**不要把坑寫進本檔，也不要把規則寫進 `LESSONS.md`** —— 兩處各寫一份必然漂移。

## 規則

### 驗證（動手前／收工前）

- **改設定檔後必驗**：`tmux source-file ~/.tmux.conf` 要**零錯誤**（tmux 3.8 對未知旗標／選項會直接報錯）。
- **改腳本後必驗**：`bash -n <script>`。
- **行為斷言要有量測**：設定值查 `tmux show-options -gv <opt>`；端到端／渲染行為用**拋棄式 server**（`tmux -L <name> -f /dev/null new-session -d`）或 **pixel／游標量測**。「看起來」不算證據。
- **交付前**：`git status` 確認沒夾帶無關檔案；`git diff --stat` 逐檔看。

### commit 紀律

- 主動提議 commit（含建議 message）；**提議前先跑 `SKELETON.md` 的 md 檢查步驟**。
- message **自足**：講清 what ＋ why，不引用內部代號（代號對讀者是黑盒）。
- **不用 `git add -A`／`git commit -a`**：明確指定路徑，並核對 `git diff --cached --name-only`（提交前）與 `git show --name-only HEAD`（提交後）。
- **push 前取得用戶確認**。

### 主機專屬設定的邊界

- **repo 只放共享結構與可直接用的預設**：色盤、字型、字級、主機路徑等「依主機而異」的值走 overlay，不改 tracked 檔。
- **overlay 在 repo 之外**（所以調偏好不會弄髒 git）：tmux `~/.tmux.local.conf`、nvim `~/.config/nvim/local.lua`；ghostty 的載入線尚未建立（本機無 ghostty 可實測 `config-file` 是否展開 `~`），在有該 binary 的機器上才補。
- **載入線必須在檔尾**：tmux 是 `run-shell` 內 `source-file -q "$HOME/…"`（`source-file` 本身不展開 `~`／`$HOME`，見 `LESSONS.md` §3.3），nvim 是 `vimrc.lua` 末尾的 `dofile`。
- **收工前跑 `bin/config-audit`**（唯讀）：外來絕對路徑、載入順序、overlay 能否載入、耦合值是否一致。
- **配色是一組**：ghostty palette／tmux theme 色階／nvim colorscheme／fzf 色必須一起改；只改一處會得到「半套主題」且**不會報錯**。

### 環境假設

- tmux **3.8**（source build，`/usr/local/bin/tmux`）；nvim **v0.12.6**（appimage）。
- node **26.1.0**（nvm default；`process.release.lts` 未定義 → 非 LTS 線；`puppeteer` 25 要求 ≥ 22.12）。
- shell `/usr/bin/zsh`。
- **本機是 Crostini 容器**（ChromeOS 的 LXC；hostname `penguin`、Debian 12 bookworm、`systemd-detect-virt` = `lxc`）：`~/.tmux.conf` 與 `~/.config/nvim/*` 已 symlink 進本 repo；**`ghostty` 未安裝、`~/.config/ghostty/` 不存在**，故 `ghostty.conf` 在本機不生效。
- 任何探針一律用**拋棄式 server**（`tmux -L <name>`），不要污染現行 server。
- popup 外觀的可覆寫通道：`FZF_PTR`（pointer，預設 `🢖`）、`FZF_SELBG`（highlight 底，預設 `#1f1a1a`）。

### 禁忌

- **不把坑寫進本檔**（坑屬 `LESSONS.md`）、**不把工作規則寫進 `LESSONS.md`**、**不把方法論寫進 `AGENTS.md`**（屬 `SKELETON.md`）。
- **不用推定代替量測**：沒量到的行為不寫進 md、不當結論交付。
