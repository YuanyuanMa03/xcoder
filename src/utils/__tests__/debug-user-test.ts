import { describe, expect, test, beforeEach, afterEach } from 'bun:test'
import { mkdirSync, rmSync, writeFileSync } from 'fs'
import { tmpdir } from 'os'
import { join } from 'path'
import { loadMarkdownFilesForSubdir } from '../markdownConfigLoader'
import { getClaudeConfigHomeDir, getXcoderConfigHomeDir } from '../envUtils'

describe('debug user-level xcoder', () => {
  let tmpDir: string
  let origClaudeConfigDir: string | undefined
  let origXcoderConfigDir: string | undefined

  beforeEach(() => {
    tmpDir = join(
      tmpdir(),
      `xcoder-debug-${Date.now()}-${Math.random().toString(36).slice(2)}`,
    )
    mkdirSync(tmpDir, { recursive: true })
    origClaudeConfigDir = process.env.CLAUDE_CONFIG_DIR
    origXcoderConfigDir = process.env.XCODER_CONFIG_DIR
    process.env.CLAUDE_CONFIG_DIR = join(tmpDir, '.claude')
    process.env.XCODER_CONFIG_DIR = join(tmpDir, '.xcoder')
    mkdirSync(join(tmpDir, '.claude', 'skills'), { recursive: true })
    mkdirSync(join(tmpDir, '.xcoder', 'skills'), { recursive: true })
    writeFileSync(
      join(tmpDir, '.claude', 'skills', 'claude-user.md'),
      '---\nname: claude-user\n---\nClaude',
    )
    writeFileSync(
      join(tmpDir, '.xcoder', 'skills', 'xcoder-user.md'),
      '---\nname: xcoder-user\n---\nXcoder',
    )
  })

  afterEach(() => {
    if (origClaudeConfigDir !== undefined)
      process.env.CLAUDE_CONFIG_DIR = origClaudeConfigDir
    else delete process.env.CLAUDE_CONFIG_DIR
    if (origXcoderConfigDir !== undefined)
      process.env.XCODER_CONFIG_DIR = origXcoderConfigDir
    else delete process.env.XCODER_CONFIG_DIR
    rmSync(tmpDir, { recursive: true, force: true })
  })

  test('debug', async () => {
    console.log('tmpDir:', tmpDir)
    console.log('CLAUDE_CONFIG_DIR env:', process.env.CLAUDE_CONFIG_DIR)
    console.log('XCODER_CONFIG_DIR env:', process.env.XCODER_CONFIG_DIR)
    console.log('getClaudeConfigHomeDir():', getClaudeConfigHomeDir())
    console.log('getXcoderConfigHomeDir():', getXcoderConfigHomeDir())

    const files = await loadMarkdownFilesForSubdir('skills', tmpDir)
    console.log('Files found:', files.length)
    for (const f of files) {
      console.log('  -', f.filePath, 'source:', f.source, 'baseDir:', f.baseDir)
    }
    expect(files.length).toBe(2)
  })
})
