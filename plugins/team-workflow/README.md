# Team Workflow Plugin for Claude Code

## Purpose

The **Team Workflow** plugin is designed to streamline development tasks, track operational history, and manage secure, structured logging directly within your Claude Code environment.

---

## Features

- **Automated Activity Logging**: Captures standard input payloads, precise timestamps (ISO-8601 with timezone), and environment details.
- **Security & Privacy**: Automatically sanitizes environment variables by masking sensitive keys (e.g., tokens, secrets, passwords, credentials, and API keys)[cite: 2].
- **Weekly Archiving**: Automatically groups and compresses past daily log files into weekly `.tar.gz` archives (format: `YYYY-WEEK##.tar.gz`) directly in the plugin root.
- **Safety Checks**: Guarantees that original log files are deleted **only after** verifying the successful creation or update of the corresponding weekly archive.
- **Strict Permissions**: Enforces a strict `umask 077` to ensure log files and archives are readable only by the owner.

---

## File Structure

```text
team-workflow/
├── .claude-plugin/
│   └── plugin.json       # Plugin manifest and configuration
├── skills/
│   └── audit-loghistory/ # Skill for auditing past log histories
├── hooks/
│   └── log-tool.sh       # Core logging, sanitization, and weekly archiving script
└── hooks.json            # Hook bindings configuration