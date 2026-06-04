# Xcoder Overlay Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement xcoder overlay system — settings merge, skills/commands/agents dual-scan, user-level `~/.xcoder/` directory.

**Architecture:** Add xcoder settings sources to existing priority chain; extend `loadMarkdownFilesForSubdir` to scan `.xcoder/` alongside `.claude/`; name-based dedup with xcoder winning on collision.

**Tech Stack:** TypeScript, bun:test, lodash mergeWith, chokidar

**Spec:** `docs/superpowers/specs/2026-05-07-xcoder-overlay-design.md`

---

## Chunk 0: Prerequisites

### Task 0: Add XCODER_CONFIG_DIR env var support and update external callers

**Files:**
- Modify: `src/utils/envUtils.ts`
- Modify: `src/utils/permissions/filesystem.ts`
- Modify: `src/utils/sandbox/sandbox-adapter.ts`

- [ ] **Step 1: Add XCODER_CONFIG_DIR env var to getXcoderConfigHomeDir**

In `src/utils/envUtils.ts`, update `getXcoderConfigHomeDir`:

```typescript
export const getXcoderConfigHomeDir = memoize(
  (): string => {
    return (
      process.env.XCODER_CONFIG_DIR ?? join(homedir(), '.xcoder')
    ).normalize('NFC')
  },
  () => process.env.XCODER_CONFIG_DIR,
)
```

This mirrors `getClaudeConfigHomeDir` which respects `CLAUDE_CONFIG_DIR`. Enables testability by allowing tests to override the xcoder config directory.

- [ ] **Step 2: Update filesystem.ts to handle xcoder sources**

In `src/utils/permissions/filesystem.ts`, find the switch on `SettingSource` (around line 756) and add xcoder cases:

```typescript
case 'xcoderUserSettings':
case 'xcoderProjectSettings':
case 'xcoderLocalSettings':
  return getSettingsRootPathForSource(source)
```

- [ ] **Step 3: Update sandbox-adapter.ts to handle xcoder sources**

In `src/utils/sandbox/sandbox-adapter.ts`, find any switch on `SettingSource` and add xcoder cases:

```typescript
case 'xcoderUserSettings':
case 'xcoderProjectSettings':
case 'xcoderLocalSettings':
  return getSettingsRootPathForSource(source)
```

- [ ] **Step 4: Commit**

```bash
git add src/utils/envUtils.ts src/utils/permissions/filesystem.ts src/utils/sandbox/sandbox-adapter.ts
git commit -m "feat: add XCODER_CONFIG_DIR env var and update external callers for xcoder sources"
```

---

## Chunk 1: Settings Overlay

### Task 1: Add xcoder setting sources to constants

**Files:**
- Modify: `src/utils/settings/constants.ts`
- Test: `src/utils/settings/__tests__/config.test.ts`

- [ ] **Step 1: Write failing test for new setting sources**

```typescript
// Add to src/utils/settings/__tests__/config.test.ts

describe('xcoder setting sources', () => {
  test('SETTING_SOURCES includes xcoder sources in correct order', () => {
    const sources = Array.from(SETTING_SOURCES)
    const userIdx = sources.indexOf('userSettings')
    const xcoderUserIdx = sources.indexOf('xcoderUserSettings')
    const projIdx = sources.indexOf('projectSettings')
    const xcoderProjIdx = sources.indexOf('xcoderProjectSettings')
    const localIdx = sources.indexOf('localSettings')
    const xcoderLocalIdx = sources.indexOf('xcoderLocalSettings')

    // xcoder comes after its Claude counterpart
    expect(xcoderUserIdx).toBeGreaterThan(userIdx)
    expect(xcoderProjIdx).toBeGreaterThan(projIdx)
    expect(xcoderLocalIdx).toBeGreaterThan(localIdx)
    // xcoder comes before the next Claude source
    expect(xcoderUserIdx).toBeLessThan(projIdx)
    expect(xcoderProjIdx).toBeLessThan(localIdx)
  })

  test('getSettingSourceName returns correct names for xcoder sources', () => {
    expect(getSettingSourceName('xcoderUserSettings')).toBe('xcoder user')
    expect(getSettingSourceName('xcoderProjectSettings')).toBe('xcoder project')
    expect(getSettingSourceName('xcoderLocalSettings')).toBe('xcoder project, gitignored')
  })

  test('getSourceDisplayName returns correct names for xcoder sources', () => {
    expect(getSourceDisplayName('xcoderUserSettings')).toBe('Xcoder User')
    expect(getSourceDisplayName('xcoderProjectSettings')).toBe('Xcoder Project')
    expect(getSourceDisplayName('xcoderLocalSettings')).toBe('Xcoder Local')
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bun test src/utils/settings/__tests__/config.test.ts`
Expected: FAIL — `xcoderUserSettings` not in SETTING_SOURCES

