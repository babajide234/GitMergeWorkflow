#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

// Path to the PowerShell module
const modulePath = path.resolve(__dirname, '../GitMergeWorkflow.psd1');

// Arguments passed to the CLI
const args = process.argv.slice(2);

// Construct the PowerShell command
// We import the module and then invoke the function with passed arguments
const psCommand = `
    $ErrorActionPreference = 'Stop'
    Import-Module '${modulePath}' -Force
    Invoke-GitMergeWorkflow ${args.join(' ')}
`;

// Determine which PowerShell executable to use (pwsh for Core, powershell for Windows PowerShell)
const psExecutable = process.platform === 'win32' ? 'powershell' : 'pwsh';

const child = spawn(psExecutable, ['-NoProfile', '-Command', psCommand], {
    stdio: 'inherit',
    shell: true
});

child.on('exit', (code) => {
    process.exit(code);
});
