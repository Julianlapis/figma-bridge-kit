#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  Figma Bridge Kit — Installer
#  Connects Claude Code, Claude Desktop, or Cursor to Figma
#  via the figma-console-mcp Desktop Bridge.
#
#  Assembled by Julian Alexander (@Julianlapis)
#  https://github.com/Julianlapis
# ─────────────────────────────────────────────────────────────

set -euo pipefail

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

header() {
  echo ""
  echo -e "${CYAN}${BOLD}┌──────────────────────────────────────────┐${RESET}"
  echo -e "${CYAN}${BOLD}│        Figma Bridge Kit — Installer      │${RESET}"
  echo -e "${CYAN}${BOLD}│        assembled by Julian Alexander      │${RESET}"
  echo -e "${CYAN}${BOLD}└──────────────────────────────────────────┘${RESET}"
  echo ""
}

step() {
  echo -e "\n${GREEN}${BOLD}[$1/4]${RESET} ${BOLD}$2${RESET}"
}

warn() {
  echo -e "  ${YELLOW}⚠  $1${RESET}"
}

fail() {
  echo -e "  ${RED}✗  $1${RESET}"
  exit 1
}

ok() {
  echo -e "  ${GREEN}✓${RESET}  $1"
}

info() {
  echo -e "  ${DIM}$1${RESET}"
}

header

# ─── Step 1: Prerequisites ───────────────────────────────────

step 1 "Checking prerequisites"

# Node.js
if command -v node &>/dev/null; then
  NODE_VERSION=$(node --version)
  NODE_MAJOR=$(echo "$NODE_VERSION" | sed 's/v//' | cut -d. -f1)
  if [ "$NODE_MAJOR" -ge 18 ]; then
    ok "Node.js $NODE_VERSION"
  else
    fail "Node.js 18+ required (found $NODE_VERSION). Download: https://nodejs.org"
  fi
else
  fail "Node.js not found. Download: https://nodejs.org"
fi

# npx
if command -v npx &>/dev/null; then
  ok "npx available"
else
  fail "npx not found (comes with Node.js). Reinstall Node: https://nodejs.org"
fi

# Figma Desktop
if [ "$(uname)" = "Darwin" ]; then
  if [ -d "/Applications/Figma.app" ]; then
    ok "Figma Desktop installed"
  else
    warn "Figma Desktop not found at /Applications/Figma.app"
    warn "Install from https://www.figma.com/downloads/ (Desktop app required, not web)"
  fi
elif [ "$(uname)" = "Linux" ]; then
  if command -v figma &>/dev/null || [ -f "/usr/bin/figma" ] || [ -f "$HOME/.local/bin/figma" ]; then
    ok "Figma Desktop found"
  else
    warn "Figma Desktop not detected. Install from https://www.figma.com/downloads/"
  fi
else
  # Windows / other
  info "Verify Figma Desktop is installed: https://www.figma.com/downloads/"
fi

# ─── Step 2: Figma Token ─────────────────────────────────────

step 2 "Figma Personal Access Token"

echo ""
echo -e "  ${BOLD}You need a Figma Personal Access Token.${RESET}"
echo ""
echo "  1. Go to Figma → Settings → Personal access tokens"
echo "     https://www.figma.com/settings#personal-access-tokens"
echo ""
echo "  2. Create a new token with these scopes:"
echo "     • File content: Read"
echo "     • Variables: Read"
echo "     • Comments: Read and write"
echo ""
echo "  3. Copy the token (starts with figd_)"
echo ""

read -rp "  Paste your Figma token here: " FIGMA_TOKEN

if [[ ! "$FIGMA_TOKEN" =~ ^figd_ ]]; then
  warn "Token doesn't start with 'figd_' — are you sure it's correct?"
  read -rp "  Continue anyway? (y/N): " CONTINUE
  if [[ ! "$CONTINUE" =~ ^[Yy] ]]; then
    fail "Aborted. Get your token from https://www.figma.com/settings#personal-access-tokens"
  fi
