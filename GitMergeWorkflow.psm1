
function Get-GitWorkflowConfig {
    <#
    .SYNOPSIS
        Retrieves the Git Merge Workflow configuration from the current repository
    .DESCRIPTION
        Looks for a .git-merge-workflow.json file in the root of the git repository.
        If found, parses and returns the configuration.
        If not found, returns null.
    #>
    [CmdletBinding()]
    param()

    try {
        # Get git root
        $gitRoot = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -eq 0 -and $gitRoot) {
            $configPath = Join-Path $gitRoot ".git-merge-workflow.json"
            if (Test-Path $configPath) {
                return Get-Content $configPath -Raw | ConvertFrom-Json
            }
        }
    } catch {
        Write-Verbose "Error reading config: $_"
    }
    return $null
}

function New-GitWorkflowConfig {
    <#
    .SYNOPSIS
        Creates a new configuration file for the Git Merge Workflow
    .DESCRIPTION
        Creates a .git-merge-workflow.json file in the root of the current git repository.
    .PARAMETER TargetBranch
        The default target branch (default: develop)
    .PARAMETER StagingSuffix
        The suffix for staging branches (default: -staging)
    .PARAMETER Remote
        The default remote name (default: origin)
    .EXAMPLE
        New-GitWorkflowConfig -TargetBranch "main" -StagingSuffix "-test"
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string]$TargetBranch = "develop",
        [string]$StagingSuffix = "-staging",
        [string]$Remote = "origin"
    )

    # Check if in git repo
    $gitRoot = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $gitRoot) {
        Write-Error "Not in a git repository. Please run inside a git repository."
        return
    }

    $configPath = Join-Path $gitRoot ".git-merge-workflow.json"
    
    $config = @{
        TargetBranch = $TargetBranch
        StagingSuffix = $StagingSuffix
        Remote = $Remote
    }

    $json = $config | ConvertTo-Json -Depth 2

    if ($PSCmdlet.ShouldProcess($configPath, "Create configuration file")) {
        $json | Set-Content $configPath
        Write-Host "Configuration file created at: $configPath" -ForegroundColor Green
        Write-Host "Content:" -ForegroundColor Cyan
        Write-Host $json
    }
}

