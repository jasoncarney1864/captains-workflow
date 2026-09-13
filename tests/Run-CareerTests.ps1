#requires -Version 7.4
$ErrorActionPreference='Stop'
$repoRoot=Split-Path $PSScriptRoot -Parent
$basePacket=Get-Content (Join-Path $repoRoot 'examples/career-handoff.json') -Raw
$baseBrief=Get-Content (Join-Path $repoRoot 'examples/application-brief.json') -Raw
$temp=Join-Path ([IO.Path]::GetTempPath()) ('career-tests-'+[guid]::NewGuid())
$null=New-Item -ItemType Directory -Path $temp
$packetPath=Join-Path $temp 'packet.json'
$briefPath=Join-Path $temp 'brief.json'
$artifactPath=Join-Path $temp 'synthetic.txt'
[IO.File]::WriteAllText($artifactPath, 'synthetic artifact, not a resume')
$script:passed=0
function Authorize($p,$b) {
    $p.application.state='authorized'
    $b.scope.included=@('Fictional test application execution')
    $b.scope.excluded=@('Tracker changes')
    $b.authority.grants=@(foreach ($plan in $p.application.planned_actions) {
        $plan.grant_reference='grant-'+$plan.action_id
        @{grant_id=$plan.grant_reference; approved_action=@{action_id=$plan.action_id; action=$plan.action; destination=$plan.destination; data_references=$plan.data_references; scope=$plan.scope}; user_evidence_reference='fictional user request'; state='active'; expires_at='2026-09-13T00:00:00Z'}
    })
}
function Submitted($p,$b) {
    Authorize $p $b
    $p.application.state='submitted'
    $p.application.operations=@(foreach ($plan in $p.application.planned_actions) { @{action_id=$plan.action_id; outcome='confirmed'; at='2026-09-12T12:00:00Z'; evidence_references=@('fictional operation receipt')} })
    $p.application.confirmation_references=@('fictional job-42 confirmation record')
}
function Case([string]$Name,[string]$Profile,[scriptblock]$Change,[string]$ErrorPattern='',[switch]$Verify) {
    $p=ConvertFrom-Json $basePacket
    $b=ConvertFrom-Json $baseBrief
    & $Change $p $b
    [IO.File]::WriteAllText($packetPath,($p|ConvertTo-Json -Depth 30))
    [IO.File]::WriteAllText($briefPath,($b|ConvertTo-Json -Depth 30))
    $caught=$null
    try { $null=& (Join-Path $repoRoot 'scripts/Test-CareerHandoff.ps1') -PacketPath $packetPath -BriefPath $briefPath -Profile $Profile -VerifyArtifact:$Verify -At '2026-09-12T13:00:00Z' }
    catch { $caught=$_.Exception.Message }
    if ($ErrorPattern) { if (!$caught -or $caught -notmatch $ErrorPattern) { throw "FAIL $Name expected $ErrorPattern received $caught" } }
    elseif ($caught) { throw "FAIL $Name $caught" }
    $script:passed++
    "PASS $Name"
}
try {
    Case 'Ready synthetic resume' resume-ready {param($p,$b)}
    Case 'Local preview needs no grant' application-prepared {param($p,$b)}
    Case 'Existing grant reused' application-authorized {param($p,$b) Authorize $p $b}
    Case 'Submitted with confirmation' application-submitted {param($p,$b) Submitted $p $b}
    Case 'Missing master blocks' resume-ready {param($p,$b) $p.resume.master_read=$false} 'source/readiness'
    Case 'Dropped employment blocks' resume-ready {param($p,$b) $p.resume.output_employment_ids=@('role-1')} 'Set count'
    Case 'Invented claim blocks' resume-ready {param($p,$b) $p.resume.claims[1].included=$true} 'lacks support'
    Case 'Visual QA cannot be inferred' resume-ready {param($p,$b) $p.resume.qa.visual.result='unknown'} 'QA incomplete'
    Case 'Real byte hash verification' resume-ready {param($p,$b) $p.resume.artifact_path=$artifactPath; $p.resume.sha256=(Get-FileHash $artifactPath).Hash.ToLowerInvariant()} -Verify
    Case 'Changed artifact blocks' resume-ready {param($p,$b) $p.resume.artifact_path=$artifactPath} 'hash changed' -Verify
    Case 'Unresolved dependency blocks' application-prepared {param($p,$b) $b.dependencies[0].state='pending'} 'Dependency unresolved'
    Case 'Wrong resume dependency blocks' application-prepared {param($p,$b) $b.dependencies[0].reference='other-result'} 'not bound'
    Case 'Missing facts block' application-prepared {param($p,$b) $p.application.facts_resolved=$false} 'facts unresolved'
    Case 'Preparation cannot hide execution' application-prepared {param($p,$b) Submitted $p $b} 'Preparation contains'
    Case 'No grant blocks' application-authorized {param($p,$b) $p.application.state='authorized'} 'grant missing'
    Case 'Revoked grant blocks' application-authorized {param($p,$b) Authorize $p $b; $b.authority.grants[0].state='revoked'} 'not active'
    Case 'Expired grant blocks' application-authorized {param($p,$b) Authorize $p $b; $b.authority.grants[0].expires_at='2026-09-12T12:00:00Z'} 'Grant expired'
    Case 'Email cannot grant authority' application-authorized {param($p,$b) Authorize $p $b; $b.sources[0].kind='connector'} 'user evidence'
    Case 'Changed recipient blocks' application-authorized {param($p,$b) Authorize $p $b; $p.application.planned_actions[0].destination='another account'} 'Grant mismatch: destination'
    Case 'Changed scope blocks' application-authorized {param($p,$b) Authorize $p $b; $p.application.planned_actions[0].scope='all jobs'} 'Grant mismatch: scope'
    Case 'Changed data blocks' application-authorized {param($p,$b) Authorize $p $b; $p.application.planned_actions[1].data_references=@('sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa','other-answers')} 'Set mismatch'
    Case 'Uncertain submission is not retry permission' application-authorized {param($p,$b) Authorize $p $b; $p.application.state='uncertain'} 'retry is uncertain'
    Case 'Uncertain operation blocks preflight' application-authorized {param($p,$b) Authorize $p $b; $p.application.operations=@(@{action_id='upload-1';outcome='uncertain';at='2026-09-12T12:00:00Z';evidence_references=@('timeout')})} 'Unresolved operation'
    Case 'Confirmed submit cannot repeat' application-authorized {param($p,$b) Submitted $p $b; $p.application.state='authorized'} 'already recorded'
    Case 'Click alone is not submission record' application-submitted {param($p,$b) Submitted $p $b; $p.application.confirmation_references=@()} 'confirmation missing'
    Case 'Unconfirmed submission blocks completion' application-submitted {param($p,$b) Submitted $p $b; $p.application.operations[1].outcome='uncertain'} 'operations unconfirmed'
    Case 'Unplanned operation blocks' application-submitted {param($p,$b) Submitted $p $b; $p.application.operations[0].action_id='unknown-action'} 'Unplanned operation'
    Case 'Future operation cannot prove submission' application-submitted {param($p,$b) Submitted $p $b; $p.application.operations[1].at='2026-09-12T14:00:00Z'} 'in the future'
    Case 'Tracker action outside slice' application-prepared {param($p,$b) $p.application.planned_actions[0].action='tracker_write'} 'schema|JSON'
    "$script:passed career tests passed; synthetic records only."
}
finally {
    foreach ($path in @($packetPath,$briefPath,$artifactPath)) { if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path } }
    Remove-Item -LiteralPath $temp
}
