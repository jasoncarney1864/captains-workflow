#requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PacketPath,
    [Parameter(Mandatory)][ValidateSet('resume-ready','application-prepared','application-authorized','application-submitted')][string]$Profile,
    [string]$BriefPath,
    [switch]$VerifyArtifact,
    [DateTimeOffset]$At = [DateTimeOffset]::UtcNow
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
function Require([bool]$Condition, [string]$Message) { if (!$Condition) { throw "Career contract: $Message" } }
function Unique($Values) {
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($value in $Values) { Require ($seen.Add($value)) "Duplicate ID: $value" }
}
function SameSet($Left, $Right) {
    Require (@($Left).Count -eq @($Right).Count) 'Set count mismatch'
    foreach ($value in $Left) { Require ($Right -ccontains $value) "Set mismatch: $value" }
}
$json = Get-Content -LiteralPath $PacketPath -Raw
Require (Test-Json -Json $json -SchemaFile (Join-Path $repoRoot 'schemas/career-handoff.schema.json')) 'Invalid packet schema'
$packet = ConvertFrom-Json $json
$resume = $packet.resume
Require ($resume.state -eq 'ready' -and $resume.master_read) 'Resume source/readiness unresolved'
SameSet $resume.source_employment_ids $resume.output_employment_ids
foreach ($claim in $resume.claims) {
    if ($claim.included) { Require ($claim.verification -ne 'unverified' -and $claim.source_references.Count -gt 0) 'Included claim lacks support' }
}
foreach ($dimension in @('package','text','visual')) { Require ($resume.qa.$dimension.result -eq 'pass') "QA incomplete: $dimension" }
if ($VerifyArtifact) {
    Require ([IO.Path]::IsPathFullyQualified($resume.artifact_path)) 'Artifact path must be absolute'
    Require (Test-Path -LiteralPath $resume.artifact_path -PathType Leaf) 'Artifact missing'
    Require ((Get-FileHash -LiteralPath $resume.artifact_path -Algorithm SHA256).Hash.ToLowerInvariant() -ceq $resume.sha256) 'Artifact hash changed'
}
if ($Profile -ne 'resume-ready') {
    Require (![string]::IsNullOrWhiteSpace($BriefPath)) 'Application brief required'
    $briefJson = Get-Content -LiteralPath $BriefPath -Raw
    Require (Test-Json -Json $briefJson -SchemaFile (Join-Path $repoRoot 'schemas/mission-brief.schema.json')) 'Invalid brief schema'
    $brief = ConvertFrom-Json $briefJson
    $app = $packet.application
    Require ($null -ne $app) 'Application packet missing'
    Require ($brief.owner -ceq 'Application Run') 'Wrong application owner'
    Require ($app.mission_id -ceq $brief.mission_id -and $app.brief_revision -eq $brief.revision) 'Application brief mismatch'
    Require ($app.facts_resolved) 'Application facts unresolved'
    Require (@($brief.dependencies | Where-Object state -ne 'satisfied').Count -eq 0) 'Dependency unresolved'
    Require (@($brief.dependencies | Where-Object reference -CEQ $resume.result_reference).Count -eq 1) 'Resume dependency not bound'
    Unique @($app.planned_actions.action_id)
    Unique @($app.operations.action_id)
    Unique @($brief.authority.grants.grant_id)
    Unique @($brief.sources.id)
    Require (@($app.planned_actions | Where-Object action -eq 'submit').Count -eq 1) 'Exactly one submit action required'
    Require (@($app.planned_actions | Where-Object action -eq 'upload').Count -ge 1) 'Resume upload plan required'
    foreach ($plan in $app.planned_actions) {
        if ($plan.action -in @('upload','submit')) { Require ($plan.data_references -ccontains "sha256:$($resume.sha256)") 'Artifact version missing from action' }
    }
    foreach ($op in $app.operations) { Require ($app.planned_actions.action_id -ccontains $op.action_id) 'Unplanned operation' }
    if ($Profile -eq 'application-prepared') {
        Require ($app.state -eq 'prepared' -and $app.operations.Count -eq 0) 'Preparation contains external execution'
    } else {
        if ($Profile -eq 'application-authorized') {
            Require ($app.state -eq 'authorized') 'Application not authorized or retry is uncertain'
            Require (@($app.operations | Where-Object outcome -ne 'confirmed').Count -eq 0) 'Unresolved operation blocks retry'
            $submitId = ($app.planned_actions | Where-Object action -eq 'submit').action_id
            Require (@($app.operations | Where-Object action_id -CEQ $submitId).Count -eq 0) 'Submission already recorded; do not retry'
        } else {
            Require ($app.state -eq 'submitted') 'Submission not confirmed'
            SameSet @($app.operations.action_id) @($app.planned_actions.action_id)
            Require (@($app.operations | Where-Object outcome -ne 'confirmed').Count -eq 0) 'Submission operations unconfirmed'
            Require ($app.confirmation_references.Count -gt 0) 'Submission confirmation missing'
        }
        foreach ($plan in $app.planned_actions) {
            $grants = @($brief.authority.grants | Where-Object grant_id -CEQ $plan.grant_reference)
            Require ($grants.Count -eq 1) 'Applicable grant missing'
            $grant = $grants[0]
            $sources = @($brief.sources | Where-Object reference -CEQ $grant.user_evidence_reference)
            Require (@($sources | Where-Object { $_.kind -eq 'user_statement' -and $_.state -eq 'available' }).Count -eq 1) 'Grant lacks available user evidence'
            foreach ($field in @('action_id','action','destination','scope')) { Require ($grant.approved_action.$field -ceq $plan.$field) "Grant mismatch: $field" }
            SameSet $grant.approved_action.data_references $plan.data_references
            $checkAt = $At
            if ($Profile -eq 'application-authorized') { Require ($grant.state -eq 'active') 'Grant not active' }
            else {
                $checkAt = [DateTimeOffset]($app.operations | Where-Object action_id -CEQ $plan.action_id).at
                Require ($checkAt -le $At) 'Operation timestamp is in the future'
            }
            if ($grant.expires_at) { Require ([DateTimeOffset]$grant.expires_at -gt $checkAt) 'Grant expired at action/check time' }
        }
    }
}
[pscustomobject]@{ Valid=$true; Profile=$Profile; ArtifactVerified=[bool]$VerifyArtifact }