function Invoke-GitMergeWorkflow {
    <#
    .SYNOPSIS
        Automated Git workflow to merge current branch to staging and then to develop
    .DESCRIPTION
        This function automates the process of:
        1. Getting the current branch name
        2. Merging current branch to {branch}-staging
        3. Merging {branch}-staging to develop
        4. Pushing all changes
        
        Configuration can be stored in .git-merge-workflow.json in the repository root.
    .PARAMETER CommitMessage
        Optional commit message if there are uncommitted changes
    .PARAMETER StagingBranch
        Optional custom staging branch name.
        Defaults to {current-branch}{staging-suffix} (configured in JSON or defaults to -staging)
    .PARAMETER TargetBranch
        Optional target branch name.
        Defaults to 'develop' or value in configuration file.
    .PARAMETER Remote
        Optional remote name.
        Defaults to 'origin' or value in configuration file.
    .EXAMPLE
        Invoke-GitMergeWorkflow
    .EXAMPLE
        Invoke-GitMergeWorkflow -CommitMessage "Fix: Updated business contact form"
    .EXAMPLE
        git-merge-workflow -CommitMessage "Feature: Added new component" -WhatIf
    #>
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$false)]
        [string]$CommitMessage = "",
        
        [Parameter(Mandatory=$false)]
        [string]$StagingBranch = "",
        
        [Parameter(Mandatory=$false)]
        [string]$TargetBranch = "",

        [Parameter(Mandatory=$false)]
        [string]$Remote = ""
    )
    
    # Load configuration
    $config = Get-GitWorkflowConfig
    
    # Set defaults (Priority: Parameter > Config > Hardcoded Default)
    if (-not $TargetBranch) {
        $TargetBranch = if ($config.TargetBranch) { $config.TargetBranch } else { "develop" }
    }
    
    if (-not $Remote) {
        $Remote = if ($config.Remote) { $config.Remote } else { "origin" }
    }
    
    $stagingSuffix = if ($config.StagingSuffix) { $config.StagingSuffix } else { "-staging" }

    # Internal helper to execute git commands with error handling
    function Exec-Git {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true, Position=0)]
            [string]$Command,

            [Parameter(Mandatory=$false)]
            [string]$ErrorMessage,

            [Parameter(Mandatory=$false)]
            [switch]$IgnoreError,

            [Parameter(Mandatory=$false)]
            [switch]$ReturnOutput,

            [Parameter(ValueFromRemainingArguments=$true)]
            [string[]]$Arguments
        )

        $cmdDesc = "git $Command $Arguments"
        
        if ($PSCmdlet.ShouldProcess("Git Repository", "Execute: $cmdDesc")) {
            # Construct the command to run
            # Note: We use & operator to run git with arguments
            $output = & git $Command $Arguments 2>&1
            $exitCode = $LASTEXITCODE

            if ($ReturnOutput) {
                return $output
            } elseif ($output) {
                # If not capturing output, write it to the stream (except errors which we handle below)
                $output | ForEach-Object { Write-Verbose $_ }
            }

            if (-not $IgnoreError -and $exitCode -ne 0) {
                $msg = if ($ErrorMessage) { $ErrorMessage } else { "Git command failed: $cmdDesc" }
                throw "$msg`nDetails: $output"
            }
        }
    }

    Write-Host "`n=== Git Merge Workflow ===" -ForegroundColor Cyan
    Write-Host "Starting automated merge process...`n" -ForegroundColor Cyan
    
    # Check if we're in a git repository
    try {
        Exec-Git "rev-parse" "--is-inside-work-tree" -ErrorMessage "Not a git repository" -ReturnOutput | Out-Null
    } catch {
        Write-Error $_.Exception.Message
        return
    }
    
    # Get current branch
    $currentBranch = (git branch --show-current).Trim()
    Write-Host "Current branch: $currentBranch" -ForegroundColor Yellow
    
    if ([string]::IsNullOrWhiteSpace($currentBranch)) {
        Write-Error "Could not determine current branch."
        return
    }

    # Validate we are not on target or explicitly named staging
    if ($currentBranch -eq $TargetBranch) {
        Write-Error "You are currently on the target branch '$TargetBranch'. Please checkout your feature branch first."
        return
    }

    # Define staging branch
    if (-not $StagingBranch) {
        $StagingBranch = "$currentBranch$stagingSuffix"
    }

    if ($currentBranch -eq $StagingBranch) {
        Write-Error "You are currently on the staging branch '$StagingBranch'. Please checkout your feature branch first."
        return
    }

    Write-Host "`nStaging branch: $StagingBranch" -ForegroundColor Yellow
    Write-Host "Target branch:  $TargetBranch" -ForegroundColor Yellow
    Write-Host "Remote:         $Remote" -ForegroundColor Yellow
    
    # Store starting branch to return to it later
    $originalBranch = $currentBranch

    try {
        # Verify remote connection before proceeding
        Write-Host "`nVerifying connection to $Remote..." -ForegroundColor Yellow
        Exec-Git -Command "ls-remote" -Arguments $Remote, "HEAD" -ErrorMessage "Could not connect to remote '$Remote'. Please check your internet connection and git credentials." -ReturnOutput | Out-Null
        Write-Host "Connection successful!" -ForegroundColor Green

        # Check for uncommitted changes
        $status = git status --porcelain
        if ($status) {
            if ($CommitMessage) {
                Write-Host "`nCommitting changes..." -ForegroundColor Yellow
                if ($PSCmdlet.ShouldProcess("Current Branch", "Add all changes and commit with message '$CommitMessage'")) {
                    Exec-Git "add" "." -ErrorMessage "Failed to add changes"
                    Exec-Git "commit" "-m" "$CommitMessage" -ErrorMessage "Failed to commit changes"
                    Write-Host "Changes committed!" -ForegroundColor Green
                }
            } else {
                Write-Error "You have uncommitted changes! Please commit them first or use -CommitMessage parameter"
                git status
                return
            }
        }
        
        # --- Handle Staging Branch ---

        # Check if staging branch exists locally
        $branchExists = git branch --list $StagingBranch
        if (-not $branchExists) {
            Write-Host "`nStaging branch doesn't exist locally. Checking remote..." -ForegroundColor Yellow
            # Check if exists on remote (explicit check to avoid silent failures)
            $remoteBranchExists = $false
            try {
                $lsRemote = Exec-Git -Command "ls-remote" -Arguments "--heads", $Remote, "refs/heads/$StagingBranch" -ReturnOutput
                if ($lsRemote) { $remoteBranchExists = $true }
            } catch {
                Write-Warning "Could not check remote branch: $_"
            }
            
            if ($remoteBranchExists) {
                Write-Host "Fetching remote staging branch..." -ForegroundColor Yellow
                Exec-Git -Command "fetch" -Arguments $Remote, "${StagingBranch}:refs/remotes/$Remote/$StagingBranch"
                Exec-Git -Command "checkout" -Arguments "-b", $StagingBranch, "$Remote/$StagingBranch"
            } else {
                Write-Host "Creating new staging branch..." -ForegroundColor Yellow
                Exec-Git -Command "checkout" -Arguments "-b", $StagingBranch
            }
        } else {
            Write-Host "Checking out staging branch..." -ForegroundColor Yellow
            Exec-Git -Command "checkout" -Arguments $StagingBranch
        }
        
        # Pull latest from staging (if tracked)
        Write-Host "`nPulling latest changes from staging..." -ForegroundColor Yellow
        # We use IgnoreError because it might fail if there's no tracking info yet, which is acceptable here
        Exec-Git -Command "pull" -Arguments $Remote, $StagingBranch -IgnoreError
        
        # Merge current branch into staging
        Write-Host "`nMerging $currentBranch into $StagingBranch..." -ForegroundColor Yellow
        Exec-Git -Command "merge" -Arguments $currentBranch, "--no-ff", "-m", "Merge $currentBranch into $StagingBranch" -ErrorMessage "Merge conflict detected in staging! Please resolve conflicts manually."
        
        Write-Host "Successfully merged to staging!" -ForegroundColor Green
        
        # Push staging
        Write-Host "`nPushing $StagingBranch to remote..." -ForegroundColor Yellow
        try {
            Exec-Git -Command "push" -Arguments "-u", $Remote, $StagingBranch -ErrorMessage "Failed to push staging branch"
            Write-Host "Staging branch pushed!" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to push staging branch to remote."
            Write-Warning "Error: $_"
            if ($PSCmdlet.ShouldContinue("Do you want to skip pushing the staging branch and continue to merge into $TargetBranch?", "Skip Staging Push")) {
                Write-Host "Skipping staging push..." -ForegroundColor Yellow
            } else {
                throw $_
            }
        }
        
        # --- Handle Target Branch ---

        # Checkout target branch
        Write-Host "`nChecking out $TargetBranch branch..." -ForegroundColor Yellow
        Exec-Git "checkout" $TargetBranch -ErrorMessage "Failed to checkout $TargetBranch"
        
        # Pull latest from target
        Write-Host "Pulling latest changes from $TargetBranch..." -ForegroundColor Yellow
        Exec-Git "pull" $Remote $TargetBranch -ErrorMessage "Failed to pull $TargetBranch"
        
        # Merge staging into target
        Write-Host "`nMerging $StagingBranch into $TargetBranch..." -ForegroundColor Yellow
        Exec-Git "merge" $StagingBranch "--no-ff" "-m" "Merge $StagingBranch into $TargetBranch" -ErrorMessage "Merge conflict detected in target! Please resolve conflicts manually."
        
        Write-Host "Successfully merged to target!" -ForegroundColor Green
        
        # Push target
        Write-Host "`nPushing $TargetBranch to remote..." -ForegroundColor Yellow
        Exec-Git "push" $Remote $TargetBranch -ErrorMessage "Failed to push $TargetBranch branch"
        Write-Host "$TargetBranch branch pushed!" -ForegroundColor Green
        
        Write-Host "`n=== Workflow Complete! ===" -ForegroundColor Green
        Write-Host "Summary:" -ForegroundColor Cyan
        Write-Host "  ✓ Merged: $originalBranch → $StagingBranch → $TargetBranch" -ForegroundColor White
        Write-Host "  ✓ All changes pushed to remote`n" -ForegroundColor White

    } catch {
        Write-Error $_.Exception.Message
        Write-Host "`nWorkflow failed. Attempting to return to original branch..." -ForegroundColor Red
    } finally {
        # Return to original branch
        $finalBranch = (git branch --show-current).Trim()
        if ($originalBranch -and $finalBranch -ne $originalBranch) {
            Write-Host "`nReturning to $originalBranch..." -ForegroundColor Yellow
            if ($PSCmdlet.ShouldProcess("Cleanup", "Checkout $originalBranch")) {
                git checkout $originalBranch 2>$null | Out-Null
            }
        }
    }
}

# Create aliases for easier usage
New-Alias -Name git-merge-workflow -Value Invoke-GitMergeWorkflow -Force
New-Alias -Name gmw -Value Invoke-GitMergeWorkflow -Force

Export-ModuleMember -Function Invoke-GitMergeWorkflow, New-GitWorkflowConfig, Get-GitWorkflowConfig -Alias git-merge-workflow, gmw
