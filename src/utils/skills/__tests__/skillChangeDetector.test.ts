import { describe, expect, test, beforeEach, afterEach } from 'bun:test'
import { mkdirSync, rmSync } from 'fs'
import { tmpdir } from 'os'
import { join } from 'path'
import { getWatchablePaths } from '../skillChangeDetector'

describe('skillChangeDetector xcoder support', () => {
  let tmpDir: string
  let origClaudeConfigDir: string | undefined
  let origXcoderConfigDir: string | undefined
  let origCwd: string

  beforeEach(() => {
    tmpDir = join(
      tmpdir(),
      `xcoder-watch-test-${Date.now()}-${Math.random().toString(36).slice(2)}`,
    )
    mkdirSync(tmpDir, { recursive: true })
    origClaudeConfigDir = process.env.CLAUDE_CONFIG_DIR
    origXcoderConfigDir = process.env.XCODER_CONFIG_DIR
    origCwd = process.cwd()
    process.env.CLAUDE_CONFIG_DIR = join(tmpDir, '.claude')
    process.env.XCODER_CONFIG_DIR = join(tmpDir, '.xcoder')
    // Change cwd to tmpDir so project-level scan doesn't find real .xcoder/
    process.chdir(tmpDir)
  })

  afterEach(() => {
    process.chdir(origCwd)
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
    rmSync(tmpDir, { recursive: true, force: true })
  })

  test('getWatchablePaths includes xcoder user skills dir when it exists', async () => {
    mkdirSync(join(tmpDir, '.xcoder', 'skills'), { recursive: true })
    const paths = await getWatchablePaths()
    expect(paths.some(p => p.includes('.xcoder') && p.includes('skills'))).toBe(
      true,
    )
  })

  test('getWatchablePaths includes xcoder user commands dir when it exists', async () => {
    mkdirSync(join(tmpDir, '.xcoder', 'commands'), { recursive: true })
    const paths = await getWatchablePaths()
    expect(
      paths.some(p => p.includes('.xcoder') && p.includes('commands')),
    ).toBe(true)
  })

  test('getWatchablePaths skips xcoder user skills dir when it does not exist', async () => {
    const paths = await getWatchablePaths()
    expect(paths.some(p => p.includes('.xcoder') && p.includes('skills'))).toBe(
      false,
    )
  })
})
