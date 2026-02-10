#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

// Path to the PowerShell module
const modulePath = path.resolve(__dirname, '../GitMergeWorkflow.psd1');

// Arguments passed to the CLI
const args = process.argv.slice(2);

// Determine which PowerShell executable to use
// On Windows: try 'pwsh' (PowerShell Core) first, fallback to 'powershell' (Windows PowerShell)
// On macOS/Linux: must use 'pwsh'
const isWin = process.platform === 'win32';
const psExecutable = isWin ? 'powershell' : 'pwsh';

// Construct the PowerShell command
// We import the module and then invoke the function with passed arguments
// We need to ensure args are passed correctly. 
// Since we are passing a command string, we rely on the user's shell to have parsed quotes,
// and we rejoin them. Ideally, we would quote arguments that contain spaces.
const formattedArgs = args.map(arg => {
    if (arg.includes(' ') && !arg.startsWith('"') && !arg.startsWith("'")) {
        return `"${arg}"`;
    }
    return arg;
}).join(' ');

const psCommand = `
    $ErrorActionPreference = 'Stop'
    Import-Module '${modulePath}' -Force
    Invoke-GitMergeWorkflow ${formattedArgs}
`;

const child = spawn(psExecutable, ['-NoProfile', '-Command', psCommand], {
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
