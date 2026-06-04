import { describe, expect, test } from 'bun:test'
import {
  getSettingsFilePathForSource,
  getRelativeSettingsFilePathForSource,
} from '../settings'

describe('xcoder settings file paths', () => {
  test('getRelativeSettingsFilePathForSource returns xcoder project path', () => {
    expect(getRelativeSettingsFilePathForSource('xcoderProjectSettings')).toBe(
      '.xcoder/settings.json',
    )
  })

  test('getRelativeSettingsFilePathForSource returns xcoder local path', () => {
    expect(getRelativeSettingsFilePathForSource('xcoderLocalSettings')).toBe(
      '.xcoder/settings.local.json',
    )
  })

  test('getSettingsFilePathForSource returns xcoder user settings path', () => {
    const path = getSettingsFilePathForSource('xcoderUserSettings')
    expect(path).toContain('.xcoder')
    expect(path).toContain('settings.json')
  })

  test('getSettingsFilePathForSource returns path for Xcoder project settings', () => {
    const path = getSettingsFilePathForSource('xcoderProjectSettings')
    expect(path).toContain('.xcoder')
    expect(path).toContain('settings.json')
  })

  test('getSettingsFilePathForSource returns path for Xcoder local settings', () => {
    const path = getSettingsFilePathForSource('xcoderLocalSettings')
    expect(path).toContain('.xcoder')
    expect(path).toContain('settings.local.json')
  })
})
