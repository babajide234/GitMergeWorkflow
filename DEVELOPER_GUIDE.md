# Developer Guide: Git Merge Workflow (GMW)

This guide explains how the **Git Merge Workflow** PowerShell module works and how you can modify it.

## 📂 Project Structure

The module is located at:
`c:\Users\jyde2\OneDrive\Documents\WindowsPowerShell\Modules\GitMergeWorkflow`

- **GitMergeWorkflow.psd1**: The *Module Manifest*. Contains metadata (version, author, description) and defines which files are processed when the module is imported.
- **GitMergeWorkflow.psm1**: The *Script Module*. Contains the actual source code and logic for the functions. **This is where you will make most changes.**
- **Install.ps1**: A helper script to install the module on a new machine.
- **package.json**: configuration for NPM publishing (if applicable).

## 🧠 How It Works

The core logic resides in `GitMergeWorkflow.psm1`.

### Main Function: `Invoke-GitMergeWorkflow`
This is the function executed when you run `gmw`.

1.  **Configuration Loading**:
    - Calls `Get-GitWorkflowConfig` to look for a `.git-merge-workflow.json` file in your repository root.
    - Sets defaults (`develop` for target, `-staging` for suffix) if no config is found.

2.  **Environment Checks**:
    - Checks if `git` is available and if the current directory is a git repository.
    - Validates that you are NOT currently on the target branch (e.g., `develop`) or the staging branch.

3.  **Staging Phase**:
    - Determines the staging branch name (e.g., `feature-xyz-staging`).
    - Checks if the staging branch exists locally or remotely.
    - **Merges** your current feature branch into this staging branch.
    - **Pushes** the staging branch to the remote (`origin`).
        - *Recent Update*: This step now includes error handling. If the push fails (e.g., permissions issue), it asks if you want to skip and proceed.

4.  **Target Phase**:
    - Checkouts the target branch (`develop`).
    - Pulls the latest changes.
    - **Merges** the staging branch into the target branch.
    - **Pushes** the target branch to remote.

5.  **Cleanup**:
    - Returns you to your original feature branch.

### Helper Functions
- `Exec-Git`: A wrapper around git commands to handle errors and verbose output consistently.
- `New-GitWorkflowConfig`: Generates the JSON configuration file.

## 🛠️ How to Edit and Test

Since this is a PowerShell module, changes are not picked up immediately if the module is already loaded in your session.

### 1. Edit the Code
Open `GitMergeWorkflow.psm1` in VS Code or your preferred editor.

**Example**: Adding a new log message.
```powershell
# Inside Invoke-GitMergeWorkflow
Write-Host "Starting my custom workflow..." -ForegroundColor Magenta
```

### 2. Reload the Module
After saving your changes, you must reload the module in your PowerShell terminal to see them take effect.

Run this command:
```powershell
Import-Module GitMergeWorkflow -Force
```
*The `-Force` flag is crucial as it unloads the old version and loads the new one.*

### 3. Test
Run the command again:
```powershell
gmw -WhatIf
```
*Using `-WhatIf` (Dry Run) is a safe way to test logic changes without actually running git commands, provided the script supports it (mostly used for ShouldProcess).*

For real testing, just run `gmw` in a test repository.

## 📦 Configuration

The behavior can be customized per-repository using a `.git-merge-workflow.json` file:

```json
{
  "TargetBranch": "main",
  "StagingSuffix": "-qa",
  "Remote": "upstream"
}
```

You can generate this file using:
```powershell
New-GitWorkflowConfig
```
