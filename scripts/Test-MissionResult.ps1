#requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BriefPath,
    [Parameter(Mandatory)][string]$ResultPath,
    [Parameter(Mandatory)][ValidateSet('mailrun-review')][string]$Profile
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$briefJson = Get-Content -LiteralPath $BriefPath -Raw
$resultJson = Get-Content -LiteralPath $ResultPath -Raw
if (!(Test-Json -Json $briefJson -SchemaFile (Join-Path $repoRoot 'schemas/mission-brief.schema.json'))) { throw 'Invalid brief schema' }
if (!(Test-Json -Json $resultJson -SchemaFile (Join-Path $repoRoot 'schemas/mission-result.schema.json'))) { throw 'Invalid result schema' }
$brief = ConvertFrom-Json -InputObject $briefJson
$result = ConvertFrom-Json -InputObject $resultJson

function Assert-Contract([bool]$Condition, [string]$Message) {
    if (!$Condition) { throw "Contract: $Message" }
}
function Assert-Unique($Values, [string]$Name) {
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($value in $Values) { Assert-Contract ($seen.Add($value)) "Duplicate $Name`: $value" }
}
function Assert-SameSet($Actual, $Expected, [string]$Name) {
    Assert-Unique $Actual $Name
    Assert-Contract (@($Actual).Count -eq @($Expected).Count) "$Name count mismatch"
    foreach ($value in $Actual) { Assert-Contract ($Expected -ccontains $value) "$Name contains unexpected ID: $value" }
}

Assert-Contract ($result.mission_id -ceq $brief.mission_id) 'Mission mismatch'
Assert-Contract ($result.brief_revision -eq $brief.revision) 'Brief revision mismatch'
Assert-Unique @($brief.acceptance_criteria.id) 'brief criterion'
Assert-Unique @($result.actions.action_id) 'action'
Assert-SameSet @($result.acceptance.criterion_id) @($brief.acceptance_criteria.id) 'acceptance'
if ($result.status -eq 'completed') {
    Assert-Contract (@($result.acceptance | Where-Object result -ne 'pass').Count -eq 0) 'Completed result has failed or unknown criteria'
    Assert-Contract ($result.remaining_work.Count -eq 0) 'Completed result has remaining work'
    Assert-Contract (@($result.actions | Where-Object outcome -in @('attempted', 'failed', 'uncertain')).Count -eq 0) 'Completed result has unresolved actions'
}

# This profile never authorizes external execution, even if a brief carries a grant.
# Prepared external changes are logged as local_prepare, not as executed operations.
Assert-Contract ($brief.owner -ceq 'Mailrun') 'Mailrun profile requires Mailrun owner'
Assert-Contract ($null -ne $result.mailrun) 'Mailrun coverage is required'
foreach ($action in $result.actions) {
    Assert-Contract ($action.operation -in @('read', 'local_prepare')) "External operation prohibited in review pilot: $($action.operation)"
}
$coverage = $result.mailrun
Assert-Contract ($coverage.pages.Count -le $coverage.page_limit) 'Page budget exceeded'
Assert-Contract ($coverage.selected_ids.Count -le $coverage.message_limit) 'Message budget exceeded'
Assert-Unique @($coverage.pages.receipt) 'page receipt'
$seenIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$returned = @(
    foreach ($page in $coverage.pages) {
        foreach ($id in $page.ids) { if ($seenIds.Add($id)) { $id } }
    }
)
$expectedSelection = @($returned | Select-Object -First $coverage.message_limit)
Assert-SameSet @($coverage.selected_ids) $expectedSelection 'selected IDs'
Assert-SameSet @($coverage.reviewed_ids + $coverage.unreadable_ids) @($coverage.selected_ids) 'read accounting'
Assert-SameSet @($coverage.relevant_ids + $coverage.unrelated_ids + $coverage.unresolved_ids) @($coverage.selected_ids) 'classification accounting'
foreach ($id in $coverage.unreadable_ids) {
    Assert-Contract ($coverage.unresolved_ids -ccontains $id) 'Unreadable message classified as known'
}
for ($index = 0; $index -lt $coverage.pages.Count - 1; $index++) {
    Assert-Contract ($coverage.pages[$index].continuation -eq 'more') 'Collected page after exhausted or unknown continuation'
}
if ($coverage.collection_state -eq 'exhausted') {
    Assert-Contract ($coverage.pages.Count -gt 0) 'Exhaustion needs a page receipt'
    Assert-Contract ($coverage.pages[-1].continuation -eq 'exhausted') 'False exhaustion claim'
    Assert-Contract ($returned.Count -eq $coverage.selected_ids.Count) 'Exhaustion hides an unselected tail'
}
if ($coverage.collection_state -eq 'capped') {
    Assert-Contract (($coverage.selected_ids.Count -eq $coverage.message_limit) -or ($coverage.pages.Count -eq $coverage.page_limit)) 'Cap claimed before either budget reached'
}
if (($coverage.collection_state -ne 'exhausted') -or ($coverage.unreadable_ids.Count -gt 0)) {
    Assert-Contract ($coverage.gaps.Count -gt 0) 'Coverage gap is undisclosed'
}
if ($result.status -eq 'completed') {
    Assert-Contract ($coverage.pages.Count -gt 0) 'Completion needs collection evidence, including empty inboxes'
    Assert-Contract ($coverage.unreadable_ids.Count -eq 0) 'Completed review has unreadable selected messages'
    Assert-Contract ($coverage.collection_state -ne 'unknown') 'Completed review has unknown collection state'
}
[pscustomobject]@{ Valid = $true; Profile = $Profile; MissionId = $result.mission_id; Status = $result.status }
