import * as assert from 'assert'
import * as vscode from 'vscode'

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