- [ ] **Step 3: Implement xcoder setting sources**

In `src/utils/settings/constants.ts`, update `SETTING_SOURCES`:

```typescript
export const SETTING_SOURCES = [
  'userSettings',
  'xcoderUserSettings',      // NEW
  'projectSettings',
  'xcoderProjectSettings',   // NEW
  'localSettings',
  'xcoderLocalSettings',     // NEW
  'flagSettings',
  'policySettings',
] as const
```

Update `getSettingSourceName`:

```typescript
export function getSettingSourceName(source: SettingSource): string {
  switch (source) {
    case 'userSettings': return 'user'
    case 'xcoderUserSettings': return 'xcoder user'
    case 'projectSettings': return 'project'
    case 'xcoderProjectSettings': return 'xcoder project'
    case 'localSettings': return 'project, gitignored'
    case 'xcoderLocalSettings': return 'xcoder project, gitignored'
    case 'flagSettings': return 'cli flag'
    case 'policySettings': return 'managed'
  }
}
```

Update `getSourceDisplayName`:

```typescript
export function getSourceDisplayName(source: SettingSource | 'plugin' | 'built-in'): string {
  switch (source) {
    case 'userSettings': return 'User'
    case 'xcoderUserSettings': return 'Xcoder User'
    case 'projectSettings': return 'Project'
    case 'xcoderProjectSettings': return 'Xcoder Project'
    case 'localSettings': return 'Local'
    case 'xcoderLocalSettings': return 'Xcoder Local'
    case 'flagSettings': return 'Flag'
    case 'policySettings': return 'Managed'
    case 'plugin': return 'Plugin'
    case 'built-in': return 'Built-in'
  }
}
```

Update `getSettingSourceDisplayNameLowercase`:

```typescript
export function getSettingSourceDisplayNameLowercase(source: SettingSource | 'cliArg' | 'command' | 'session'): string {
  switch (source) {
    case 'userSettings': return 'user settings'
    case 'xcoderUserSettings': return 'xcoder user settings'
    case 'projectSettings': return 'shared project settings'
    case 'xcoderProjectSettings': return 'xcoder project settings'
    case 'localSettings': return 'project local settings'
    case 'xcoderLocalSettings': return 'xcoder project local settings'
    case 'flagSettings': return 'command line arguments'
    case 'policySettings': return 'enterprise managed settings'
    case 'cliArg': return 'CLI argument'
    case 'command': return 'command configuration'
    case 'session': return 'current session'
  }
}
```

Update `getSettingSourceDisplayNameCapitalized`:

```typescript
export function getSettingSourceDisplayNameCapitalized(source: SettingSource | 'cliArg' | 'command' | 'session'): string {
  switch (source) {
    case 'userSettings': return 'User settings'
    case 'xcoderUserSettings': return 'Xcoder user settings'
    case 'projectSettings': return 'Shared project settings'
    case 'xcoderProjectSettings': return 'Xcoder project settings'
    case 'localSettings': return 'Project local settings'
    case 'xcoderLocalSettings': return 'Xcoder project local settings'
    case 'flagSettings': return 'Command line arguments'
    case 'policySettings': return 'Enterprise managed settings'
    case 'cliArg': return 'CLI argument'
    case 'command': return 'Command configuration'
    case 'session': return 'Current session'
  }
}
```

Update `EditableSettingSource`:

```typescript
export type EditableSettingSource = Exclude<
  SettingSource,
  'policySettings' | 'flagSettings'
>
```

**Note on `SOURCES` and `parseSettingSourcesFlag`:** xcoder sources are auto-detected (file exists → enable), not CLI-specified. `SOURCES` (used by permission-rule UI) stays unchanged — xcoder settings are editable through the same UI as project settings. `parseSettingSourcesFlag` stays unchanged — `--setting-sources` flag only controls Claude sources. This is intentional; xcoder overlay activates automatically.

Also update the existing test at `src/utils/settings/__tests__/config.test.ts` that asserts exact 5-element array:

