import { existsSync, mkdirSync, readdirSync, readFileSync } from 'fs'
import { join } from 'path'
import { useSyncExternalStore } from 'react'
import { parse as parseYaml } from 'yaml'
import {
  getInitialSettings,
  updateSettingsForSource,
} from '../utils/settings/settings.js'
import { getXcoderConfigHomeDir } from '../utils/envUtils.js'
import { DEFAULT_MODES } from './defaults.js'
import type { XcoderMode } from './types.js'

let currentModeSlug: string | null = null
let customModes: XcoderMode[] | null = null
const modeListeners = new Set<() => void>()

function loadCustomModes(): XcoderMode[] {
  if (customModes !== null) return customModes
  customModes = []
  try {
    const modesDir = join(getXcoderConfigHomeDir(), 'modes')
    if (!existsSync(modesDir)) {
      mkdirSync(modesDir, { recursive: true })
    }
    const files = readdirSync(modesDir).filter(
      f => f.endsWith('.yaml') || f.endsWith('.yml'),
    )
    for (const file of files) {
      try {
        const raw = readFileSync(join(modesDir, file), 'utf-8')
        const data = parseYaml(raw) as Record<string, unknown>
        if (!data.slug || !data.name) continue
        customModes.push({
          name: String(data.name),
          slug: String(data.slug),
          description: String(data.description || ''),
          icon: String(data.icon || '🔧'),
          systemPrompt: String(data.system_prompt || ''),
          ui: {
            accentColor: String(
              (data.ui as Record<string, unknown>)?.accent_color || '#00D4AA',
            ),
            promptPrefix: String(
              (data.ui as Record<string, unknown>)?.prompt_prefix || '',
            ),
          },
          permissions: {
            defaultMode:
              ((data.permissions as Record<string, unknown>)
                ?.default_mode as XcoderMode['permissions']['defaultMode']) ||
              'default',
            memoryExtract: Boolean(
              (data.permissions as Record<string, unknown>)?.memory_extract ??
                true,
            ),
          },
          responseStyle: {
            verbosity:
              ((data.response_style as Record<string, unknown>)
                ?.verbosity as XcoderMode['responseStyle']['verbosity']) ||
              'normal',
          },
        })
      } catch {
        // skip invalid yaml files
      }
    }
  } catch {
    // modes directory may not exist
  }
  return customModes
}

function getAllModes(): XcoderMode[] {
  const custom = loadCustomModes()
  if (custom.length === 0) return DEFAULT_MODES
  // Custom modes override defaults with same slug
  const slugs = new Set(custom.map(m => m.slug))
  return [...custom, ...DEFAULT_MODES.filter(m => !slugs.has(m.slug))]
}

export function getCurrentModeSlug(): string {
  if (currentModeSlug === null) {
    const settings = getInitialSettings() as Record<string, unknown>
    currentModeSlug = (settings.xcoderMode as string) || 'default'
  }
  return currentModeSlug
}

export function getCurrentMode(): XcoderMode {
  const slug = getCurrentModeSlug()
  const modes = getAllModes()
  return modes.find(m => m.slug === slug) ?? DEFAULT_MODES[0]
}

export function setCurrentMode(slug: string): void {
  const modes = getAllModes()
  const mode = modes.find(m => m.slug === slug)
  if (!mode) {
    throw new Error(
      `Unknown mode: ${slug}. Available: ${modes.map(m => m.slug).join(', ')}`,
    )
  }
  currentModeSlug = slug
  updateSettingsForSource('userSettings', { xcoderMode: slug } as Record<
    string,
    unknown
  >)
  for (const listener of modeListeners) listener()
}

function subscribeMode(listener: () => void): () => void {
  modeListeners.add(listener)
  return () => modeListeners.delete(listener)
}

/** Reactive hook — re-renders the component when the mode changes. */
export function useCurrentMode(): XcoderMode {
  return useSyncExternalStore(subscribeMode, getCurrentMode)
}

export function listModes(): XcoderMode[] {
  return getAllModes()
}

export function cycleMode(): XcoderMode {
  const modes = listModes()
  const current = getCurrentModeSlug()
  const idx = modes.findIndex(m => m.slug === current)
  const next = modes[(idx + 1) % modes.length]
  setCurrentMode(next.slug)
  return next
}
