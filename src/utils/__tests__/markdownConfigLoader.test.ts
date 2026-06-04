import { describe, expect, test, beforeEach, afterEach } from 'bun:test'
import { mkdirSync, rmSync, writeFileSync } from 'fs'
import { tmpdir } from 'os'
import { join } from 'path'
import {
  getProjectDirsUpToHome,
  loadMarkdownFilesForSubdir,
} from '../markdownConfigLoader'

describe('getProjectDirsUpToHome with Xcoder overlay', () => {
  let tmpDir: string

  beforeEach(() => {
    tmpDir = join(
      tmpdir(),
      `xcoder-test-${Date.now()}-${Math.random().toString(36).slice(2)}`,
    )
    mkdirSync(tmpDir, { recursive: true })
  })

  afterEach(() => {
    rmSync(tmpDir, { recursive: true, force: true })
  })

  test('returns both .claude and .xcoder dirs when both exist', () => {
    mkdirSync(join(tmpDir, '.claude', 'skills'), { recursive: true })
    mkdirSync(join(tmpDir, '.xcoder', 'skills'), { recursive: true })

    const dirs = getProjectDirsUpToHome('skills', tmpDir)
    const hasClaude = dirs.some(d => d.includes('.claude'))
    const hasXcoder = dirs.some(d => d.includes('.xcoder'))
    expect(hasClaude).toBe(true)
    expect(hasXcoder).toBe(true)
  })

  test('returns only .claude when .xcoder does not exist', () => {
    mkdirSync(join(tmpDir, '.claude', 'skills'), { recursive: true })

    const dirs = getProjectDirsUpToHome('skills', tmpDir)
    const hasClaude = dirs.some(d => d.includes('.claude'))
    const hasXcoder = dirs.some(d => d.includes('.xcoder'))
    expect(hasClaude).toBe(true)
    expect(hasXcoder).toBe(false)
  })

  test('returns only .xcoder when .claude does not exist', () => {
    mkdirSync(join(tmpDir, '.xcoder', 'skills'), { recursive: true })

    const dirs = getProjectDirsUpToHome('skills', tmpDir)
    const hasClaude = dirs.some(d => d.includes('.claude'))
    const hasXcoder = dirs.some(d => d.includes('.xcoder'))
    expect(hasClaude).toBe(false)
    expect(hasXcoder).toBe(true)
  })

  test('returns empty array when neither .claude nor .xcoder exist', () => {
    const dirs = getProjectDirsUpToHome('skills', tmpDir)
    expect(dirs).toEqual([])
  })
})

describe('loadMarkdownFilesForSubdir user-level xcoder', () => {
  let tmpDir: string
  let origClaudeConfigDir: string | undefined
  let origXcoderConfigDir: string | undefined
  let origNativeFileSearch: string | undefined

  beforeEach(() => {
    tmpDir = join(
      tmpdir(),
      `xcoder-user-test-${Date.now()}-${Math.random().toString(36).slice(2)}`,
    )
    mkdirSync(tmpDir, { recursive: true })
    origClaudeConfigDir = process.env.CLAUDE_CONFIG_DIR
    origXcoderConfigDir = process.env.XCODER_CONFIG_DIR
    origNativeFileSearch = process.env.CLAUDE_CODE_USE_NATIVE_FILE_SEARCH
    process.env.CLAUDE_CONFIG_DIR = join(tmpDir, '.claude')
    process.env.XCODER_CONFIG_DIR = join(tmpDir, '.xcoder')
    // Use native file search in tests — ripgrep subprocess can hang in bun test
    process.env.CLAUDE_CODE_USE_NATIVE_FILE_SEARCH = '1'
    mkdirSync(join(tmpDir, '.claude', 'skills'), { recursive: true })
    mkdirSync(join(tmpDir, '.xcoder', 'skills'), { recursive: true })
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

  test('loads skills from both user-level directories', async () => {
    writeFileSync(
      join(tmpDir, '.claude', 'skills', 'claude-user.md'),
      '---\nname: claude-user\n---\nClaude user skill',
    )
    writeFileSync(
      join(tmpDir, '.xcoder', 'skills', 'xcoder-user.md'),
      '---\nname: xcoder-user\n---\nXcoder user skill',
    )

    const files = await loadMarkdownFilesForSubdir('skills', tmpDir)
    const filePaths = files.map(f => f.filePath)
    expect(filePaths.some(p => p.includes('claude-user.md'))).toBe(true)
    expect(filePaths.some(p => p.includes('xcoder-user.md'))).toBe(true)
  })
})

describe('name-based deduplication', () => {
  let tmpDir: string
  let origClaudeConfigDir: string | undefined
  let origXcoderConfigDir: string | undefined
  let origNativeFileSearch: string | undefined

  beforeEach(() => {
    tmpDir = join(
      tmpdir(),
      `xcoder-dedup-test-${Date.now()}-${Math.random().toString(36).slice(2)}`,
    )
    mkdirSync(tmpDir, { recursive: true })
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

  test('xcoder skill overrides claude skill with same relative path', async () => {
    mkdirSync(join(tmpDir, '.claude', 'skills', 'foo'), { recursive: true })
    writeFileSync(
      join(tmpDir, '.claude', 'skills', 'foo', 'SKILL.md'),
      '---\nname: foo\n---\nClaude version',
    )

    mkdirSync(join(tmpDir, '.xcoder', 'skills', 'foo'), { recursive: true })
    writeFileSync(
      join(tmpDir, '.xcoder', 'skills', 'foo', 'SKILL.md'),
      '---\nname: foo\n---\nXcoder version',
    )

    const files = await loadMarkdownFilesForSubdir('skills', tmpDir)
    const fooFiles = files.filter(f => f.filePath.includes('foo'))
    expect(fooFiles).toHaveLength(1)
    expect(fooFiles[0]!.content).toContain('Xcoder version')
  })

  test('both skills loaded when relative paths differ', async () => {
    mkdirSync(join(tmpDir, '.claude', 'skills', 'alpha'), { recursive: true })
    writeFileSync(
      join(tmpDir, '.claude', 'skills', 'alpha', 'SKILL.md'),
      '---\nname: alpha\n---\nAlpha',
    )

    mkdirSync(join(tmpDir, '.xcoder', 'skills', 'beta'), { recursive: true })
    writeFileSync(
      join(tmpDir, '.xcoder', 'skills', 'beta', 'SKILL.md'),
      '---\nname: beta\n---\nBeta',
    )

    const files = await loadMarkdownFilesForSubdir('skills', tmpDir)
    const names = files.map(f => f.frontmatter.name)
    expect(names).toContain('alpha')
    expect(names).toContain('beta')
  })
})
