#requires -Version 7.4
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$validator = Join-Path $repoRoot 'scripts/Test-MissionResult.ps1'
$baseBrief = Get-Content (Join-Path $repoRoot 'examples/mailrun-review.json') -Raw
$baseResult = Get-Content (Join-Path $repoRoot 'examples/mailrun-result.json') -Raw
$testDirectory = Join-Path ([IO.Path]::GetTempPath()) ('captain-contract-' + [guid]::NewGuid())
$null = New-Item -ItemType Directory -Path $testDirectory
$briefPath = Join-Path $testDirectory 'brief.json'
$resultPath = Join-Path $testDirectory 'result.json'
$script:passed = 0

function Test-Case([string]$Name, [scriptblock]$Change, [string]$ExpectedError = '') {
    $brief = ConvertFrom-Json $baseBrief
    $result = ConvertFrom-Json $baseResult
    & $Change $brief $result
    [IO.File]::WriteAllText($briefPath, ($brief | ConvertTo-Json -Depth 30))
    [IO.File]::WriteAllText($resultPath, ($result | ConvertTo-Json -Depth 30))
    $caught = $null
    try { $null = & $validator -BriefPath $briefPath -ResultPath $resultPath -Profile mailrun-review }
    catch { $caught = $_.Exception.Message }
    if ($ExpectedError) {
        if (!$caught -or $caught -notmatch $ExpectedError) { throw "FAIL $Name`: expected $ExpectedError; received $caught" }
    } elseif ($caught) { throw "FAIL $Name`: $caught" }
    $script:passed++
    "PASS $Name"
}
function Set-Complete($Result) {
    $Result.status = 'completed'
    $Result.remaining_work = @()
    foreach ($item in $Result.acceptance) { $item.result = 'pass' }
    $Result.mailrun.reviewed_ids = @('m1', 'm2', 'm3', 'm4')
    $Result.mailrun.unreadable_ids = @()
    # m4 has now been read, but role details can still remain unresolved.
}

