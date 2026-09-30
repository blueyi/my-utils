# Powerlevel10k — IDE terminal ghost prompts

## Symptom

In Cursor / VS Code integrated terminals, accepting a line or waiting for async
git status can leave stacked copies of the prompt, e.g.:

```text
╭─ ~/.hermes  macos-xy !11 ?11                     ✔  17:53
╭─ ~/.hermes  macos-xy !11 ?11                  ✔  17:53:05
╭─ ~/.hermes  macos-xy !11 ?11                       ✔  17:53:05
╰─
```

xterm.js often does not fully clear multiline / transient redraws.

## Fix (my-utils)

- `config/p10k-ide-overrides.zsh` — IDE-only overrides after `~/.p10k.zsh`
- Wired from `config/zsh_entry.zsh`

When detected as an IDE terminal:

| Setting | Value |
|---|---|
| `POWERLEVEL9K_TRANSIENT_PROMPT` | `off` |
| `POWERLEVEL9K_INSTANT_PROMPT` | `quiet` |
| Left prompt | single line: `dir` + `vcs` |
| Right prompt | slim: status / duration / jobs / venv / conda / context (no `time`) |

External terminals (iTerm, Terminal.app, …) keep the full `config/p10k.zsh`
rainbow + transient setup.

## Detection

Overrides apply when any of:

- `TERM_PROGRAM` is `vscode` or `cursor`
- `VSCODE_INJECTION` / `VSCODE_PID` set
- `CURSOR_TRACE_ID` set or `CURSOR_AGENT=1`

## Controls

```bash
# Disable IDE overrides (even inside Cursor)
export MYU_P10K_IDE_OVERRIDES=0

# Force overrides outside IDE (for testing)
export MYU_P10K_IDE_OVERRIDES=1
```

Put the export in `~/.my-utils.env` if you want it persistent.

## Verify

1. Open a **new** Cursor terminal tab.
2. `cd` into a git repo; wait a few seconds; press Enter a few times.
3. Scrollback should not stack duplicate `╭─` / prompt lines.
4. In iTerm (or another non-IDE terminal), prompt should still be the full
   two-line framed style with transient trim.
