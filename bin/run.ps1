$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $PSScriptRoot "..\GitMergeWorkflow.psd1"
$modulePath = (Resolve-Path $modulePath).ProviderPath

Import-Module $modulePath -Force

Invoke-GitMergeWorkflow @args
