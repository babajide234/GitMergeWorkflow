const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const required = [
  'GitMergeWorkflow.psm1',
  'GitMergeWorkflow.psd1',
  'bin/cli.js',
  'bin/run.ps1',
];

for (const file of required) {
  const full = path.join(root, file);
  if (!fs.existsSync(full)) {
    console.error(`missing ${file}`);
    process.exit(1);
  }
}

const moduleSource = fs.readFileSync(path.join(root, 'GitMergeWorkflow.psm1'), 'utf8');
if (moduleSource.includes('Invoke-Expression')) {
  console.error('GitMergeWorkflow.psm1 must not call Invoke-Expression');
  process.exit(1);
}

console.log('smoke ok');
