#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

const args = process.argv.slice(2);
const isWin = process.platform === 'win32';
const psExecutable = isWin ? 'powershell' : 'pwsh';
const scriptPath = path.resolve(__dirname, 'run.ps1');

const child = spawn(psExecutable, ['-NoProfile', '-File', scriptPath, ...args], {
    stdio: 'inherit',
    shell: false // set to false to avoid shell injection, we are executing pwsh directly
});

child.on('error', (err) => {
    if (err.code === 'ENOENT') {
        console.error(`Error: Could not find '${psExecutable}'. Please ensure PowerShell is installed.`);
        if (!isWin) {
            console.error('On macOS/Linux, install PowerShell via Homebrew: brew install --cask powershell');
        }
    } else {
        console.error('Failed to start PowerShell process:', err);
    }
    process.exit(1);
});

child.on('exit', (code) => {
    process.exit(code);
});
