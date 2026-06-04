import * as path from 'node:path'
import Mocha from 'mocha'
import { glob } from 'glob'

export async function run(): Promise<void> {
  const mocha = new Mocha({
    ui: 'tdd',
    color: true,
  })

  const testsRoot = path.resolve(__dirname)
  const files: string[] = await glob('**/**.test.js', { cwd: testsRoot })
  for (const f of files) {
    mocha.addFile(path.resolve(testsRoot, f))
  }

  return new Promise<void>((resolve, reject) => {
    mocha.run((failures: number) => {
      if (failures > 0) {
        reject(new Error(`${failures} tests failed.`))
      } else {
        resolve()
      }
    })
  })
}
