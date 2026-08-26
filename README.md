# Git Merge Workflow

Promote **the branch you are on** through a dedicated staging branch, then into a target branch.

On each run this tool takes your current feature (for example `login`), merges it into `login-staging`, merges that into `develop` (or whatever you configure), and pushes. Other feature branches are left alone. There is no `feature/` prefix requirement.

The merge engine is PowerShell. The npm CLI (`gmw`) is a thin wrapper around `pwsh` / Windows PowerShell.

## Requirements

- Git
- **PowerShell 5.1+ or PowerShell Core (`pwsh`)** — required even when installing via npm

macOS:

```bash
brew install --cask powershell
```

## Installation

```bash
npm install -g @babajide234/git-merge-workflow
```

This provides `gmw` and `git-merge-workflow`. You can also install the module with `.\Install.ps1` or copy it into your PowerShell modules directory.

## Usage

Run from your feature branch, not from `develop` / `main` and not from the staging branch:

```powershell
gmw
```

Dry run (no git mutations):

```powershell
gmw -DryRun
# or
gmw -WhatIf
```

Optional commit of **already-tracked** files only (`git add -u`, not `git add .`):

```powershell
gmw -CommitMessage "Feat: Completed login page"
```

Override branches for one run:

```powershell
gmw -TargetBranch "main" -StagingBranch "custom-staging"
```

If pushing staging fails in a non-interactive shell, the workflow stops unless you pass `-SkipStagingPush`.

## Configuration

From the repository root:

```powershell
New-GitWorkflowConfig -TargetBranch "main" -StagingSuffix "-test"
```

Creates `.git-merge-workflow.json`:

```json
{
  "TargetBranch": "main",
  "StagingSuffix": "-test",
  "Remote": "origin"
}
```

Optional `PreMergeHook` is a path **inside the repo** to a `.ps1`, `.sh`, `.cmd`, or `.bat` file. It is executed (not interpolated) before each merge.

## Functions

- `Invoke-GitMergeWorkflow` (aliases: `gmw`, `git-merge-workflow`)
- `New-GitWorkflowConfig`
- `Get-GitWorkflowConfig`

## License

MIT
