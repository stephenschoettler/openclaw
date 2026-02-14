#!/bin/bash
set -e

# Usage: create-agent.sh <agent-id> <agent-name> <bot-token> <model>

if [ $# -lt 3 ]; then
  echo "Usage: $0 <agent-id> <agent-name> <bot-token> [model]"
  echo "Example: $0 dev \"Code Monkey\" \"8478572814:AAE...\" \"anthropic/claude-sonnet-4-5\""
  exit 1
fi

AGENT_ID="$1"
AGENT_NAME="$2"
BOT_TOKEN="$3"
MODEL="${4:-anthropic/claude-sonnet-4-5}"

WORKSPACE_DIR="$HOME/.openclaw/workspace-$AGENT_ID"
REPO_NAME="openclaw-$AGENT_ID"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$(dirname "$SCRIPT_DIR")/assets"

echo "=== Creating agent: $AGENT_NAME (ID: $AGENT_ID) ==="

# 1. Create workspace directory
echo "Creating workspace at $WORKSPACE_DIR..."
mkdir -p "$WORKSPACE_DIR"

# 2. Generate workspace files from templates
echo "Generating workspace files..."
cp "$ASSETS_DIR/AGENTS.md" "$WORKSPACE_DIR/AGENTS.md"
cp "$ASSETS_DIR/SOUL.md" "$WORKSPACE_DIR/SOUL.md"
cp "$ASSETS_DIR/USER.md" "$WORKSPACE_DIR/USER.md"
cp "$ASSETS_DIR/IDENTITY.md" "$WORKSPACE_DIR/IDENTITY.md"
cp "$ASSETS_DIR/TOOLS.md" "$WORKSPACE_DIR/TOOLS.md"

# Customize templates
sed -i "s/__AGENT_NAME__/$AGENT_NAME/g" "$WORKSPACE_DIR"/*.md
sed -i "s/__AGENT_ID__/$AGENT_ID/g" "$WORKSPACE_DIR"/*.md

# 3. Patch OpenClaw config
echo "Patching OpenClaw config..."
python3 "$SCRIPT_DIR/patch-config.py" "$AGENT_ID" "$AGENT_NAME" "$BOT_TOKEN" "$MODEL"

# 4. Create GitHub repo
echo "Creating GitHub backup repo..."
gh repo create "stephenschoettler/$REPO_NAME" --private --description "$AGENT_NAME agent workspace backup" || echo "Repo may already exist"

# 5. Init git and push
echo "Initializing git..."
cd "$WORKSPACE_DIR"
git init
git add -A
git commit -m "Initial $AGENT_NAME workspace setup"
git remote add origin "https://github.com/stephenschoettler/$REPO_NAME.git" || git remote set-url origin "https://github.com/stephenschoettler/$REPO_NAME.git"
git branch -M main
git push -u origin main -f

# 6. Add to backup-sync.sh
echo "Adding to backup sync..."
BACKUP_SCRIPT="$HOME/.openclaw/scripts/backup-sync.sh"
if ! grep -q "workspace-$AGENT_ID:$REPO_NAME" "$BACKUP_SCRIPT"; then
  sed -i "/WORKSPACES=(/a\  \"workspace-$AGENT_ID:$REPO_NAME\"" "$BACKUP_SCRIPT"
  echo "Added to backup-sync.sh"
else
  echo "Already in backup-sync.sh"
fi

# 7. Restart gateway
echo "Restarting gateway..."
pkill -SIGUSR1 -f "openclaw gateway" || echo "Gateway not running or restart failed"

echo ""
echo "=== Agent created successfully! ==="
echo "Agent ID: $AGENT_ID"
echo "Agent Name: $AGENT_NAME"
echo "Model: $MODEL"
echo "Workspace: $WORKSPACE_DIR"
echo "Repo: https://github.com/stephenschoettler/$REPO_NAME"
echo ""
echo "Next steps:"
echo "1. Find your bot on Telegram (@<bot-username>)"
echo "2. Send /start to pair it"