fi

ok "Token received"

# ─── Step 3: Detect client and configure ─────────────────────

step 3 "Configuring your MCP client"

echo ""
echo "  Which client are you setting up?"
echo ""
echo "  1) Claude Code (CLI)"
echo "  2) Claude Desktop"
echo "  3) Cursor"
echo "  4) Windsurf"
echo "  5) Manual (just show me the config)"
echo ""

read -rp "  Enter 1-5: " CLIENT_CHOICE

case "$CLIENT_CHOICE" in
  1)
    # Claude Code — use the CLI command
    info "Running: claude mcp add figma-console ..."
    claude mcp add figma-console \
      -s user \
      -e FIGMA_ACCESS_TOKEN="$FIGMA_TOKEN" \
      -e ENABLE_MCP_APPS=true \
      -- npx -y figma-console-mcp@latest
    ok "figma-console registered in Claude Code"
    ;;
  2)
    # Claude Desktop
    CONFIG_DIR="$HOME/Library/Application Support/Claude"
    CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"

    if [ "$(uname)" != "Darwin" ]; then
      CONFIG_DIR="$APPDATA/Claude"
      CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"
    fi

    mkdir -p "$CONFIG_DIR"

    if [ -f "$CONFIG_FILE" ]; then
      info "Existing config found at $CONFIG_FILE"
      info "Adding figma-console server..."

      # Use node to merge JSON safely
      node -e "
        const fs = require('fs');
        const config = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8'));
        config.mcpServers = config.mcpServers || {};
        config.mcpServers['figma-console'] = {
          command: 'npx',
          args: ['-y', 'figma-console-mcp@latest'],
          env: {
            FIGMA_ACCESS_TOKEN: '$FIGMA_TOKEN',
            ENABLE_MCP_APPS: 'true'
          }
        };
        fs.writeFileSync('$CONFIG_FILE', JSON.stringify(config, null, 2));
      "
    else
      cat > "$CONFIG_FILE" <<JSONEOF
{
  "mcpServers": {
    "figma-console": {
      "command": "npx",
      "args": ["-y", "figma-console-mcp@latest"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "$FIGMA_TOKEN",
        "ENABLE_MCP_APPS": "true"
      }
    }
  }
}
JSONEOF
    fi
    ok "Config written to $CONFIG_FILE"
    warn "Restart Claude Desktop to load the new server."
    ;;
  3)
    # Cursor
    CONFIG_FILE="$HOME/.cursor/mcp.json"
    mkdir -p "$HOME/.cursor"

    if [ -f "$CONFIG_FILE" ]; then
      node -e "
        const fs = require('fs');
        const config = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8'));
        config.mcpServers = config.mcpServers || {};
        config.mcpServers['figma-console'] = {
          command: 'npx',
          args: ['-y', 'figma-console-mcp@latest'],
          env: {
            FIGMA_ACCESS_TOKEN: '$FIGMA_TOKEN',
            ENABLE_MCP_APPS: 'true'
          }
        };
        fs.writeFileSync('$CONFIG_FILE', JSON.stringify(config, null, 2));
      "
    else
      cat > "$CONFIG_FILE" <<JSONEOF
{
  "mcpServers": {
    "figma-console": {
      "command": "npx",
      "args": ["-y", "figma-console-mcp@latest"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "$FIGMA_TOKEN",
        "ENABLE_MCP_APPS": "true"
      }
    }
  }
}
JSONEOF
    fi
    ok "Config written to $CONFIG_FILE"
    warn "Restart Cursor to load the new server."
    ;;
  4)
    # Windsurf
    CONFIG_DIR="$HOME/.codeium/windsurf"
    CONFIG_FILE="$CONFIG_DIR/mcp_config.json"
    mkdir -p "$CONFIG_DIR"

    if [ -f "$CONFIG_FILE" ]; then
      node -e "
        const fs = require('fs');
        const config = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8'));
        config.mcpServers = config.mcpServers || {};
        config.mcpServers['figma-console'] = {
          command: 'npx',
          args: ['-y', 'figma-console-mcp@latest'],
          env: {
            FIGMA_ACCESS_TOKEN: '$FIGMA_TOKEN',
            ENABLE_MCP_APPS: 'true'
          }
        };
        fs.writeFileSync('$CONFIG_FILE', JSON.stringify(config, null, 2));
      "
    else
      cat > "$CONFIG_FILE" <<JSONEOF
{
  "mcpServers": {
    "figma-console": {
      "command": "npx",
      "args": ["-y", "figma-console-mcp@latest"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "$FIGMA_TOKEN",
        "ENABLE_MCP_APPS": "true"
      }
    }
  }
}
JSONEOF
    fi
    ok "Config written to $CONFIG_FILE"
    warn "Restart Windsurf to load the new server."
    ;;
  5)
    echo ""
    echo -e "  ${BOLD}Add this to your MCP client config:${RESET}"
    echo ""
    echo '  {
    "mcpServers": {
      "figma-console": {
        "command": "npx",
        "args": ["-y", "figma-console-mcp@latest"],
        "env": {
          "FIGMA_ACCESS_TOKEN": "'"$FIGMA_TOKEN"'",
          "ENABLE_MCP_APPS": "true"
        }
      }
    }
  }'
    echo ""
    echo "  Config file locations:"
    echo "  • Claude Desktop (Mac): ~/Library/Application Support/Claude/claude_desktop_config.json"
    echo "  • Claude Code:          ~/.claude.json"
    echo "  • Cursor:               ~/.cursor/mcp.json"
    echo "  • Windsurf:             ~/.codeium/windsurf/mcp_config.json"
    echo ""
    ;;
  *)
    warn "Invalid choice. Run the script again."
    exit 1
    ;;
