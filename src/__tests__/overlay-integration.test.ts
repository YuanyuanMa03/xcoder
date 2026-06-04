import { describe, expect, test, beforeEach, afterEach } from 'bun:test'
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'fs'
import { tmpdir } from 'os'
import { join } from 'path'
import { settingsMergeCustomizer } from '../utils/settings/settings'
import mergeWith from 'lodash-es/mergeWith.js'
import { loadMarkdownFilesForSubdir } from '../utils/markdownConfigLoader'

describe('xcoder overlay integration', () => {
  let tmpDir: string
  let origClaudeConfigDir: string | undefined
  let origXcoderConfigDir: string | undefined
  let origNativeFileSearch: string | undefined

  beforeEach(() => {
    tmpDir = mkdtempSync(join(tmpdir(), 'xcoder-integration-'))
    origClaudeConfigDir = process.env.CLAUDE_CONFIG_DIR
    origXcoderConfigDir = process.env.XCODER_CONFIG_DIR
    origNativeFileSearch = process.env.CLAUDE_CODE_USE_NATIVE_FILE_SEARCH
    process.env.CLAUDE_CONFIG_DIR = join(tmpDir, '.claude')
    process.env.XCODER_CONFIG_DIR = join(tmpDir, '.xcoder')
    process.env.CLAUDE_CODE_USE_NATIVE_FILE_SEARCH = '1'
  })

  afterEach(() => {
    if (origClaudeConfigDir !== undefined) {
      process.env.CLAUDE_CONFIG_DIR = origClaudeConfigDir
    } else {
      delete process.env.CLAUDE_CONFIG_DIR
    }
    if (origXcoderConfigDir !== undefined) {
      process.env.XCODER_CONFIG_DIR = origXcoderConfigDir
    } else {
      delete process.env.XCODER_CONFIG_DIR
    }
    if (origNativeFileSearch !== undefined) {
      process.env.CLAUDE_CODE_USE_NATIVE_FILE_SEARCH = origNativeFileSearch
    } else {
      delete process.env.CLAUDE_CODE_USE_NATIVE_FILE_SEARCH
    }
    rmSync(tmpDir, { recursive: true, force: true })
  })

  test('settings merge: xcoder overlays on claude', () => {
    const base = {
      model: 'sonnet',
      permissions: { allow: ['Read'] },
      env: { FOO: 'bar' },
    }
    const overlay = {
      model: 'opus',
      permissions: { allow: ['Bash(git *)'] },
    }
    const result = mergeWith({}, base, overlay, settingsMergeCustomizer)
    expect(result.model).toBe('opus')
    expect(result.permissions.allow).toContain('Read')
    expect(result.permissions.allow).toContain('Bash(git *)')
    expect(result.env.FOO).toBe('bar')
  })

  test('skills dual-scan: loads from both directories', async () => {
    mkdirSync(join(tmpDir, '.claude', 'skills', 'claude-skill'), {
      recursive: true,
    })
    writeFileSync(
      join(tmpDir, '.claude', 'skills', 'claude-skill', 'SKILL.md'),
      '---\nname: claude-skill\n---\nClaude skill',
    )

    mkdirSync(join(tmpDir, '.xcoder', 'skills', 'xcoder-skill'), {
      recursive: true,
    })
    writeFileSync(
      join(tmpDir, '.xcoder', 'skills', 'xcoder-skill', 'SKILL.md'),
      '---\nname: xcoder-skill\n---\nXcoder skill',
    )

    const files = await loadMarkdownFilesForSubdir('skills', tmpDir)
    const names = files.map(f => f.frontmatter.name)
    expect(names).toContain('claude-skill')
    expect(names).toContain('xcoder-skill')
  })

  test('standalone: only .xcoder works without .claude', async () => {
    mkdirSync(join(tmpDir, '.xcoder', 'skills', 'standalone-skill'), {
      recursive: true,
    })
    writeFileSync(
      join(tmpDir, '.xcoder', 'skills', 'standalone-skill', 'SKILL.md'),
      '---\nname: standalone\n---\nStandalone skill',
    )

    const files = await loadMarkdownFilesForSubdir('skills', tmpDir)
    const names = files.map(f => f.frontmatter.name)
    expect(names).toContain('standalone')
  })

  test('name collision: xcoder skill wins over claude skill', async () => {
    mkdirSync(join(tmpDir, '.claude', 'skills', 'shared'), { recursive: true })
    writeFileSync(
      join(tmpDir, '.claude', 'skills', 'shared', 'SKILL.md'),
      '---\nname: shared\n---\nClaude version',
    )

    mkdirSync(join(tmpDir, '.xcoder', 'skills', 'shared'), { recursive: true })
    writeFileSync(
      join(tmpDir, '.xcoder', 'skills', 'shared', 'SKILL.md'),
      '---\nname: shared\n---\nXcoder version',
    )

    const files = await loadMarkdownFilesForSubdir('skills', tmpDir)
    const sharedFiles = files.filter(f => f.filePath.includes('shared'))
    expect(sharedFiles).toHaveLength(1)
    expect(sharedFiles[0]!.content).toContain('Xcoder version')
  })

  test('commands dual-scan: loads from both directories', async () => {
    mkdirSync(join(tmpDir, '.claude', 'commands'), { recursive: true })
    writeFileSync(
      join(tmpDir, '.claude', 'commands', 'claude-cmd.md'),
      '---\nname: claude-cmd\n---\nClaude command',
    )

    mkdirSync(join(tmpDir, '.xcoder', 'commands'), { recursive: true })
    writeFileSync(
      join(tmpDir, '.xcoder', 'commands', 'xcoder-cmd.md'),
      '---\nname: xcoder-cmd\n---\nXcoder command',
    )

    const files = await loadMarkdownFilesForSubdir('commands', tmpDir)
    const names = files.map(f => f.frontmatter.name)
    expect(names).toContain('claude-cmd')
    expect(names).toContain('xcoder-cmd')
  })
})
