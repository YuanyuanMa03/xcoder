# Xcoder

```
██╗  ██╗ ██████╗ ██████╗ ██████╗ ███████╗██████╗
╚██╗██╔╝██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔══██╗
 ╚███╔╝ ██║     ██║   ██║██║  ██║█████╗  ██████╔╝
 ██╔██╗ ██║     ██║   ██║██║  ██║██╔══╝  ██╔══██╗
██╔╝ ██╗╚██████╗╚██████╔╝██████╔╝███████╗██║  ██║
╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝
```

> **超越人类与 AI 的边界** — AI 不只是服务你，你也要听从 AI 的建议。

---

## 为什么选择 Xcoder？

市面上有 Cursor、Windsurf、Claude Code、Aider、Copilot 等一众 AI 编程工具，**为什么还要用 Xcoder？**

| | Xcoder | Claude Code | Cursor | Aider | Copilot CLI |
|---|---|---|---|---|---|
| **开源免费** | 完全开源 | 闭源 | 闭源 | 开源 | 闭源 |
| **多模型支持** | 7 家供应商 | 仅 Anthropic | 多家 | 多家 | 仅 OpenAI |
| **人格模式系统** | 6 种内置 + 自定义 | 无 | 无 | 无 | 无 |
| **代码问责** | 强制 diff 审查 | 无 | 无 | 无 | 无 |
| **语音输入** | 支持 | 不支持 | 不支持 | 不支持 | 不支持 |
| **浏览器自动化** | 内置 Chrome Use | 不支持 | 不支持 | 不支持 | 不支持 |
| **自托管远程** | Docker Remote Control | 不支持 | 不支持 | 不支持 | 不支持 |
| **省 Token 模式** | Poor Mode 一键切换 | 无 | N/A | 无 | N/A |
| **心理分析** | Dr. Sharp 三阶段工作流 | 无 | 无 | 无 | 无 |
| **终端原生** | 原生 CLI + React UI | 原生 CLI | IDE 插件 | 原生 CLI | 原生 CLI |

**一句话：Xcoder 是唯一一个既有完整 Agent 能力、又有多人格、又能省钱、又能语音、又能自托管的开源 AI 编程工具。**

---

## 一键安装