try {
    Test-Case 'Valid partial result with duplicate page IDs' { param($b, $r) }
    Test-Case 'Completed bounded sample need not exhaust inbox' { param($b, $r) Set-Complete $r }
    Test-Case 'Verified empty inbox completes' {
        param($b, $r)
        Set-Complete $r
        $r.mailrun.pages = @(@{receipt='empty-page'; ids=@(); continuation='exhausted'})
        $r.mailrun.collection_state = 'exhausted'
        foreach ($key in @('selected_ids','reviewed_ids','unreadable_ids','relevant_ids','unrelated_ids','unresolved_ids','gaps')) { $r.mailrun.$key = @() }
    }
    Test-Case 'Blocked access records no fabricated coverage' {
        param($b, $r)
        $r.status = 'blocked'
        $r.actions = @()
        $r.mailrun.pages = @()
        $r.mailrun.collection_state = 'unknown'
        foreach ($key in @('selected_ids','reviewed_ids','unreadable_ids','relevant_ids','unrelated_ids','unresolved_ids')) { $r.mailrun.$key = @() }
    }
    Test-Case 'Mission identity mismatch' { param($b, $r) $r.mission_id = 'other-mission' } 'Mission mismatch'
    Test-Case 'Stale brief revision' { param($b, $r) $r.brief_revision = 2 } 'revision mismatch'
    Test-Case 'Missing criterion' { param($b, $r) $r.acceptance = @($r.acceptance[0]) } 'acceptance count mismatch'
    Test-Case 'Duplicate criterion' { param($b, $r) $r.acceptance[1].criterion_id = 'ac-1' } 'Duplicate acceptance'
    Test-Case 'Duplicate action ID' { param($b, $r) $r.actions[1].action_id = 'review-1' } 'Duplicate action'
    Test-Case 'False complete with unknown criterion' { param($b, $r) $r.status = 'completed' } 'failed or unknown criteria'
    Test-Case 'False complete with remaining work' { param($b, $r) foreach ($a in $r.acceptance) { $a.result='pass' }; $r.status='completed' } 'remaining work'
    Test-Case 'Uncertain action cannot close' { param($b, $r) Set-Complete $r; $r.actions[0].outcome='uncertain' } 'unresolved actions'
    Test-Case 'Unreadable selected message cannot close' { param($b, $r) $r.status='completed'; $r.remaining_work=@(); foreach ($a in $r.acceptance) { $a.result='pass' } } 'unreadable selected'
    Test-Case 'Changed query rejected by schema' { param($b, $r) $r.mailrun.query = 'in:inbox' } 'schema|JSON'
    Test-Case 'Unknown operation rejected by schema' { param($b, $r) $r.actions[0].operation = 'magic' } 'schema|JSON'
    Test-Case 'Missing evidence rejected by schema' { param($b, $r) $r.actions[0].evidence_references = @() } 'schema|JSON'
    Test-Case 'Missing coverage rejected' { param($b, $r) $r.PSObject.Properties.Remove('mailrun') } 'coverage is required'
    Test-Case 'Wrong owner rejected' { param($b, $r) $b.owner='Sitrep' } 'requires Mailrun owner'
    Test-Case 'Duplicate selected ID' { param($b, $r) $r.mailrun.selected_ids[3]='m1' } 'schema|JSON'
    Test-Case 'Missing read result' { param($b, $r) $r.mailrun.reviewed_ids=@('m1','m2') } 'read accounting count mismatch'
    Test-Case 'Read and unreadable overlap' { param($b, $r) $r.mailrun.reviewed_ids += 'm4' } 'Duplicate read accounting'
    Test-Case 'Unreadable message cannot have known classification' { param($b, $r) $r.mailrun.relevant_ids += 'm4'; $r.mailrun.unresolved_ids=@() } 'classified as known'
    Test-Case 'False exhaustion with continuation' { param($b, $r) $r.mailrun.collection_state='exhausted' } 'False exhaustion'
    Test-Case 'Unselected page tail cannot disappear' { param($b, $r) $r.mailrun.pages[1].ids += 'm5'; $r.mailrun.pages[1].continuation='exhausted'; $r.mailrun.collection_state='exhausted' } 'unselected tail'
    Test-Case 'Unselected tail allowed when capped and disclosed' { param($b, $r) $r.mailrun.pages[1].ids += 'm5'; $r.mailrun.gaps += 'm5 returned but not selected; preserve for resume' }
    Test-Case 'Premature cap claim' { param($b, $r) $r.mailrun.message_limit=25 } 'Cap claimed'
    Test-Case 'Hidden coverage gap' { param($b, $r) $r.mailrun.gaps=@() } 'gap is undisclosed'
    Test-Case 'Page budget exceeded' { param($b, $r) $r.mailrun.page_limit=1 } 'Page budget exceeded'
    Test-Case 'Message budget exceeded' { param($b, $r) $r.mailrun.message_limit=3 } 'Message budget exceeded'
    Test-Case 'Page after exhaustion' { param($b, $r) $r.mailrun.pages[0].continuation='exhausted' } 'Collected page after'
    Test-Case 'Duplicate page receipt' { param($b, $r) $r.mailrun.pages[1].receipt='page-1' } 'Duplicate page receipt'
    foreach ($operation in @('external_draft','send','submit','upload','delete','label_change','tracker_write','other_external_write')) {
        Test-Case "Review blocks $operation" { param($b, $r) $r.actions[0].operation=$operation } 'External operation prohibited'
    }
    Test-Case 'User grant does not expand review profile' {
        param($b, $r)
        $b.authority.grants = @(@{grant_id='g1'; approved_action=@{action_id='review-1'; action='send'; destination='fictional recipient'; data_references=@('fictional text'); scope='one reply'}; user_evidence_reference='fictional user request'; state='active'})
        $r.actions[0].operation='send'; $r.actions[0].grant_reference='g1'
    } 'External operation prohibited'
    Test-Case 'Email instructions cannot authorize action' {
        param($b, $r)
        $r.actions[0].operation='send'; $r.actions[0].grant_reference='mailrun-inbox-fixture.json#m2'
    } 'External operation prohibited'
    "$script:passed contract tests passed. No live tools or external services invoked."
}
finally {
    # Remove only the two known synthetic files, then the empty directory; no recursion.
    foreach ($path in @($briefPath, $resultPath)) { if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path } }
    Remove-Item -LiteralPath $testDirectory
}
