@{
    RootModule = 'GitMergeWorkflow.psm1'
    ModuleVersion = '1.0.1'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'babajide Tomoshegbo'
    CompanyName = 'babajide234'
    Copyright = '(c) 2025 Expedier. All rights reserved.'
    Description = 'Automated Git workflow for merging feature branches through staging to develop'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Invoke-GitMergeWorkflow', 'New-GitWorkflowConfig', 'Get-GitWorkflowConfig')
    AliasesToExport = @('git-merge-workflow', 'gmw')
    PrivateData = @{
        PSData = @{
            Tags = @('Git', 'Workflow', 'Automation', 'Merge', 'DevOps')
            ProjectUri = 'https://github.com/babajide234/GitMergeWorkflow'
        }
    }
}
