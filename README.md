# Git Merge Workflow PowerShell Module

Automate your git merge workflow with safety and ease. This module helps you merge your current feature branch to a staging branch (e.g., `feature-branch-staging`), and then to a target branch (e.g., `develop`), ensuring a consistent workflow.

## Features

- **Automated Merging**: Merges current branch -> Staging -> Target.
- **Safety Checks**: Prevents running on wrong branches, checks for uncommitted changes.
- **Conflict Handling**: Stops immediately on merge conflicts so you can resolve them.
- **Automatic Cleanup**: Returns you to your original branch even if the script fails.
- **Configurable**: Define project-specific settings via a JSON configuration file.
- **Dry Run**: Support for `-WhatIf` to preview actions.

## Installation

### Via NPM (Recommended for Node.js users)
You can install this tool globally using npm:

```bash
npm install -g @expedier/git-merge-workflow
```
This will make the `gmw` and `git-merge-workflow` commands available in your terminal.

### Manual Installation
1. Download this repository.
2. Run the included installation script:
   ```powershell
   .\Install.ps1
   ```
   Or copy the `GitMergeWorkflow` folder to your PowerShell modules directory manually.
3. Import the module (if not auto-loaded):
   ```powershell
   Import-Module GitMergeWorkflow
   ```

## Usage

### Basic Usage
Run the workflow from your feature branch:
```powershell
Invoke-GitMergeWorkflow
# OR use the alias
gmw
```

### With Commit Message
If you have uncommitted changes, you can commit them as part of the workflow:
```powershell
gmw -CommitMessage "Feat: Completed login page"
```

### Dry Run (Preview)
See what commands would be executed without actually running them:
```powershell
gmw -WhatIf
```

### Custom Branches
Override default branches on the fly:
```powershell
gmw -TargetBranch "main" -StagingBranch "custom-staging"
```

## Configuration

You can create a configuration file for your project so you don't have to pass parameters every time.

1. Navigate to your project root.
2. Run the configuration generator:
   ```powershell
   New-GitWorkflowConfig -TargetBranch "main" -StagingSuffix "-test"
   ```
   
   This creates a `.git-merge-workflow.json` file:
   ```json
   {
     "TargetBranch": "main",
     "StagingSuffix": "-test",
     "Remote": "origin"
   }
   ```

## Publishing (For Maintainers)

### GitHub Actions
This repository is configured to automatically publish to:
1. **PowerShell Gallery** (if `NUGET_KEY` secret is set)
2. **NPM Registry** (if `NPM_TOKEN` secret is set)

When you create a new Release in GitHub.

### Manual Publishing

**To NPM:**
```bash
npm login
npm publish --access public
```

**To PowerShell Gallery:**
```powershell
Publish-Module -Path . -NuGetApiKey <Your-API-Key>
```

## Functions

- `Invoke-GitMergeWorkflow` (Alias: `gmw`, `git-merge-workflow`): The main workflow command.
- `New-GitWorkflowConfig`: Generates the `.git-merge-workflow.json` configuration file.
- `Get-GitWorkflowConfig`: Reads the current configuration.

## Cross-Platform Support (Mac/Linux)

This tool works on Windows, macOS, and Linux.

### Requirements for macOS/Linux
You must have **PowerShell Core** (`pwsh`) installed.

**macOS (Homebrew):**
```bash
brew install --cask powershell
```

**Linux (Ubuntu):**
```bash
sudo apt-get install -y wget apt-transport-https software-properties-common
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell
```

## License
MIT
