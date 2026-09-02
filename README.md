# agent-md-starter

給本機 coding agent 的通用指令檔。一份 `AGENTS.md`，三個 CLI 都能吃：

| CLI | 專案內讀 | 全域讀 |
|-----|---------|--------|
| Claude Code | `CLAUDE.md`（一行 `@./AGENTS.md`）| `~/.claude/CLAUDE.md` |
| Gemini CLI | `GEMINI.md`（一行 `@./AGENTS.md`）| `~/.gemini/GEMINI.md` |
| GitHub Copilot CLI | `AGENTS.md` 直接讀 | `~/.copilot/copilot-instructions.md` |

## 用法

**放進單一專案**：把 `AGENTS.md`、`CLAUDE.md`、`GEMINI.md` 複製到專案根目錄。

**裝成全域預設**（每個專案都生效）：

```powershell
git clone https://github.com/bingo-taiwan/agent-md-starter.git
cd agent-md-starter
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

會把 `AGENTS.md` 複製到上表「全域讀」三個位置，原檔先備份成 `.bak`。

## 改自己的

只改 `AGENTS.md`，尤其最後的「個人化」段。`CLAUDE.md` / `GEMINI.md` 不用動，它們只是引入。
改完重新跑 `install.ps1`（或 Gemini CLI 內 `/memory reload`）。

## 為什麼這樣設計

- 單一真來源：規則只在 `AGENTS.md`，不會三份漂移。
- 短才有效：agent 對長篇規則的遵守率會下降，長內容放 `docs/` 按需讀。
- 金鑰不進 git：`keys/` 已在 `.gitignore`。

依據：
- Copilot CLI 自訂指令：https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions
- Gemini CLI GEMINI.md：https://geminicli.com/docs/cli/gemini-md/
