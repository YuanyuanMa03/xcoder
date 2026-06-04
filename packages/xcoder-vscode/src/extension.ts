import * as vscode from 'vscode'

export function activate(context: vscode.ExtensionContext) {
  // 注册启动命令
  const launchCommand = vscode.commands.registerCommand('xcoder.launch', () => {
    // 获取当前活动编辑器的文件路径
    const editor = vscode.window.activeTextEditor
    const filePath = editor ? editor.document.uri.fsPath : ''

    // 创建或复用终端
    const terminal = vscode.window.createTerminal('Xcoder')

    // 发送 xcoder 命令
    if (filePath) {
      terminal.sendText(`xcoder "${filePath}"`)
    } else {
      terminal.sendText('xcoder')
    }

    // 显示终端
    terminal.show()
  })

  // 创建状态栏按钮
  const statusBarItem = vscode.window.createStatusBarItem(
    vscode.StatusBarAlignment.Left,
    100,
  )
  statusBarItem.text = '$(terminal) Xcoder'
  statusBarItem.command = 'xcoder.launch'
  statusBarItem.tooltip = '启动 Xcoder AI 编程助手'
  statusBarItem.show()

  // 注册到订阅列表，确保正确清理
  context.subscriptions.push(launchCommand, statusBarItem)
}

export function deactivate() {}