```typescript
// Update this existing test (around line 272):
test('contains all sources in order', () => {
  expect(SETTING_SOURCES).toEqual([
    'userSettings', 'xcoderUserSettings', 'projectSettings', 'xcoderProjectSettings',
    'localSettings', 'xcoderLocalSettings', 'flagSettings', 'policySettings',
  ])
})
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bun test src/utils/settings/__tests__/config.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/utils/settings/constants.ts src/utils/settings/__tests__/config.test.ts
git commit -m "feat(settings): add xcoder setting sources to priority chain"
```

---

### Task 2: Wire xcoder settings file paths

**Files:**
- Modify: `src/utils/settings/settings.ts`
- Create: `src/utils/settings/__tests__/settings.test.ts`

- [ ] **Step 1: Create test file and write failing test for xcoder settings file paths**

```typescript
// Create src/utils/settings/__tests__/settings.test.ts

import { describe, expect, test, beforeEach } from 'bun:test'
import { getSettingsFilePathForSource, getRelativeSettingsFilePathForSource } from '../settings'

describe('xcoder settings file paths', () => {
  test('getRelativeSettingsFilePathForSource returns xcoder paths', () => {
    expect(getRelativeSettingsFilePathForSource('xcoderProjectSettings')).toBe('.xcoder/settings.json')
    expect(getRelativeSettingsFilePathForSource('xcoderLocalSettings')).toBe('.xcoder/settings.local.json')
  })

  test('getSettingsFilePathForSource returns xcoder user settings path', () => {
    const path = getSettingsFilePathForSource('xcoderUserSettings')
    expect(path).toContain('.xcoder')
    expect(path).toContain('settings.json')
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bun test src/utils/settings/__tests__/settings.test.ts`
Expected: FAIL — `xcoderProjectSettings` not handled in switch

- [ ] **Step 3: Implement xcoder settings file path resolution**

In `src/utils/settings/settings.ts`, update `getRelativeSettingsFilePathForSource`:

```typescript
export function getRelativeSettingsFilePathForSource(
  source: 'projectSettings' | 'localSettings' | 'xcoderProjectSettings' | 'xcoderLocalSettings',
): string {
  switch (source) {
    case 'projectSettings':
      return join(getProjectDotDir(getOriginalCwd()), 'settings.json')
    case 'localSettings':
      return join(getProjectDotDir(getOriginalCwd()), 'settings.local.json')
    case 'xcoderProjectSettings':
      return join('.xcoder', 'settings.json')
    case 'xcoderLocalSettings':
      return join('.xcoder', 'settings.local.json')
  }
}
```

Update `getSettingsFilePathForSource` to handle xcoder sources:

```typescript
export function getSettingsFilePathForSource(source: SettingSource): string | undefined {
  switch (source) {
    case 'userSettings':
      return join(getSettingsRootPathForSource(source), getUserSettingsFilePath())
    case 'xcoderUserSettings':
      return join(getXcoderConfigHomeDir(), 'settings.json')
    case 'projectSettings':
    case 'localSettings':
    case 'xcoderProjectSettings':
    case 'xcoderLocalSettings':
      return join(getSettingsRootPathForSource(source), getRelativeSettingsFilePathForSource(source))
    case 'policySettings':
      return getManagedSettingsFilePath()
    case 'flagSettings':
      return getFlagSettingsPath()
  }
}
```

Update `getSettingsRootPathForSource` to handle xcoder sources:

```typescript
export function getSettingsRootPathForSource(source: SettingSource): string {
  switch (source) {
    case 'userSettings':
      return resolve(getClaudeConfigHomeDir())
    case 'xcoderUserSettings':
      return resolve(getXcoderConfigHomeDir())
    case 'policySettings':
    case 'projectSettings':
    case 'localSettings':
    case 'xcoderProjectSettings':
    case 'xcoderLocalSettings': {
      return resolve(getOriginalCwd())
    }
    case 'flagSettings': {
      const path = getFlagSettingsPath()
      return path ? dirname(resolve(path)) : resolve(getOriginalCwd())
    }
  }
}
```

**Note:** `policySettings` is grouped with project/local sources (all use `getOriginalCwd()`). The existing behavior is preserved exactly — only new xcoder cases are added.

- [ ] **Step 4: Run test to verify it passes**

Run: `bun test src/utils/settings/__tests__/settings.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/utils/settings/settings.ts src/utils/settings/__tests__/settings.test.ts
git commit -m "feat(settings): wire xcoder settings file paths"
```

