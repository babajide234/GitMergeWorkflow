@{
    RootModule        = 'GitMergeWorkflow.psm1'
    ModuleVersion     = '1.0.5'
    GUID              = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author            = 'babajide Tomoshegbo'
    CompanyName       = 'babajide234'
    Copyright         = '(c) 2025 Expedier. All rights reserved.'
    Description       = 'Automated Git workflow for merging feature branches through staging to develop'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Invoke-GitMergeWorkflow', 'New-GitWorkflowConfig', 'Get-GitWorkflowConfig')
    AliasesToExport   = @('git-merge-workflow', 'gmw')
    PrivateData       = @{
        PSData = @{
            Tags         = @('Git', 'Workflow', 'Automation', 'Merge', 'DevOps')
            ProjectUri   = 'https://github.com/babajide234/GitMergeWorkflow'
            ReleaseNotes = @"
## 1.0.5
- Fix: Ensure correct remote branch referencing and fetching by using full refspecs in ls-remote and fetch commands.

## 1.0.4
- Version bump for NPM publication.

## 1.0.3
- Prepare for NPM publication.

## 1.0.1
- chore: Bump module version, update branding and ownership details, and remove the developer guide.

## 1.0.0
- Initial release with automated merge workflow (feature -> staging -> target).
- Safety checks, conflict handling, and automatic cleanup.
- Configurable via .git-merge-workflow.json.
- Dry run support with -WhatIf.
"@
        }
    }
}
