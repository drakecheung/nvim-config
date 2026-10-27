# SKELETON — 方法論與檔案地圖

本檔是專案的方法論契約：**原則、檔案地圖、同步儀式**。
新設定案以本檔為藍圖；多案之間只人工 sync（copy＋diff），不設 template repo、不設骨架目錄。
本檔衍生自 `mygenie` 的藍本（**pull-only，不回寫**）；**「同版」只約束骨架與節名**（見 §3），本地增補一律標記 `❗本 repo 增補`，**條數允許不同**。本專案是參考實作，檔案可被複製到新案當起點。

## 1. 方法論

### 原則

- **單一方法，不放 alternatives**：每件事只給唯一做法，避免 agent 在選項間猶豫。
- **文件精確、無歧義**：不用「可選／備援／或」措辭。
- **所有指令非 blocking**：agent 會執行的指令一律不長駐前台。
- **外部相依最少化（AI 掌握度）**：預設手寫——只組合既有 primitive；只有「無法自行實作的 primitive」才用 library。判準＝AI 能否在 repo 內完全推導其行為，而非「library 聽起來比較可靠」。詳見下節。
- **文件與實作同步**：任何改動完成後，必須覆檢並同步 `AGENTS.md`、`SKELETON.md`、`LESSONS.md`。原因：agent reset 後 md 是唯一可靠紀錄。
- **只記「會重複犯」的坑，不記一次性備忘**：能寫進 md 的是「未來 agent 可能重蹈的坑／須遵守的紀律／source-of-truth 規格」；一次性備忘、已落地不會再發生的問題、純敘述性歷程，寫進去只會稀釋專注。判斷標準：這條能在「新 session、無本對話上下文」時防止一個實際錯誤嗎？不能就刪。與「文件與實作同步」互相制衡：後者防漏、本條防濫。
- **量測優先，不憑印象（❗本 repo 增補；家族藍本未有，可日後 pull）**：凡對「行為」下斷言都要有量測 —— 設定值用 `tmux show-options -gv`、端到端用拋棄式 server、渲染／寬度用 pixel 或游標量測。「我記得」「看起來」不是證據；量到才寫進 md。
- **文件只描述當下，history 交給 git（❗本 repo 增補）**：樹內不留決策史／進度帳 —— 文件永遠反映現在；要追溯「為何變成這樣」用 `git log`／`git blame`。樹內放 history 只會與現實脫節（第二份會漂移的真相）。
- **commit 是 reset-safe checkpoint**：每段工作完成、結束 session 前，AI 必須**主動提議 git commit**（含建議 message），且提議前先完成 md 去矛盾／去漂移 review。未 commit 不結束工作。
- **跨案遷移的是紀律與契約，不是檔案**：可共享的是 pattern；檔案遷移度 = stack 相似度。

### Library 定手寫（AI 掌握度）

> **預設手寫——只組合既有 primitive；只有「無法自行實作的 primitive」才用 library。** 判準＝AI 能否在 repo 內完全推導其行為。

- **用 library**：無法自行實作的 primitive（tmux／nvim 本體、fzf、ghostty、字型鏈）；行為可由公開文件推導。
- **手寫**：`bin/**` 的膠水腳本、設定檔的組合與覆寫；要確定性、狀態可觀察、可測失敗。
- **理由**：in-repo 可推導、無 hidden semantics／version drift。**可靠性來自明文 invariant ＋失敗測試，而非第三方庫。**

### 文件分工（本 repo）

| 檔案 | 角色 |
|---|---|
| `SKELETON.md` | 本檔：方法論契約（跨案**骨架**同版；本地增補標記 `❗本 repo 增補`） |
| `AGENTS.md` | agent 工作規則（引用本檔） |
| `LESSONS.md` | 本 repo 的專案級坑與其行動（「遇到 X 就做 Y」） |
| `opencode-config` 的 `memories/global/` | 跨專案通則 |

**引用關係（誰指向誰）**：