esac

# ─── Step 4: Desktop Bridge Plugin ───────────────────────────

step 4 "Figma Desktop Bridge plugin"

echo ""
echo -e "  ${BOLD}Last step — import the plugin into Figma Desktop:${RESET}"
echo ""
echo "  1. Open Figma Desktop and open any file"
echo "  2. Go to: Plugins > Development > Import plugin from manifest..."
echo "  3. Select this path:"
echo ""
echo -e "     ${CYAN}~/.figma-console-mcp/plugin/manifest.json${RESET}"
echo ""
echo "     (This path is auto-created the first time the MCP server starts."
echo "      If it doesn't exist yet, run your AI client once — it will start"
echo "      the server and create the plugin directory.)"
echo ""
echo "  4. Run the plugin in your Figma file — it auto-connects via WebSocket"
echo ""

# Pre-warm the server to create the plugin directory
info "Pre-warming the MCP server to create the plugin directory..."
timeout 10 npx -y figma-console-mcp@latest --print-path 2>/dev/null || true

if [ -f "$HOME/.figma-console-mcp/plugin/manifest.json" ]; then
  ok "Plugin directory ready at ~/.figma-console-mcp/plugin/"
else
  info "Plugin directory will be created when your AI client first starts the server."
fi

# ─── Done ─────────────────────────────────────────────────────

echo ""
echo -e "${CYAN}${BOLD}┌──────────────────────────────────────────┐${RESET}"
echo -e "${CYAN}${BOLD}│            Setup complete.               │${RESET}"
echo -e "${CYAN}${BOLD}└──────────────────────────────────────────┘${RESET}"
echo ""
echo "  Test it by asking your AI:"
echo ""
echo -e "    ${DIM}\"Check Figma status\"${RESET}"
echo -e "    ${DIM}\"Create a simple frame with a blue background\"${RESET}"
echo ""
echo -e "  ${DIM}Assembled by Julian Alexander — github.com/Julianlapis${RESET}"
echo ""