---

### Task 3: Test settings deep merge with xcoder overlay

**Files:**
- Test: `src/utils/settings/__tests__/overlay.test.ts` (create)

- [ ] **Step 1: Write integration test for settings merge**

```typescript
// Create src/utils/settings/__tests__/overlay.test.ts

import { describe, expect, test, beforeEach, afterEach } from 'bun:test'
import { mkdtempSync, writeFileSync, rmSync } from 'fs'
import { tmpdir } from 'os'
import { join } from 'path'
import { settingsMergeCustomizer } from '../settings'
import mergeWith from 'lodash-es/mergeWith.js'

describe('xcoder settings overlay merge', () => {
  test('deep merge: xcoder overrides matching fields, preserves others', () => {
    const base = {
      model: 'sonnet',
      permissions: { allow: ['Read', 'Edit'] },
      env: { FOO: 'bar' },
    }
    const overlay = {
      model: 'opus',
      permissions: { allow: ['Bash(git *)'] },
    }
    const result = mergeWith({}, base, overlay, settingsMergeCustomizer)
    expect(result.model).toBe('opus')
    expect(result.permissions.allow).toContain('Read')
    expect(result.permissions.allow).toContain('Edit')
    expect(result.permissions.allow).toContain('Bash(git *)')
    expect(result.env.FOO).toBe('bar')
  })

  test('array concat + dedupe', () => {
    const base = { permissions: { allow: ['Read', 'Edit'] } }
    const overlay = { permissions: { allow: ['Edit', 'Bash(git *)'] } }
    const result = mergeWith({}, base, overlay, settingsMergeCustomizer)
    const allow = result.permissions.allow as string[]
    expect(allow.filter((v: string) => v === 'Edit')).toHaveLength(1)
    expect(allow).toContain('Read')
    expect(allow).toContain('Bash(git *)')
  })

  test('scalar override', () => {
    const base = { model: 'sonnet' }
    const overlay = { model: 'opus' }
    const result = mergeWith({}, base, overlay, settingsMergeCustomizer)
    expect(result.model).toBe('opus')
  })

  test('overlay adds new keys without removing base keys', () => {
    const base = { model: 'sonnet', env: { A: '1' } }
    const overlay = { env: { B: '2' } }
    const result = mergeWith({}, base, overlay, settingsMergeCustomizer)
    expect(result.model).toBe('sonnet')
    expect(result.env.A).toBe('1')
    expect(result.env.B).toBe('2')
  })
})
```

- [ ] **Step 2: Run test to verify it passes**

