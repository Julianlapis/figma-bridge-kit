# Figma Bridge Kit

> Give your AI full read/write access to Figma.
> One script. Five minutes. 94+ tools.

This kit connects **Claude Code**, **Claude Desktop**, **Cursor**, or **Windsurf** to Figma Desktop through the [figma-console-mcp](https://github.com/southleft/figma-console-mcp) Desktop Bridge. Once connected, your AI can read designs, create components, manage design tokens, build layouts, and take screenshots, all through natural language.

---

## What you get

| Capability | What it means |
|---|---|
| **Read designs** | Extract variables, components, styles, file structure |
| **Create in Figma** | Build frames, shapes, text, full layouts via Plugin API |
| **Design tokens** | Create, update, rename variables (no Enterprise plan needed) |
| **FigJam boards** | Stickies, flowcharts, tables, code blocks |
| **Slides** | Create, reorder, set transitions. Full presentation control |
| **Screenshots** | Visual debugging and verification loops |
| **94+ tools** | Full MCP surface area |

---

## Requirements

- **Node.js 18+**: [download](https://nodejs.org)
- **Figma Desktop**: [download](https://www.figma.com/downloads/) (the desktop app, not web)
- **A Figma Personal Access Token**: [create one](https://www.figma.com/settings#personal-access-tokens)
- **An MCP client**: Claude Code, Claude Desktop, Cursor, or Windsurf

---

## Install

### Option A: Run the script (recommended)

```bash
cd figma-bridge-kit
./install.sh
```

The script:
1. Checks prerequisites (Node.js, Figma Desktop)
2. Walks you through creating a Figma token
3. Registers the MCP server in your chosen client
4. Pre-warms the server to create the plugin directory

### Option B: Manual setup

If you prefer to configure things yourself:

**1. Get your Figma token**

Go to [Figma Settings > Personal access tokens](https://www.figma.com/settings#personal-access-tokens). Create a token with these scopes:
- File content: **Read**
- Variables: **Read**
- Comments: **Read and write**

Copy the token (starts with `figd_`).

**2. Register the MCP server**

For **Claude Code**:
```bash
claude mcp add figma-console -s user \
  -e FIGMA_ACCESS_TOKEN=figd_YOUR_TOKEN \
  -e ENABLE_MCP_APPS=true \
  -- npx -y figma-console-mcp@latest
```

For **Claude Desktop**, **Cursor**, or **Windsurf**, add this to your config file:

```json
{
  "mcpServers": {
    "figma-console": {
      "command": "npx",
      "args": ["-y", "figma-console-mcp@latest"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "figd_YOUR_TOKEN",
        "ENABLE_MCP_APPS": "true"
      }
    }
  }
}
```

Config file locations:

| Client | Path |
|---|---|
| Claude Desktop (Mac) | `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Cursor | `~/.cursor/mcp.json` |
| Windsurf | `~/.codeium/windsurf/mcp_config.json` |

**3. Import the Figma plugin**

1. Open Figma Desktop and open any file
2. Go to **Plugins > Development > Import plugin from manifest...**
3. Select `~/.figma-console-mcp/plugin/manifest.json`
4. Run the plugin. It auto-connects via WebSocket

> The plugin directory is created when the MCP server first starts. If the path doesn't exist yet, launch your AI client once and it'll appear.

---

## Test it

Once everything is connected, try these prompts:

```
Check Figma status
```

```
Create a simple frame with a blue background
```

```
Get design variables from [paste a Figma file URL]
```

If status shows a WebSocket connection, you're live.

---

## Troubleshooting

**"Plugin directory doesn't exist"**
The MCP server creates `~/.figma-console-mcp/plugin/` on first run. Start your AI client, wait a few seconds, then check again.

**"Connection failed" or no WebSocket**
Make sure the Figma Desktop Bridge plugin is running in your open Figma file. The plugin needs to be active, not only imported.

**Token doesn't work**
Verify your token starts with `figd_` and has the correct scopes (File content Read, Variables Read, Comments Read+Write). Tokens from the old format won't work.

**Port conflicts**
The server auto-assigns ports 9223-9232. If another process holds all of them, you'll get a connection error. Check with `lsof -i :9223`.

---

## How it works

```
Your AI  -->  MCP Server (npx)  -->  WebSocket  -->  Desktop Bridge Plugin  -->  Figma
```

The MCP server runs as a local process, started by npx when your AI client launches. It opens a WebSocket on port 9223 (or the next available port up to 9232). The Desktop Bridge plugin inside Figma connects to that WebSocket and executes commands using the Figma Plugin API.

No cloud relay needed. Everything stays local.

---

## What's inside this kit

```
figma-bridge-kit/
  README.md        This file
  install.sh       Interactive setup script
```

The kit doesn't bundle the MCP server itself. `npx figma-console-mcp@latest` pulls the latest version each time, so you get new tools and fixes without re-downloading anything.

---

## Credits

[figma-console-mcp](https://github.com/southleft/figma-console-mcp) is built by [Southleft](https://github.com/southleft). This kit packages the setup experience.

---

<sub>Assembled by **Julian Alexander** · [github.com/Julianlapis](https://github.com/Julianlapis) · Strategy Director at Code & Theory</sub>
