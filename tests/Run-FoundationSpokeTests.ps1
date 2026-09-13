#requires -Version 7.4
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$briefSchema = Join-Path $repoRoot 'schemas/mission-brief.schema.json'
$resultSchema = Join-Path $repoRoot 'schemas/mission-result.schema.json'
$script:passed = 0

function Assert-Foundation([bool]$Condition, [string]$Message) {
    if (!$Condition) { throw "FAIL $Message" }
}

function Assert-SameSet($Actual, $Expected, [string]$Name) {
    Assert-Foundation (@($Actual).Count -eq @($Expected).Count) "$Name count mismatch"
    foreach ($item in $Actual) { Assert-Foundation ($Expected -ccontains $item) "$Name contains unexpected value: $item" }
    Assert-Foundation ((@($Actual) | Select-Object -Unique).Count -eq @($Actual).Count) "$Name has duplicates"
}

$cases = @(
    @{ Owner='Opportunity Fit'; Skill='opportunity-fit'; Brief='opportunity-fit-foundation-brief.json'; Result='opportunity-fit-foundation-result.json'; Template='fit-review.md' },
    @{ Owner='Tracker Steward'; Skill='tracker-steward'; Brief='tracker-steward-foundation-brief.json'; Result='tracker-steward-foundation-result.json'; Template='tracker-review.md' },
    @{ Owner='Interview Prep'; Skill='interview-prep'; Brief='interview-prep-foundation-brief.json'; Result='interview-prep-foundation-result.json'; Template='interview-brief.md' },
    @{ Owner='Sitrep'; Skill='sitrep'; Brief='sitrep-foundation-brief.json'; Result='sitrep-foundation-result.json'; Template='sitrep.md' }
)

foreach ($case in $cases) {
    $briefPath = Join-Path $repoRoot (Join-Path 'examples' $case.Brief)
    $resultPath = Join-Path $repoRoot (Join-Path 'examples' $case.Result)
    $skillPath = Join-Path $repoRoot (Join-Path (Join-Path 'skills' $case.Skill) 'SKILL.md')
    $templatePath = Join-Path $repoRoot (Join-Path (Join-Path (Join-Path 'skills' $case.Skill) 'assets') $case.Template)
    $briefJson = Get-Content -LiteralPath $briefPath -Raw
    $resultJson = Get-Content -LiteralPath $resultPath -Raw
    Assert-Foundation (Test-Path -LiteralPath $skillPath) "$($case.Owner) skill is missing"
    Assert-Foundation (Test-Path -LiteralPath $templatePath) "$($case.Owner) template is missing"
    Assert-Foundation (Test-Json -Json $briefJson -SchemaFile $briefSchema) "$($case.Owner) brief fails schema"
    Assert-Foundation (Test-Json -Json $resultJson -SchemaFile $resultSchema) "$($case.Owner) result fails schema"
    $brief = ConvertFrom-Json -InputObject $briefJson
    $result = ConvertFrom-Json -InputObject $resultJson
    Assert-Foundation ($brief.owner -ceq $case.Owner) "$($case.Owner) brief owner mismatch"
    Assert-Foundation ($result.mission_id -ceq $brief.mission_id) "$($case.Owner) mission mismatch"
    Assert-Foundation ($result.brief_revision -eq $brief.revision) "$($case.Owner) brief revision mismatch"
    Assert-Foundation (@($brief.authority.grants).Count -eq 0) "$($case.Owner) foundation fixture must not carry a grant"
    Assert-Foundation (@($brief.authority.proposed_red_actions).Count -eq 0) "$($case.Owner) foundation fixture must not propose red work"
    Assert-SameSet @($result.acceptance.criterion_id) @($brief.acceptance_criteria.id) "$($case.Owner) acceptance"
    Assert-Foundation ($result.status -eq 'completed') "$($case.Owner) fixture is not complete"
    Assert-Foundation (@($result.remaining_work).Count -eq 0) "$($case.Owner) completed fixture has remaining work"
    Assert-Foundation (@($result.acceptance | Where-Object result -ne 'pass').Count -eq 0) "$($case.Owner) completed fixture has incomplete acceptance"
    foreach ($action in $result.actions) {
        Assert-Foundation ($action.operation -in @('read', 'local_prepare')) "$($case.Owner) foundation fixture declares external operation $($action.operation)"
        Assert-Foundation ($null -eq $action.grant_reference) "$($case.Owner) foundation fixture unexpectedly uses a grant"
        Assert-Foundation ($action.outcome -in @('confirmed', 'prepared')) "$($case.Owner) foundation fixture has unresolved action"
    }
    $script:passed++
    "PASS $($case.Owner) foundation contract"
}

"$script:passed foundation spoke tests passed. Synthetic records only; no live sources or external services invoked."