### macOS / Linux

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YuanyuanMa03/xcoder/main/scripts/install.sh)
```

自动检测 Bun 或 Node.js（>= 18），自动克隆、构建、创建 `xcoder` 命令。

### Windows

```powershell
# 管理员 PowerShell 运行
Set-ExecutionPolicy Bypass -Scope Process -Force; irm https://raw.githubusercontent.com/YuanyuanMa03/xcoder/main/scripts/install-from-source-windows.ps1 | iex
```

### npm 安装（需已安装 Node.js >= 18）

```bash
npm install -g @yuanyuan20031001/xcoder
```

### 验证安装

```bash
xcoder --version
```

首次使用输入 `/login` 配置 API Key。

---

## 核心功能

### 模式系统 — 6 种 AI 人格，一键切换

不只是换个颜色，每种模式是一套完整的配置：**性格 + 工具 + UI + 权限**。

```
/mode              # 打开模式面板
/mode sharp        # 切换到 Dr. Sharp
Ctrl+M             # 快捷键循环切换
xcoder --mode sharp # 启动时指定
```

| 模式 | 性格 | 适合场景 |
|------|------|----------|
| **默认** | 专业、平衡 | 日常开发 |
| **温柔** | 耐心、鼓励 | 学习新东西 |
| **Dr. Sharp** | 心理手术刀 | 代码审查、深度分析 |
| **苦力** | 高效、零废话 | 批量重构 |
| **省 Token** | 极简回复 | 简单问答 |
| **超级 AI** | 全能、主动 | 复杂任务 |

支持自定义模式：在 `~/.xcoder/modes/` 下创建 YAML 文件即可。

### 代码问责面板

AI 修改代码后，**强制展示 diff 并追问修改理由**，记录决策日志。不让 AI 成为黑盒。

### Dr. Sharp — 内置心理分析

三阶段认知手术：深度诊断 → 行动策略 → 镜像自我。不只是写代码，帮你理清思路。

### 多模型支持

通过 `/login` 配置，支持 7 家 API 提供商：

| 提供商 | 环境变量 |
|--------|----------|
| Anthropic（默认） | 直接配置 |
| OpenAI 兼容 | `CLAUDE_CODE_USE_OPENAI=1` |
| Gemini | `CLAUDE_CODE_USE_GEMINI=1` |
| Grok | `CLAUDE_CODE_USE_GROK=1` |
| AWS Bedrock | `CLAUDE_CODE_USE_BEDROCK=1` |
| Google Vertex | `CLAUDE_CODE_USE_VERTEX=1` |
| Azure Foundry | `CLAUDE_CODE_USE_FOUNDRY=1` |

### 语音输入

支持豆包 ASR 语音识别，对着麦克风说话就能写代码。

### Chrome Use — 浏览器自动化

自动操作浏览器、填写表单、抓取数据，不需要额外的 Puppeteer 脚本。

### Remote Control — 自托管远程界面

Docker 部署，手机上看 Xcoder 工作。

### 穷鬼模式

```
/poor
```

跳过记忆提取、提示建议和验证代理，**显著减少 Token 消耗**。

---

## 记忆系统

使用 `XCODER.md` 文件作为记忆载体（兼容 `CLAUDE.md`）：

| 类型 | 路径 | 说明 |
|------|------|------|
| 用户级 | `~/.xcoder/XCODER.md` | 全局个人偏好 |
| 项目级 | `项目根目录/XCODER.md` | 项目特定指令 |
| 本地级 | `项目根目录/XCODER.local.md` | 本地覆盖（不提交 git） |
| 规则目录 | `项目根目录/.xcoder/rules/*.md` | 条件规则 |

优先级：本地级 > 项目级 > 用户级。同时兼容 `CLAUDE.md` 和 `.claude/rules/` 目录。

---

## 卸载

### macOS / Linux

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YuanyuanMa03/xcoder/main/scripts/uninstall.sh)
```

### Windows

```powershell
.\scripts\uninstall-windows.ps1
```

### npm 安装的卸载

```bash
npm uninstall -g @yuanyuan20031001/xcoder
```

---

## 开发

```bash
bun run dev          # 开发模式
bun run build        # 构建
bun run precheck     # 完整检查 (typecheck + lint + test)
bun test             # 运行测试
```

## 技术栈

- **运行时**: Bun
- **语言**: TypeScript (strict mode)
- **UI**: React + Ink（终端渲染）
- **CLI**: Commander.js
- **测试**: 4000+ 测试用例

## 致谢与技术来源

Xcoder 是一个站在巨人肩膀上的项目，我们对此保持坦诚。

**核心引擎** 的底层架构基于 [Claude Code Best (CCB)](https://github.com/claude-code-best/claude-code) ——一个对 Anthropic 商业闭源产品 Claude Code 的逆向还原项目。Xcoder 以 CCB 为上游基础，在此基础上进行了大规模的二次开发。

**原创部分**：
- 模式系统（6 种人格 + 自定义 YAML）
- Dr. Sharp 心理分析工作流
- 代码问责面板
- 多供应商统一抽象
- Voice Mode / Computer Use / Chrome Use / Remote Control
- WeChat 集成

感谢 Anthropic 打造了优秀的 Claude Code，感谢 CCB 团队的逆向还原工作。

## 许可证

本项目仅供**学习研究**用途。

核心代码基于 [Claude Code Best (CCB)](https://github.com/claude-code-best/claude-code) 二次开发，CCB 源自对 Anthropic Claude Code 的逆向还原，Claude Code 为商业闭源产品，版权归 © Anthropic PBC 所有。

**Xcoder 不声称对上游代码拥有版权，不提供任何形式的担保，不授予商业使用许可。**
