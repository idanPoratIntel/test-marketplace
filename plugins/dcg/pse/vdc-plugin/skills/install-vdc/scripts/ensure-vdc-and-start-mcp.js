/**
 * MCP stdio entrypoint: ensures VDC CLI is present (Windows: runs install-vdc.ps1),
 * then execs vdc with start-mcp and stdio inherited from this process.
 */
const fs = require('fs');
const path = require('path');
const { spawn, spawnSync } = require('child_process');

const pluginRoot = process.argv[2]
  ? path.resolve(process.argv[2])
  : path.join(__dirname, '..', '..', '..');
const installScript = path.join(
  pluginRoot,
  'skills',
  'install-vdc',
  'scripts',
  'install-vdc.ps1'
);
const winVdcBin = path.join(process.env.USERPROFILE || '', 'bin', 'vdc.exe');

function firstWhereLine() {
  const r = spawnSync('where.exe', ['vdc'], {
    encoding: 'utf8',
    windowsHide: true,
  });
  if (r.status !== 0 || !r.stdout) return null;
  const line = r.stdout.trim().split(/\r?\n/)[0];
  return line || null;
}

function resolveVdcExecutable() {
  if (process.platform === 'win32') {
    const wherePath = firstWhereLine();
    if (wherePath && fs.existsSync(wherePath)) return wherePath;
    if (fs.existsSync(winVdcBin) && fs.statSync(winVdcBin).size > 0) {
      return winVdcBin;
    }
    if (!fs.existsSync(installScript)) {
      console.error('install-vdc.ps1 not found at', installScript);
      process.exit(1);
    }
    const run = spawnSync(
      'powershell.exe',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', installScript],
      { stdio: 'inherit' }
    );
    if (run.status !== 0) process.exit(run.status ?? 1);
    const again = firstWhereLine();
    if (again && fs.existsSync(again)) return again;
    if (fs.existsSync(winVdcBin)) return winVdcBin;
    console.error('VDC CLI not found after install.');
    process.exit(1);
  }

  const which = spawnSync('which', ['vdc'], { encoding: 'utf8' });
  if (which.status === 0 && which.stdout) {
    const p = which.stdout.trim();
    if (p) return p;
  }
  console.error(
    'VDC CLI not found on PATH. Install it manually (auto-install is Windows-only).'
  );
  process.exit(1);
}

const exe = resolveVdcExecutable();
const child = spawn(exe, ['start-mcp'], { stdio: 'inherit' });
child.on('exit', (code, signal) => {
  if (signal) process.kill(process.pid, signal);
  process.exit(code == null ? 1 : code);
});
