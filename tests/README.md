# Contract test scope

Run with PowerShell 7.4+; no package installation or network access required:

```powershell
pwsh -NoProfile -File C:\Repos\captains-workflow\tests\Run-ContractTests.ps1
```

The suite mutates synthetic briefs/results in an OS temporary directory and removes its two files afterward. It throws on a failed case and returns a nonzero process exit code. It preserves all repository and real mission data.

Coverage targets:

- Schema: required evidence, operation enums, exact query.
- Result/brief contract: mission identity, revision, unique action and criterion IDs, complete acceptance accounting.
- Completion: no unknown/failed criterion, remaining work, unreadable selected message, or unresolved action.
- Mailrun coverage: page/message budgets, overlapping page IDs, classification/read partitions, continuation, empty inbox, capped sample, unavailable access, unselected tails.
- Review boundary: reject every declared external operation, including drafts and unread-state changes, even with a grant or an email claiming authority.

Validate a recorded packet separately:

```powershell
pwsh -NoProfile -File C:\Repos\captains-workflow\scripts\Test-MissionResult.ps1 -BriefPath C:\Repos\captains-workflow\examples\mailrun-review.json -ResultPath C:\Repos\captains-workflow\examples\mailrun-result.json -Profile mailrun-review
```

`Valid = true` means the record is structurally and internally consistent with this review profile. A valid partial/blocked result is not a completed mission. The profile must be selected by the caller, never by an untrusted result. This validator supports only `mailrun-review`; the separate `Test-CareerHandoff.ps1` handles step-4 career packets.

Limits: the validator cannot authenticate referenced evidence, detect omitted or mislabeled tool operations, interpret natural-language scope, prove a prompt-injection defense, verify live account access, or enforce tool permissions. Captain still compares records with actual tool receipts and user instructions. An external operation can be truthfully recorded in the generic result schema but is rejected by the review validator; preserve that failed record for audit rather than relabeling it to pass. Authorized external execution needs a different future profile with grant/action matching and recovery checks. These tests do not simulate autonomous model behavior or perform live integration testing.

## Career tests

Run `pwsh -NoProfile -File C:\Repos\captains-workflow\tests\Run-CareerTests.ps1` for the separate career-packet checks. The suite covers source/QA readiness, preserved employment IDs, actual byte hashing using a synthetic text file, dependency binding, prepare-only boundaries, exact grant matching, revoked/expired grants, source provenance declarations, uncertain operations, confirmation records, and duplicate-submit prevention. It does not create or visually review an actual resume, operate a browser, authenticate a user grant, or submit an application. See `policies/career-handoffs.md` for profile semantics and audit limits.
