#!/usr/bin/env python3
"""Patch OpenClaw config to add a new agent."""

import json
import sys
from pathlib import Path

def patch_config(agent_id, agent_name, bot_token, model):
    config_path = Path.home() / ".openclaw" / "openclaw.json"
    
    with open(config_path) as f:
        config = json.load(f)
    
    workspace_path = f"/home/{Path.home().name}/.openclaw/workspace-{agent_id}"
    
    # Add agent to agents.list
    agent_entry = {
        "id": agent_id,
        "name": agent_name,
        "workspace": workspace_path,
        "model": model
    }
    
    if agent_id not in [a["id"] for a in config["agents"]["list"]]:
        config["agents"]["list"].append(agent_entry)
    
    # Add binding
    binding_entry = {
        "agentId": agent_id,
        "match": {
            "channel": "telegram",
            "accountId": agent_id
        }
    }
    
    if not any(b.get("agentId") == agent_id for b in config.get("bindings", [])):
        # Insert before the main binding (keep it last)
        main_idx = next((i for i, b in enumerate(config["bindings"]) if b.get("agentId") == "main"), None)
        if main_idx is not None:
            config["bindings"].insert(main_idx, binding_entry)
        else:
            config["bindings"].append(binding_entry)
    
    # Add Telegram account
    if "accounts" not in config["channels"]["telegram"]:
        config["channels"]["telegram"]["accounts"] = {}
    
    config["channels"]["telegram"]["accounts"][agent_id] = {
        "dmPolicy": "pairing",
        "botToken": bot_token,
        "groupPolicy": "allowlist",
        "streamMode": "partial"
    }
    
    # Write back
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)
    
    print(f"✓ Config patched for agent '{agent_name}' (ID: {agent_id})")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: patch-config.py <agent-id> <agent-name> <bot-token> [model]")
        sys.exit(1)
    
    agent_id = sys.argv[1]
    agent_name = sys.argv[2]
    bot_token = sys.argv[3]
    model = sys.argv[4] if len(sys.argv) > 4 else "anthropic/claude-sonnet-4-5"
    
    patch_config(agent_id, agent_name, bot_token, model)
