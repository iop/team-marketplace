# team-marketplace

## Purpose

A demo Claude Code plugin marketplace for shared development workflows and activity auditing.

## Overview

This marketplace distributes shared workflow tools, code quality checks, and automated activity logging across engineering teams.

Included Plugins:

* **`team-workflow`** — Plugin providing real-time activity logging, and daily log auditing.

## Installation

### Option 1: Add as Marketplace (Recommended)

Add the marketplace repository to Claude Code:

```text
/plugin marketplace add github:iop/team-marketplace
```

Install the `team-workflow` plugin:

```text
/plugin install team-workflow@team-marketplace
```

### Option 2: Run Locally (Development)

Clone the repository and pass the plugin directory directly:

```bash
git clone https://github.com/iop/team-marketplace.git
cd team-marketplace
claude --plugin-dir ./plugins/team-workflow
```

## Plugin Architecture

### `team-workflow`

```text
plugins/team-workflow/
├── .claude-plugin/
│   └── plugin.json
├── hooks/
│   └── log-tool.sh│       
├── skills/
│   └── audit-loghistory/
│       └── SKILL.md
├── log-tool-YYYY-MM-DD.log
└── YYYY-MM.tar.gz
```

## Features & Capabilities

### Skills

#### `audit-loghistory`

Audits daily tool invocations recorded by plugin hooks and generates structured activity reports.

* **Trigger Phrases:** `"log audit"`, `"today report"`, `"what agent did"`, `"tool statistics"`, `"check commit logs"`.
* **Output:**
  * Summary metrics (Total invocations, Active log file, Success rate)
  * Hierarchical **Tree-View** breakdown of tool calls
  * Quick-reference **Summary Table**
  * **Git Commit Quality Review** (evaluates against Conventional Commits)
  * Proactive prompt for 7-day trend analysis
* **Fallback:** Returns `"Data for analysis is currently unavailable."` if no logs exist or the active log file is empty.


### Hooks

#### `PostToolUse` (`log-tool.sh`)

Automatically logs Claude Code tool activity without external binary overhead.

* **Storage Location:** `${CLAUDE_PLUGIN_ROOT}/log-tool-YYYY-MM-DD.log`
* **Recorded Fields:** Timestamp, event type, tool name, execution status, masked parameters.
* **Log Archiving & Retention:**
  * Files older than **7 days** are moved to archive.
  * Archived files are grouped and compressed into weeks archives (`YYYY-WEEK.tar.gz`).

### Commands  

—

## Security

* **Sensitive Data Masking:** Environment variables, tokens, and sensitive parameters are masked prior to writing to disk (`***HIDDEN***`).

## Troubleshooting

### Hook Execution Error (`Permission denied`)

If you downloaded the repository as a raw ZIP archive or created hook scripts locally on a filesystem that stripped executable flags, grant execution permissions manually:

```bash
chmod +x `${CLAUDE_PLUGIN_ROOT}/team-workflow/hooks/log-tool.sh`
```

## License

MIT