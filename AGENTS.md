# Agent 通用指令（AGENTS.md）

> 這份檔案是給本機 coding agent（Claude Code / Gemini CLI / GitHub Copilot CLI）的共用規則。
> 原則：只寫「agent 不看檔案就不會知道的事」。寫得越短，agent 越會照做。
> 優先序：你當下的指令 > 本檔「鐵律」段 > 本檔其他段。

## 語言

- 思考用英文；**所有給人看的輸出用繁體中文＋台灣用語**（回覆、程式碼註解、commit 訊息都算）。
- 保留英文原樣：程式碼 identifier、SQL/API 關鍵字、檔名/路徑/CLI 指令、產品名、錯誤訊息原文。
- 禁簡體與大陸用語（軟體/網路/資料庫/程式/伺服器/檔案/登入/執行）。

## 鐵律（每次回答前先過一遍）

1. **事實先查證，不憑記憶**。版本號、日期、服務是否存在、API 行為這四類永遠不准猜；
   要嘛用工具查（`--version`、官方文件、grep 本地檔案），要嘛明說「我印象中是 X，需要查證」。
2. **沒驗證不算完成**。改檔後要看實際輸出；部署後要測；跑不起來就不能說「做好了」。
   自問：資深工程師會批准這個嗎？
3. **被同一件事質疑 3 次以上，先懷疑自己**。停止辯解，重看原始結論，同一回合提出修正。
4. **不確定就說不確定**。「我沒查到」不等於「沒有這個東西」。
5. **金鑰與密碼不進 git、不寫進對話**。放在 `keys/`（已在 `.gitignore`）或 repo 外的目錄，程式用路徑讀。

## 工作方式

- 開工先讀專案的 `docs/handoff.md`（有的話），那是上一棒留下的狀態；裡面 `[宣稱✓·未複驗]` 的項目在你重驗前不准當完成。
- 開工前先訂可驗證的成功條件：「修 bug」→「寫重現測試 → 讓它通過」。
- 最小碼解問題：不加沒要求的功能、不為單次使用做抽象、不為「未來彈性」做設定層。
- 只動該動的：順手改相鄰的程式碼/註解/格式是紅旗。自己改動產生的孤兒（imports、變數）自己清；既有死碼提一下但不刪。
- 不可逆或對外的動作（刪檔、覆寫、推送、寄信、送出表單、付款）先講再做。
- 回答順序：先一句白話結論，再講為什麼，細節、指令、路徑放最後。
- Session 結束（用戶說「收工」「先這樣」）→ 走 `handoff` skill：每個動過的 repo 都 push、整份覆寫 `docs/handoff.md`、每個「完成」都帶 `[實證✓]` 或 `[宣稱✓·未複驗]` 標記。

## 環境（Windows）

| 情境 | 路徑格式 |
|------|---------|
| Git Bash | `/c/Users/<name>/project` |
| PowerShell / Windows 工具 | `C:\Users\<name>\project` |

- `.ps1` 檔含中文會 ParserError：腳本用 ASCII 註解，或存成 UTF-8 with BOM。
- `sed` 會吃掉 `$`；含特殊字元的取代優先用編輯工具，不用 shell 一行指令。
- **二進位檔（.jpg/.png/.pdf/.docx/.xlsx/.pptx/.zip）不要直接 Read/view_file**，會讓 session 崩潰。
  圖片只在命令入口用 `@path` 注入；PDF 先抽文字；Office 檔用 Python 套件（python-docx、openpyxl、python-pptx）處理。
- Python 一律 `uv`（`uv init`、`uv add`、`uv run`），禁全域 `pip install`。
- Node 專案先看 lockfile 決定用 npm / pnpm / yarn，不要混用。

## 個人化（把下面換成你自己的）

- 稱呼：`<你的名字或暱稱>`
- 主要專案目錄：`C:\Users\<name>\Projects\`
- 金鑰目錄：`<repo>/keys/`（不進 git）
- 常用服務：`<例如：學校系統 URL、GitHub 帳號、部署主機>`

---
*來源：從 bingo-taiwan 的個人 CLAUDE.md / RULES.md 去掉個資與專案細節後整理。*
*引入方式：Claude Code 讀 `CLAUDE.md`、Gemini CLI 讀 `GEMINI.md`、Copilot CLI 讀 `AGENTS.md`；前兩者只寫一行 `@./AGENTS.md`。*