- `AGENTS.md` → 引用 `SKELETON.md`（通則）＋ 指向 `LESSONS.md`（動手前先讀對應節）＋ 指向 `memories/global/`（跨專案通則）。
- `LESSONS.md` → **只由 `AGENTS.md` 引用**；它自己不引用 `SKELETON.md`，避免雙向糾纏。
- `SKELETON.md` → 不引用 `LESSONS.md` 內文（坑是 delta，不屬 invariant）。

### md 檢查步驟（commit 前必跑，按順序）

> 由「文件與實作同步」推導出的可執行流程。每次改動完成、提議 commit 前照做，不要靠「記得」。目的：去矛盾、去漂移、無斷裂（交叉引用落空）。

1. **列改動盤點**：`git status` ＋ `git diff --stat`。
2. **改動→文件 對齊**：每段改動對應哪個 md 節？（設定行為／坑 → `LESSONS.md`；工作規則 → `AGENTS.md`；方法論 → `SKELETON.md`）
3. **stale 引用掃描**：`grep` 全倉 md，搵已刪／已改／已搬的舊詞（舊腳本名、舊選項名、舊鍵位）。
4. **設定／實作一致**：md 寫的設定值要 `grep` 回實際檔案確認（例如 `tmux.conf` 的那一行），不要照抄舊值。
5. **編號／結構完整**：節號無跳號或重複（`grep '^#'` 看圖）。
6. **交叉引用無落空**：md 互相提到的節名、檔名、腳本名——逐條確認存在。
7. **矛盾／歧義掃描**：搜「可選／備援／或／暫用／替代」，修成單一做法。
8. **驗證命令照跑**：`tmux source-file ~/.tmux.conf` 零錯誤、`bash -n <script>`；行為類改動用拋棄式 server 端到端。
9. **用 grep／工具核實，不靠眼睛**。

## 2. 檔案地圖

類型定義：

- **Invariant** — 跨案不可變的紀律／契約文件，多案同步時人工對齊（見 §3）。
- **Reference** — 參考實作。stack 相近的案子可抄、可改、可不抄；不進 sync 驗證。
- **Delta** — 純專案內容，只存在各案，不共享。

### Invariant

> **只有跨案共用的紀律與契約放這裡**；sync 時**逐節比對**，只 pull 新版內容過來 —— **禁止整檔覆蓋**（見 §3）。
> ❗ **repo 專屬內容禁止放進 Invariant**：放進來就等於把「會變的東西」裝進「承諾不變的容器」，sync 時必然相撞（§3 的整檔覆蓋禁令即由此而來）。

| 檔案 | 用途 |
|---|---|
| `SKELETON.md` | 本檔：方法論契約 |
| `AGENTS.md` | agent 工作規則（引用本檔） |

### Reference（本專案 = nvim ＋ tmux ＋ ghostty；Linux／AppImage）

| 路徑 | 用途 |
|---|---|
| `install.sh` | 安裝入口（symlink 設定檔；`-d` 守衛，未安裝的目標會跳過） |
| `tmux.conf` | tmux 設定（鍵位、pane toggle、theme、popup 外觀） |
| `ghostty.conf` | ghostty 設定（字型鏈、keybind，如 `ctrl+shift+l=csi:108;6u`） |
| `kitty.conf` | kitty 設定（保留；kitty 未安裝） |
| `vimrc.lua` | nvim 入口（含 deprecated API alias） |
| `nvim.d/**` | nvim 設定（keymap、autocmd、plugin、LSP、telescope…） |
| `bin/**` | 膠水腳本（pane toggle、project picker、fzf popup 包裝…） |
| `bin/config-audit` | 唯讀稽核共享／主機專屬的界線（外來絕對路徑、overlay 載入順序與可載入性、耦合值） |
| `README.ln` | 使用者向說明（鍵位表、環境安裝步驟） |

> **主機專屬覆寫不在 repo 內**：`~/.tmux.local.conf`、`~/.config/nvim/local.lua`（ghostty 的載入線待有該 binary 的機器補）。repo 的設定檔在**檔尾**條件載入它們，缺席即用 repo 的預設 —— 所以新機不帶 overlay 也能運作，調偏好也不會弄髒 git。

