---
name: audit-loghistory
description: Audit today's tool-invocation log written by the team-workflow plugin hooks. Reports tool usage, error rate and git commit message quality. Use whenever the user asks what the agent did today, wants a log audit or activity report, asks for tool usage stats, error counts or failed commands from the logs, or wants feedback on commit messages recorded in the log. Also trigger on "audit logs", "today's report", "what did the agent do", "tool stats", "check the commits in the logs", even when the user does not say "log" or "audit". Covers only the current day; a 7-day view is offered as a follow-up, never produced by default.
---

# Audit Log History

Turn today's hook log into a short status report: which tools ran, how often they failed, and whether the git commits in the log follow Conventional Commits. The reader should scan it in seconds.

## Where the data lives

The hook (`hooks/log-tool.sh`) writes to the plugin root. `${CLAUDE_PLUGIN_ROOT}` is only set for hooks, so do not rely on it here. Resolve the root from this file:

1. Go two directories up from this `SKILL.md` (`skills/audit-loghistory/` → plugin root).
2. Check that `hooks/log-tool.sh` exists there. If not, stop and tell the user the plugin root was not found. Do not search the filesystem.

Files in the root:
- Today's log: `log-tool-YYYY-MM-DD.log` (today's date). This is the only file the report reads.
- Weekly archives: `YYYY-WEEK##.tar.gz`. Never open, extract or decompress them unless the user explicitly asks.

## Log format

Each entry is: a line of 80 dashes, an ISO-8601 timestamp, the JSON payload the hook received, then an `env:` block. Never read or print the `env:` block.

Before counting, read one raw entry and take the field names from it. Do not assume them.

## Fallback

If the plugin root or today's log is missing, or the log is empty, reply with exactly this and nothing else:

**"No data available for analysis right now."**

Do not infer activity from other files in that case.

## Steps

1. **Resolve the root and open today's log.** Apply the fallback if needed.
2. **Confirm the payload fields.** From one entry, identify the fields for tool name, tool input (the command, for shell tools) and the result, including any exit code or error flag.
3. **Count the activity** across all of today's entries:
   - total invocations and counts per tool name;
   - for shell or build tools (for example `git`, `npm`, `g++`), counts per sub-command;
   - successful and failed calls. A call failed if its result has a non-zero exit code or an error flag. If the payload has no such signal, report the success rate as unavailable.
   - success rate = successful ÷ total, as a percentage.
4. **Review git commits.** Find every `git commit` and take its message. Valid Conventional Commits form: `type(scope): summary` or `type: summary`. Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
   - Valid message: say so, no suggestion.
   - Invalid message: give a corrected message and a one-line reason. Stay faithful to what the commit did, as far as the log shows.
5. **Render the report** in the format below.
6. **Offer the 7-day view.** Check the last 7 days for daily logs and archives, by name only. List only the range actually found. If none, skip the offer.

## Output format

### 📊 Log Audit Report (Today: YYYY-MM-DD)

**Summary Metrics:**
- **Total Tool Invocations:** `<number>`
- **Active Log File:** `log-tool-YYYY-MM-DD.log`
- **Success Rate:** `<percentage>%` (`<error_count>` issues detected)

#### 🌳 Usage Structure
```text
📁 log-tool-YYYY-MM-DD.log (Total: <X> calls)
├── 🛠️ <ToolName1> (<Count> calls — <Percent>%)
│   ├── <Sub-command1> ............. <Count>
│   └── <Sub-command2> ............. <Count>
└── 📖 <ToolName2> (<Count> calls — <Percent>%)
    └── <Sub-command1> ............. <Count>
```

#### 📋 Tool Usage Table
| Tool | Invocations | Share | Status / Notes |
| :--- | :---: | :---: | :--- |
| **<ToolName>** | <Count> | <Percent>% | <Status / warnings> |

#### 📝 Git Commit Review
*(Include only if a `git commit` was found.)*
- **Original Commit Message:** `<message>`
- **Suggested Improvement:** `<Conventional Commits message>`, or "not needed: already follows Conventional Commits"
- **Reasoning:** `<one line>`

---
> 💡 **Proactive Follow-up:** logs for `<start>` to `<end>` are available. Would you like the 7-day trend analysis?

## Rules

- Every number must come from today's log. If it cannot be derived, mark it unavailable. A made-up number is worse than none.
- Never print raw JSON, the `env:` block or full file contents. Count from them; show only aggregates.
- Never open archives or other days' logs unless the user asks.
- Do not flag a commit message that already follows Conventional Commits.
