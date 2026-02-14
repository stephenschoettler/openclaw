---
name: agent-creator
description: Create new OpenClaw agents with Telegram bots, workspaces, and GitHub backup repos. Use when the user wants to create a new agent, add an agent, set up a new bot, or create a specialized assistant.
---

# Agent Creator

Create new OpenClaw agents with full setup: Telegram bot, workspace, config, and GitHub backup.

## Prerequisites

- `gh` CLI authenticated
- User must create Telegram bot via BotFather (can't be automated)
- OpenClaw config at `~/.openclaw/openclaw.json`

## Process

### 1. Get Bot Token from User

Ask the user to:

1. Message `@BotFather` on Telegram
2. Send `/newbot`
3. Follow prompts to name the bot
4. Copy the bot token (format: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`)
5. Provide the token to you

### 2. Gather Agent Details

Ask for:

- **Agent name** (display name, e.g., "Code Monkey")
- **Agent ID** (short slug, e.g., "dev")
- **Model** (default: `anthropic/claude-sonnet-4-5`)
- **Purpose** (what the agent does)
- **Personality** (optional: tone, style, vibe)

### 3. Run Setup Script

```bash
cd /home/w0lf/dev/openclaw/skills/agent-creator
./scripts/create-agent.sh <agent-id> <agent-name> <bot-token> <model>
```

Example:

```bash
./scripts/create-agent.sh dev "Code Monkey" "8478572814:AAE..." "anthropic/claude-sonnet-4-5"
```

The script will:

- Create workspace directory
- Generate AGENTS.md, SOUL.md, USER.md, IDENTITY.md, TOOLS.md
- Patch OpenClaw config
- Create GitHub backup repo
- Init git and push
- Add to backup-sync.sh
- Restart gateway

### 4. Pair Bot

Tell the user to:

1. Find the bot on Telegram (username provided by BotFather)
2. Send `/start` to pair it to their account

## Templates

The script uses templates from `assets/` to generate workspace files. These can be customized based on agent purpose and personality.

## Post-Creation

After creation:

- Agent is live and accessible via Telegram
- Workspace is at `~/.openclaw/workspace-<agent-id>/`
- Backup repo at `github.com/stephenschoettler/openclaw-<agent-id>`
- Auto-syncs daily via cron job

## Troubleshooting

- **Gateway restart fails**: Check config syntax with `openclaw doctor`
- **GitHub repo exists**: Use `--force` flag or delete existing repo first
- **Bot doesn't respond**: Verify bot token in config, check pairing status