### Delta（不共享）

> sync **不會**碰這裡。

| 路徑 | 用途 |
|---|---|
| **`LESSONS.md`** | **本 repo 的專案級坑與行動**（repo 專屬；由 `AGENTS.md` 引用） |
| `nvim.d/my/**`、`snippets/`、`syntax/`、`ftplugin/`、`ftdetect/` | 個人 nvim 內容 |
| `.serena/**`、`node_modules/` | 工具產物（由 `~/.gitignore_global` 與 repo `.gitignore` 擋） |

### 已知坑（三層歸屬）

| 層級 | 住處 | sync 會覆蓋嗎 |
|---|---|---|
| **框架／跨案通用**（方法論、跨 stack 的紀律） | 本檔 §1／§2 | ✅ 會（本就共用） |
| **工具級跨專案**（tmux 3.8、fzf、nvim 的行為變更） | `opencode-config` 的 `memories/global/` | ❌ 各自同步 |
| **本 repo 專屬**（本 repo 的設定值、腳本、pane 模型） | **`LESSONS.md`** | ❌ **不碰** |

判準（**❗本 repo 增補**；家族藍本未有）：四問**全過**才算「通用」，可進上兩層；任一不過 → 留 `LESSONS.md`：

| # | 問法 | 不過就代表 |
|---|---|---|
| 1 | **適用面**：另一個不相干的案會不會遇到？ | 只有本 repo 會 → 屬本 repo |
| 2 | **自足**：把本 repo 的名字／路徑全部刪掉，這段話還成立嗎？ | 抽掉就崩 → 屬本 repo |
| 3 | **可行動**：別處的人不必讀本 repo，就能照著做嗎？ | 非讀本 repo 不可 → 屬本 repo |
| 4 | **有實質**：抽掉本 repo 專屬的部分（表格、現值、腳本名）後，**還剩可操作內容**嗎？ | 只剩格言 → 不值得寫成條目 |

> 第 1 問是**必要但不充分** —— 單靠它會把「本 repo 的專屬實例」誤升級成通用條目。

## 3. 同步儀式

- **開新案**：複製本專案（或任一同門專案）當起點 → 改 Delta。
- **同步（人工，兩三步）**：
  1. 比對各案 `SKELETON.md` 的**骨架與節名**；差異逐項判斷：藍本新版 → pull 過來；本地增補 → 標記 `❗本 repo 增補`。
     ❗ 本 repo **只 pull、不覆蓋他案**（藍本及其成員非本 repo 所有）。
  2. 依新版 `SKELETON.md` 檢查**本 repo** 的 Invariant 文件（`AGENTS.md` 結構）是否一致。
  3. Reference 檔**不需要**對齊——各案可自由分叉，只有 Invariant 的**骨架與節名**必須同版（條數可不同）。
- ❗ **禁止整檔覆蓋**：sync 只做**逐節比對**，且只同步「**脫離 stack 與案型仍成立**」的節（§1 原則、§3 儀式、§2 的類型定義）；**per-case 節**（§2 的 Reference 清單、任何 stack 綁定的已知坑清單）**不得同步**。理由：`SKELETON.md` 混著 invariant 節與 per-case 節，整檔覆蓋會**靜默覆滅**本 repo 的 stack 知識（覆蓋後檔案完全正常，只是內容換成別人的）。
- 目標是「**Invariant 的骨架**同版、Delta 各異」；若某檔案長期被改，就把它從 Invariant 降為 Reference 或 Delta。

**「同版」判準**：**節名一致 ＋ 語意可對照**即可，**規則數目允許不同**（**條數因 stack 與案型而異，故不比較條數**；本地增補以 `❗本 repo 增補` 標記），**用語依各 repo 的語文政策**（本 repo 用繁體中文書面語；姊妹案可能用其他語體）—— 不要求逐字相同，但節名與語意必須對得上，否則同步時無法 diff。
