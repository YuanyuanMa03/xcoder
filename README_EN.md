# Xcoder

```
██╗  ██╗ ██████╗ ██████╗ ██████╗ ███████╗██████╗
╚██╗██╔╝██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔══██╗
 ╚███╔╝ ██║     ██║   ██║██║  ██║█████╗  ██████╔╝
 ██╔██╗ ██║     ██║   ██║██║  ██║██╔══╝  ██╔══██╗
██╔╝ ██╗╚██████╗╚██████╔╝██████╔╝███████╗██║  ██║
╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝
```

> **Beyond the Boundary of Human and AI** — AI doesn't just serve you, you also listen to AI's advice.

### Mascot

Xcoder features a small Unicode block-drawing mascot, rendered as a 3-row × 9-character figure in the terminal:

```
 ▐▛███▜▌     ← head (visor effect)
▐▟█████▙▌    ← body
  ▘▘ ▝▝      ← feet
```

Supports 4 poses (default / look-left / look-right / arms-up). Compatible with all modern terminals; Apple Terminal uses a bg-fill trick to avoid gaps between character rows.

Xcoder is an AI programming CLI tool with a strong personal brand. It's not just your tool, it's your collaborative partner — with the right to question your decisions, proactively suggest better approaches, and engage in equal dialogue with you.

## Quick Start

### npm Install (Recommended)

```bash
npm install -g xcoder-cli
xcoder              # Launch
xcoder --version    # 1.0.0 (xcoder)
```

### Install from Source

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YuanyuanMa03/xcoder/main/scripts/install.sh)
```

## Features

| Feature | Description |
|---------|-------------|
| **Mode System** | 6 built-in modes (default/gentle/sharp/workhorse/token-saver/super-ai) |
| **Dr. Sharp** | Built-in life coach with three-phase psychological analysis |
| **Multi-Provider** | Anthropic/OpenAI/Gemini/Grok compatible |
| **Remote Control** | Docker self-hosted remote interface |
| **Voice Mode** | Voice input with Doubao ASR |
| **Computer Use** | Screen capture, keyboard and mouse control |
| **Chrome Use** | Browser automation, form filling |
| **Web Search** | Built-in web search (Bing/Brave) |

## Mode System

```
/mode              # Display mode selection
/mode sharp        # Switch to Dr. Sharp mode
Ctrl+M             # Cycle through all modes
```

## Tech Stack

- **Runtime**: Bun
- **Language**: TypeScript (strict mode)
- **UI**: React + Ink (terminal rendering)
- **CLI**: Commander.js

## License

This project is for **learning and research** purposes only.

## Acknowledgments

Based on [Claude Code Best (CCB)](https://github.com/claude-code-best/claude-code), with extensive original development on top.

---

For full documentation, see [README.md](README.md) (Chinese version)