Run: `bun test src/utils/settings/__tests__/overlay.test.ts`
Expected: PASS (merge logic already exists, we're testing it works for overlay scenarios)

- [ ] **Step 3: Commit**

```bash
git add src/utils/settings/__tests__/overlay.test.ts
git commit -m "test(settings): add overlay merge tests"
```

---

## Chunk 2: Skills / Commands / Agents Dual-Scan

### Task 4: Extend getProjectDirsUpToHome to scan .xcoder/

**Files:**
- Modify: `src/utils/markdownConfigLoader.ts`
- Test: `src/utils/__tests__/markdown.test.ts`

- [ ] **Step 1: Write failing test for dual-scan**

```typescript
// Add to src/utils/__tests__/markdown.test.ts

import { describe, expect, test, beforeEach, afterEach } from 'bun:test'
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'fs'
import { tmpdir } from 'os'
import { join } from 'path'
import { getProjectDirsUpToHome } from '../markdownConfigLoader'

describe('getProjectDirsUpToHome with xcoder overlay', () => {
  let tmpDir: string

  beforeEach(() => {
    tmpDir = mkdtempSync(join(tmpdir(), 'xcoder-test-'))
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
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bun test src/utils/__tests__/markdown.test.ts`
Expected: FAIL — only `.claude` dir returned when both exist

- [ ] **Step 3: Implement dual-scan in getProjectDirsUpToHome**

In `src/utils/markdownConfigLoader.ts`, update `getProjectDirsUpToHome`:

```typescript
export function getProjectDirsUpToHome(
  subdir: ClaudeConfigDirectory,
  cwd: string,
): string[] {
  const home = resolve(homedir()).normalize('NFC')
  const gitRoot = resolveStopBoundary(cwd)
  let current = resolve(cwd)
  const dirs: string[] = []

  while (true) {
    if (normalizePathForComparison(current) === normalizePathForComparison(home)) {
      break
    }

    // Check .claude/ (or .xcoder/ via getProjectDotDir)
    const claudeSubdir = join(current, getProjectDotDir(current), subdir)
    try {
      statSync(claudeSubdir)
      dirs.push(claudeSubdir)
    } catch (e: unknown) {
      if (!isFsInaccessible(e)) throw e
    }

    // Also check the OTHER dot dir (overlay)
    const otherDotDir = getProjectDotDir(current) === '.claude' ? '.xcoder' : '.claude'
    const otherSubdir = join(current, otherDotDir, subdir)
    if (otherSubdir !== claudeSubdir) {
      try {
        statSync(otherSubdir)
        dirs.push(otherSubdir)
      } catch (e: unknown) {
        if (!isFsInaccessible(e)) throw e
      }
    }

    if (gitRoot && normalizePathForComparison(current) === normalizePathForComparison(gitRoot)) {
      break
    }

    const parent = dirname(current)
    if (parent === current) break
    current = parent
  }

  return dirs
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bun test src/utils/__tests__/markdown.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/utils/markdownConfigLoader.ts src/utils/__tests__/markdown.test.ts
git commit -m "feat(loader): extend getProjectDirsUpToHome for .xcoder/ overlay"
```

---

### Task 5: Add user-level xcoder dir to loadMarkdownFilesForSubdir

**Files:**
- Modify: `src/utils/markdownConfigLoader.ts`

- [ ] **Step 1: Write failing test for user-level xcoder loading**

```typescript
// Add to src/utils/__tests__/markdown.test.ts

describe('loadMarkdownFilesForSubdir user-level xcoder', () => {
  let tmpDir: string
  let origClaudeConfigDir: string | undefined
  let origXcoderConfigDir: string | undefined

  beforeEach(() => {
    tmpDir = mkdtempSync(join(tmpdir(), 'xcoder-user-test-'))
    origClaudeConfigDir = process.env.CLAUDE_CONFIG_DIR
    origXcoderConfigDir = process.env.XCODER_CONFIG_DIR
    process.env.CLAUDE_CONFIG_DIR = join(tmpDir, '.claude')
    process.env.XCODER_CONFIG_DIR = join(tmpDir, '.xcoder')
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
    rmSync(tmpDir, { recursive: true, force: true })
  })

  test('loads skills from both user-level directories', async () => {
    writeFileSync(join(tmpDir, '.claude', 'skills', 'claude-user.md'), 'Claude user skill')
    writeFileSync(join(tmpDir, '.xcoder', 'skills', 'xcoder-user.md'), 'Xcoder user skill')

    const files = await loadMarkdownFilesForSubdir('skills', tmpDir)
    const filePaths = files.map(f => f.filePath)
    expect(filePaths.some(p => p.includes('claude-user.md'))).toBe(true)
    expect(filePaths.some(p => p.includes('xcoder-user.md'))).toBe(true)
  })
})
```

- [ ] **Step 2: Implement user-level xcoder loading**

In `src/utils/markdownConfigLoader.ts`, update `loadMarkdownFilesForSubdir`. Find the `Promise.all` block (around line 337) and add xcoder user dir loading:

```typescript
const userDir = join(getClaudeConfigHomeDir(), subdir)
const xcoderUserDir = join(getXcoderConfigHomeDir(), subdir)

const [managedFiles, userFiles, xcoderUserFiles, projectFilesNested] = await Promise.all([
  // Always load managed (policy settings)
  loadMarkdownFiles(managedDir).then(_ =>
    _.map(file => ({
      ...file,
      baseDir: managedDir,
      source: 'policySettings' as const,
    })),
  ),
  // Conditionally load user files
  isSettingSourceEnabled('userSettings') &&
  !(subdir === 'agents' && isRestrictedToPluginOnly('agents'))
    ? loadMarkdownFiles(userDir).then(_ =>
        _.map(file => ({
          ...file,
          baseDir: userDir,
          source: 'userSettings' as const,
        })),
      )
    : Promise.resolve([]),
  // xcoder user files
  isSettingSourceEnabled('userSettings')
    ? loadMarkdownFiles(xcoderUserDir).then(_ =>
        _.map(file => ({
          ...file,
          baseDir: xcoderUserDir,
          source: 'xcoderUserSettings' as const,
        })),
      ).catch(() => []) // xcoder dir may not exist
    : Promise.resolve([]),
  // Conditionally load project files from all directories up to home
  isSettingSourceEnabled('projectSettings') &&
  !(subdir === 'agents' && isRestrictedToPluginOnly('agents'))
    ? Promise.all(
        projectDirs.map(projectDir =>
          loadMarkdownFiles(projectDir).then(_ =>
            _.map(file => ({
              ...file,
              baseDir: projectDir,
              source: 'projectSettings' as const,
            })),
          ),
        ),
      )
    : Promise.resolve([]),
])

const projectFiles = projectFilesNested.flat()
const allFiles = [...managedFiles, ...userFiles, ...xcoderUserFiles, ...projectFiles]
```

- [ ] **Step 3: Run test to verify it passes**

Run: `bun test src/utils/__tests__/markdown.test.ts`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add src/utils/markdownConfigLoader.ts
git commit -m "feat(loader): add user-level xcoder dir to markdown loader"
```

---

### Task 6: Add name-based dedup (xcoder wins)

**Files:**
- Modify: `src/utils/markdownConfigLoader.ts`
- Test: `src/utils/__tests__/markdown.test.ts`

- [ ] **Step 1: Write failing test for name-based dedup**

```typescript
// Add to src/utils/__tests__/markdown.test.ts

describe('name-based deduplication', () => {
  let tmpDir: string

  beforeEach(() => {
    tmpDir = mkdtempSync(join(tmpdir(), 'xcoder-test-'))
  })

  afterEach(() => {
    rmSync(tmpDir, { recursive: true, force: true })
  })

  test('xcoder skill overrides claude skill with same name', async () => {
    // Create .claude/skills/foo/SKILL.md
    mkdirSync(join(tmpDir, '.claude', 'skills', 'foo'), { recursive: true })
    writeFileSync(join(tmpDir, '.claude', 'skills', 'foo', 'SKILL.md'), '---\nname: foo\n---\nClaude version')

    // Create .xcoder/skills/foo/SKILL.md
    mkdirSync(join(tmpDir, '.xcoder', 'skills', 'foo'), { recursive: true })
    writeFileSync(join(tmpDir, '.xcoder', 'skills', 'foo', 'SKILL.md'), '---\nname: foo\n---\nXcoder version')

    const files = await loadMarkdownFilesForSubdir('skills', tmpDir)
    const fooFiles = files.filter(f => f.filePath.includes('foo'))
    expect(fooFiles).toHaveLength(1)
    expect(fooFiles[0].content).toContain('Xcoder version')
  })

  test('both skills loaded when names differ', async () => {
    mkdirSync(join(tmpDir, '.claude', 'skills', 'alpha'), { recursive: true })
    writeFileSync(join(tmpDir, '.claude', 'skills', 'alpha', 'SKILL.md'), '---\nname: alpha\n---\nAlpha')

    mkdirSync(join(tmpDir, '.xcoder', 'skills', 'beta'), { recursive: true })
    writeFileSync(join(tmpDir, '.xcoder', 'skills', 'beta', 'SKILL.md'), '---\nname: beta\n---\nBeta')

    const files = await loadMarkdownFilesForSubdir('skills', tmpDir)
    const names = files.map(f => f.frontmatter.name)
    expect(names).toContain('alpha')
    expect(names).toContain('beta')
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bun test src/utils/__tests__/markdown.test.ts`
Expected: FAIL — both foo files returned instead of just xcoder

- [ ] **Step 3: Implement name-based dedup**

In `src/utils/markdownConfigLoader.ts`, after the existing inode dedup, add name-based dedup:

```typescript
// After existing inode dedup (around line 407), add:

// Name-based dedup: when same relative path exists in both .claude/ and .xcoder/,
// keep the .xcoder/ version (xcoder wins on collision).
const nameSeen = new Map<string, number>() // relativePath -> index in deduplicatedFiles
const nameDedupedFiles: MarkdownFile[] = []

for (const [i, file] of deduplicatedFiles.entries()) {
  // Compute relative path from baseDir (e.g. "foo/SKILL.md")
  const relativePath = file.filePath.slice(file.baseDir.length).replace(/^\//, '')
  const existingIdx = nameSeen.get(relativePath)

  if (existingIdx !== undefined) {
    const existing = nameDedupedFiles[existingIdx]
    // If current file is from .xcoder and existing is from .claude, replace
    if (file.baseDir.includes('.xcoder') && existing && !existing.baseDir.includes('.xcoder')) {
      nameDedupedFiles[existingIdx] = file
      logForDebugging(`Name dedup: .xcoder '${relativePath}' overrides .claude version`)
    }
    // Otherwise skip (existing wins)
    continue
  }

  nameSeen.set(relativePath, nameDedupedFiles.length)
  nameDedupedFiles.push(file)
}

return nameDedupedFiles
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bun test src/utils/__tests__/markdown.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add src/utils/markdownConfigLoader.ts src/utils/__tests__/markdown.test.ts
git commit -m "feat(loader): add name-based dedup with xcoder winning on collision"
```

---

## Chunk 3: File Monitoring & Integration

### Task 7: Watch xcoder directories for changes

**Files:**
- Modify: `src/utils/skills/skillChangeDetector.ts`
- Test: `src/utils/skills/__tests__/skillChangeDetector.test.ts`

- [ ] **Step 1: Write failing test for xcoder watch paths**

```typescript
// Add to src/utils/skills/__tests__/skillChangeDetector.test.ts

import { describe, expect, test, beforeEach, afterEach } from 'bun:test'
import { mkdtempSync, mkdirSync, rmSync } from 'fs'
import { tmpdir } from 'os'
import { join } from 'path'
import { getWatchablePaths } from '../skillChangeDetector'

describe('skillChangeDetector xcoder support', () => {
  let tmpDir: string
  let origClaudeConfigDir: string | undefined
  let origXcoderConfigDir: string | undefined

  beforeEach(() => {
    tmpDir = mkdtempSync(join(tmpdir(), 'xcoder-watch-test-'))
    origClaudeConfigDir = process.env.CLAUDE_CONFIG_DIR
    origXcoderConfigDir = process.env.XCODER_CONFIG_DIR
    process.env.CLAUDE_CONFIG_DIR = join(tmpDir, '.claude')
    process.env.XCODER_CONFIG_DIR = join(tmpDir, '.xcoder')
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
    rmSync(tmpDir, { recursive: true, force: true })
  })

  test('getWatchablePaths includes xcoder user skills dir when it exists', async () => {
    mkdirSync(join(tmpDir, '.xcoder', 'skills'), { recursive: true })
    const paths = await getWatchablePaths()
    expect(paths.some(p => p.includes('.xcoder') && p.includes('skills'))).toBe(true)
  })

  test('getWatchablePaths skips xcoder user skills dir when it does not exist', async () => {
    // No .xcoder dir created
    const paths = await getWatchablePaths()
    expect(paths.some(p => p.includes('.xcoder') && p.includes('skills'))).toBe(false)
  })
})
```

- [ ] **Step 2: Implement xcoder watch paths**

In `src/utils/skills/skillChangeDetector.ts`, update `getWatchablePaths`:

```typescript
async function getWatchablePaths(): Promise<string[]> {
  const fs = getFsImplementation()
  const paths: string[] = []

  // User skills directory (~/.claude/skills)
  const userSkillsPath = getSkillsPath('userSettings', 'skills')
  if (userSkillsPath) {
    try {
      await fs.stat(userSkillsPath)
      paths.push(userSkillsPath)
    } catch {
      // Path doesn't exist, skip it
    }
  }

  // xcoder user skills directory (~/.xcoder/skills)
  const xcoderUserSkillsPath = join(getXcoderConfigHomeDir(), 'skills')
  try {
    await fs.stat(xcoderUserSkillsPath)
    paths.push(xcoderUserSkillsPath)
  } catch {
    // Path doesn't exist, skip it
  }

  // User commands directory (~/.claude/commands)
  const userCommandsPath = getSkillsPath('userSettings', 'commands')
  if (userCommandsPath) {
    try {
      await fs.stat(userCommandsPath)
      paths.push(userCommandsPath)
    } catch {
      // Path doesn't exist, skip it
    }
  }

  // xcoder user commands directory (~/.xcoder/commands)
  const xcoderUserCommandsPath = join(getXcoderConfigHomeDir(), 'commands')
  try {
    await fs.stat(xcoderUserCommandsPath)
    paths.push(xcoderUserCommandsPath)
  } catch {
    // Path doesn't exist, skip it
  }

  // ... rest of function (project skills/commands with getProjectDotDir) stays the same
  // ...

  return paths
}
```

- [ ] **Step 3: Run test to verify it passes**

Run: `bun test src/utils/skills/__tests__/skillChangeDetector.test.ts`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add src/utils/skills/skillChangeDetector.ts
git commit -m "feat(detector): watch xcoder user directories for changes"
```

---

### Task 8: End-to-end integration test

**Files:**
- Test: `src/__tests__/overlay-integration.test.ts` (create)

- [ ] **Step 1: Write integration test**

```typescript
// Create src/__tests__/overlay-integration.test.ts

import { describe, expect, test, beforeEach, afterEach } from 'bun:test'
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'fs'
import { tmpdir } from 'os'
import { join } from 'path'

describe('xcoder overlay integration', () => {
  let tmpDir: string

  beforeEach(() => {
    tmpDir = mkdtempSync(join(tmpdir(), 'xcoder-integration-'))
  })

  afterEach(() => {
    rmSync(tmpDir, { recursive: true, force: true })
  })

  test('settings merge: xcoder overlays on claude', async () => {
    mkdirSync(join(tmpDir, '.claude'))
    writeFileSync(join(tmpDir, '.claude', 'settings.json'), JSON.stringify({
      model: 'sonnet',
      permissions: { allow: ['Read'] },
    }))
    mkdirSync(join(tmpDir, '.xcoder'))
    writeFileSync(join(tmpDir, '.xcoder', 'settings.json'), JSON.stringify({
      model: 'opus',
      permissions: { allow: ['Bash(git *)'] },
    }))

    // Test merge logic directly using settingsMergeCustomizer
    const { settingsMergeCustomizer } = await import('../../utils/settings/settings')
    const mergeWith = (await import('lodash-es/mergeWith.js')).default
    const base = JSON.parse(await import('fs').then(fs => fs.readFileSync(join(tmpDir, '.claude', 'settings.json'), 'utf-8')))
    const overlay = JSON.parse(await import('fs').then(fs => fs.readFileSync(join(tmpDir, '.xcoder', 'settings.json'), 'utf-8')))
    const result = mergeWith({}, base, overlay, settingsMergeCustomizer)
    expect(result.model).toBe('opus')
    expect(result.permissions.allow).toContain('Read')
    expect(result.permissions.allow).toContain('Bash(git *)')
  })

  test('skills dual-scan: loads from both directories', async () => {
    mkdirSync(join(tmpDir, '.claude', 'skills', 'claude-skill'), { recursive: true })
    writeFileSync(join(tmpDir, '.claude', 'skills', 'claude-skill', 'SKILL.md'),
      '---\nname: claude-skill\n---\nClaude skill')

    mkdirSync(join(tmpDir, '.xcoder', 'skills', 'xcoder-skill'), { recursive: true })
    writeFileSync(join(tmpDir, '.xcoder', 'skills', 'xcoder-skill', 'SKILL.md'),
      '---\nname: xcoder-skill\n---\nXcoder skill')

    const { loadMarkdownFilesForSubdir } = await import('../../utils/markdownConfigLoader')
    const files = await loadMarkdownFilesForSubdir('skills', tmpDir)
    const names = files.map(f => f.frontmatter.name)
    expect(names).toContain('claude-skill')
    expect(names).toContain('xcoder-skill')
  })

  test('standalone: only .xcoder works without .claude', async () => {
    mkdirSync(join(tmpDir, '.xcoder', 'skills', 'standalone-skill'), { recursive: true })
    writeFileSync(join(tmpDir, '.xcoder', 'skills', 'standalone-skill', 'SKILL.md'),
      '---\nname: standalone\n---\nStandalone skill')

    const { loadMarkdownFilesForSubdir } = await import('../../utils/markdownConfigLoader')
    const files = await loadMarkdownFilesForSubdir('skills', tmpDir)
    const names = files.map(f => f.frontmatter.name)
    expect(names).toContain('standalone')
  })
})
```

- [ ] **Step 2: Run test to verify it passes**

Run: `bun test src/__tests__/overlay-integration.test.ts`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add src/__tests__/overlay-integration.test.ts
git commit -m "test: add xcoder overlay integration tests"
```

---

### Task 9: Final commit and verification

- [ ] **Step 1: Run full test suite**

Run: `bun test`
Expected: All tests pass, no regressions

- [ ] **Step 2: Verify TypeScript compilation**

Run: `bun run typecheck`
Expected: No type errors

- [ ] **Step 3: Final commit if needed**

```bash
git add -A
git commit -m "feat: complete xcoder overlay system"
```
