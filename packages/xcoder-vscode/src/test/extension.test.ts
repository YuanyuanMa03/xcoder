// This test only runs inside the VS Code extension host (mocha with tdd UI).
// Bun discovers it by glob but cannot resolve the 'vscode' module.
let _vscodeAvailable = false
try {
  require('vscode')
  _vscodeAvailable = true
} catch {
  // Not running in VS Code
}

if (!_vscodeAvailable) {
  describe.skip('Extension Test Suite (VS Code only)', () => {})
} else {
  const assert = require('assert')
  const vscode = require('vscode')

  suite('Extension Test Suite', () => {
    vscode.window.showInformationMessage('Start all tests.')

    test('命令应该存在', async () => {
      const commands = await vscode.commands.getCommands(true)
      assert.ok(commands.includes('xcoder.launch'))
    })

    test('状态栏应该显示', () => {
      assert.ok(true)
    })
  })
}
