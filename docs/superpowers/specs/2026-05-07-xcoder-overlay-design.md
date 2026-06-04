# Xcoder Overlay Design Spec

## Overview

xcoder layers on top of Claude Code's configuration. When both `.claude/` and `.xcoder/` exist, xcoder reads Claude's config as the base and overlays xcoder-specific customizations on top. xcoder can also run standalone when no Claude Code config exists.

**Key principle**: Xcoder is a delta layer, not a fork. Users put only their customizations in `.xcoder/`; everything else falls through to `.claude/`.

## Directory Structure

### Project Level

```
project/
  .claude/              ← Claude Code base (if exists)
    settings.json
    settings.local.json
    skills/
    commands/
    agents/
  .xcoder/               ← xcoder overlay (if exists)
    settings.json
    settings.local.json
    skills/
    commands/
    agents/
```

### User Level

```
~/.claude/              ← Claude Code global base
  settings.json
  skills/
  commands/
  agents/
~/.xcoder/               ← xcoder global overlay
  settings.json
  settings.local.json
  skills/
  commands/
  agents/
```

`~/.xcoder/` is for user-authored config only. Auth tokens, session data, analytics stay in `~/.claude/`.

## Design: Settings Overlay

### Priority Order (low to high)

```
userSettings            ~/.claude/settings.json
xcoderUserSettings       ~/.xcoder/settings.json         NEW
projectSettings         .claude/settings.json
xcoderProjectSettings    .xcoder/settings.json            NEW
localSettings           .claude/settings.local.json
xcoderLocalSettings      .xcoder/settings.local.json      NEW
flagSettings            --settings CLI flag
policySettings          managed/remote settings
```

### Merge Strategy

Deep merge using existing `settingsMergeCustomizer`:
- Objects: merge field-by-field (xcoder fields override Claude fields, rest preserved)
- Arrays: concatenate + deduplicate
- Scalars: xcoder value wins

`.xcoder/settings.json` is a delta file. Example:

```json
// .claude/settings.json (base)
{ "permissions": { "allow": ["Read", "Edit"] }, "model": "sonnet" }

// .xcoder/settings.json (overlay)
{ "permissions": { "allow": ["Bash(git *)"] }, "model": "opus" }

// Merged result
{ "permissions": { "allow": ["Read", "Edit", "Bash(git *)"] }, "model": "opus" }
```

### Implementation Changes

- `src/utils/settings/constants.ts`: Add `xcoderUserSettings`, `xcoderProjectSettings`, `xcoderLocalSettings` to `SETTING_SOURCES`; update display name functions
- `src/utils/settings/settings.ts`: `getRelativeSettingsFilePathForSource()` handles new sources with hardcoded `.xcoder` paths; `getSettingsForSourceUncached()` returns `{}` if `.xcoder/settings.json` doesn't exist (no error)
- No changes to `loadSettingsFromDisk()` — it iterates all enabled sources automatically

## Design: Skills / Commands / Agents Dual-Scan

### Scan Order

When both directories exist, scan in this order (later wins on collision):

```
managed (policy)
user    (~/.claude/{subdir}/)       Claude base
user    (~/.xcoder/{subdir}/)        xcoder overlay
project (.claude/{subdir}/)         Claude base (walk up to home)
project (.xcoder/{subdir}/)          xcoder overlay (walk up to home)
```

### Collision Resolution

Two-pass deduplication:
1. **Inode dedup** (existing): catches symlinks/hardlinks
2. **Name dedup** (new): same relative path (e.g. `foo/SKILL.md`) → keep `.xcoder/` version

Name dedup uses the path relative to the base directory. If `.claude/skills/foo/SKILL.md` and `.xcoder/skills/foo/SKILL.md` both exist, the `.xcoder/` version wins.

### Implementation Changes

- `src/utils/markdownConfigLoader.ts`:
  - `loadMarkdownFilesForSubdir()`: Add parallel load from `getXcoderConfigHomeDir()/{subdir}` for user-level; add `.xcoder/` project dirs to scan list
  - `getProjectDirsUpToHome()`: At each directory level, check both `.claude/{subdir}` and `.xcoder/{subdir}`, push both if they exist
  - After existing inode dedup, add name-based dedup pass (xcoder wins)
- No changes to `getProjectDotDir()` — backward compatible

### File Change Monitoring

`src/utils/skills/skillChangeDetector.ts` `getWatchablePaths()`: Already uses `getProjectDotDir()` for project dirs. Add `getXcoderConfigHomeDir()/skills` and `getXcoderConfigHomeDir()/commands` to the watch list.

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| Only `.claude/` exists | Identical to today, no overlay |
| Only `.xcoder/` exists | Works standalone, no dependency on Claude |
| Both exist | Overlay activates: xcoder merges on top of Claude |
| `.xcoder/` has empty `skills/` | Only Claude skills loaded |
| Same skill name in both | xcoder version wins |
| `.xcoder/settings.json` missing keys | Falls through to `.claude/` values |
| `~/.xcoder/` doesn't exist | Skip user-level xcoder overlay, use `~/.claude/` only |

## Testing Strategy

### Unit Tests: Settings Merge
- Temp dir with both `.claude/settings.json` and `.xcoder/settings.json`
- Verify deep merge: xcoder overrides matching fields, preserves others
- Verify array concat + dedupe for `allowedTools`
- Regression: only `.claude/` → identical behavior
- Standalone: only `.xcoder/` → works independently

### Unit Tests: Skills/Commands/Agents Dual-Scan
- Temp dir: `.claude/skills/foo/SKILL.md` + `.xcoder/skills/bar/SKILL.md` → both loaded
- Collision: `.claude/skills/foo/SKILL.md` + `.xcoder/skills/foo/SKILL.md` → xcoder wins
- Empty `.xcoder/skills/` → only Claude skills
- Standalone: only `.xcoder/skills/` → works independently

### Integration Tests
- Full overlay scenario: existing `.claude/` config + new `.xcoder/` layer
- Verify settings, skills, commands, agents all merge correctly
- Verify `skillChangeDetector` monitors `.xcoder/` directories
