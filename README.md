# Captain's Workflow

Status: steps 1 through 4 and the GitHub Issues/Project tracking layer are implemented. Opportunity Fit, Tracker Steward, Interview Prep, and Sitrep have testable, read-only foundations. Mailrun, Opportunity Fit, Tracker Steward, Interview Prep, Sitrep, Resume Studio, and Application Run are not installed globally; live connector, document-rendering, and submission integration have not been tested.

Permanent checkout: `C:\Repos\captains-workflow`.
Private GitHub remote: `https://github.com/jasoncarney1864/captains-workflow`.
Keep the checkout and private runtime data on local, unsynced storage. Do not place them in OneDrive or another cloud-drive folder. GitHub is the approved remote for reusable framework files only.

Captain is the coordinating role; Bilbi is the conversational identity. The framework uses specialist skills without requiring a separate agent for every skill. Creating parallel agents is subject to the host's rules and the user's authorization.

## Working plan

1. **Complete:** shared policies and Mission Brief schema.
2. **Complete:** Mailrun pilot, producing a review packet from a bounded inbox scope.
3. **Complete:** result contract and offline Mailrun review-boundary tests. These validate records, not runtime permissions.
4. **Complete:** Resume Studio and Application Run skills, artifact handoff, and offline readiness/authorization checks.
5. **Complete:** private GitHub Issues/Project tracking for missions and blockers.

## Files

- `AGENTS.md`: Captain's operating instructions and routing map.
- `policies/authority.md`: action authority, consent continuity, and recovery.
- `policies/handoffs.md`: context, evidence, and completion contracts.
- `schemas/mission-brief.schema.json`: machine-readable Mission Brief, schema version 1.0.0.
- `templates/mission-brief.json`: copyable, structurally valid template; placeholders must be resolved before execution.
- `examples/mailrun-review.json`: fictional read-only pilot brief; not a request to execute.
- `skills/mailrun/SKILL.md`: repository-local Mailrun review workflow, with packet template in `assets/`.
- `skills/opportunity-fit/SKILL.md`: repository-local role-research and candid-fit workflow, with a review template in `assets/`.
- `skills/tracker-steward/SKILL.md`: repository-local tracker-inspection and change-plan workflow, with no write authority.
- `skills/interview-prep/SKILL.md`: repository-local, evidence-grounded interview-preparation workflow.
- `skills/sitrep/SKILL.md`: repository-local evidence-backed status-reporting workflow.
- `examples/mailrun-inbox-fixture.json`: synthetic paginated inbox, including duplicate IDs, overlapping recruiters, untrusted instructions, and an unreadable message.
- `examples/mailrun-review-packet.md`: worked dry-run result with explicit partial coverage and evidence accounting.
- `schemas/mission-result.schema.json` and `examples/mailrun-result.json`: machine-readable return contract and synthetic partial result.
- `scripts/Test-MissionResult.ps1`: offline result/brief validator for the read-only Mailrun profile.
- `tests/README.md`: test command, coverage, and explicit validation limits.
- `tests/Run-FoundationSpokeTests.ps1`: synthetic read-only contract exercises for Tracker Steward, Interview Prep, and Sitrep.
- `policies/github-tracking.md`: GitHub Issue lifecycle, privacy, authority, and Project-view rules.
- `.github/ISSUE_TEMPLATE/`: private-safe Mission and Blocker issue forms.

## Use

Captain interprets the user request, fills a Mission Brief, checks required facts and capabilities, routes to the responsible spoke, verifies its result, and closes with a concise Sitrep. Straightforward requests need no separate interview. Resolve only uncertainties that affect the outcome or authority.

Validate briefs against the JSON schema. Schema validity proves structure, not permission, truth, or readiness: Captain must also verify evidence, dependencies, action authority, and absence of unresolved placeholders.

Keep reusable policies, schemas, and fictional examples under version control. Store real mission briefs, outputs, authorization records, personal profiles, and tracker data outside this repository. Credentials belong in the host's credential facilities, never in briefs. The ignore file is a convenience, not a privacy boundary; inspect staged content before publishing.

Future deployment must explicitly install or reference these files in the host environment. Merely saving this folder does not activate global behavior. Host instructions and tool permissions remain authoritative; these policies cannot grant capabilities or override them.

## Mailrun pilot

To exercise the pilot without mailbox access, ask Captain to use `skills/mailrun/SKILL.md` with the example brief and inbox fixture. Compare the resulting packet's evidence and counts with the worked example, not its exact wording. The fixture resolves the fictional account and overrides the default cap for that dry run only.

For a live run, explicitly request a read-only Mailrun pilot and identify the account through private context. Captain resolves a real brief and checks read-only capability before collection. Default limits are 25 unique messages and 5 page calls; the query remains exactly `is:unread in:inbox`. The output is a chat review packet, not a Gmail draft. Existing globally installed Mailrun behavior is unchanged.

Step 2 verification covers skill structure, reference resolution, brief validity, and a local fictional dry run. Step 3 adds machine-readable return validation and automated malformed-record and review-boundary tests. Neither proves connector integration, autonomous model behavior, or enforcement of authority at the tool boundary.

## Opportunity Fit

Opportunity Fit is the read-only assessment spoke: it verifies a role source, separates company requirements from candidate evidence, identifies strengths and unverified requirements, and returns a candid `pursue`, `clarify`, `hold`, or `no action` recommendation. Its template is under `skills/opportunity-fit/assets/fit-review.md`.

A fit review does not create a resume, begin an application, send a message, or change a tracker. Those outcomes require separate user requests and route to their respective spokes. The current slice is an instruction-and-template foundation; it has no live job-source or resume integration test.

## Remaining spoke foundations

Opportunity Fit, Tracker Steward, Interview Prep, and Sitrep now have repository-local skills, local templates, and synthetic brief/result exercises. The foundation suite runs those records through the shared Mission Brief and Mission Result schemas and verifies a Green-only boundary: fixture runs may read and prepare local material, but may not write a tracker, schedule or contact anyone, or start underlying workflows.

Run their foundation suite with PowerShell 7.4+:

```powershell
pwsh -NoProfile -File C:\Repos\captains-workflow\tests\Run-FoundationSpokeTests.ps1
```

The suite is not a live integration test and does not prove source availability, tool permissions, or the truth of a real assessment. Deepening each spoke should add the smallest domain-specific contract only when a real workflow shows that the shared contract is insufficient.

## Career slice

Read `policies/career-handoffs.md` for the Resume Studio → Application Run contract. The two new skill entrypoints are under `skills/resume-studio/` and `skills/application-run/`. `schemas/career-handoff.schema.json` defines the supplemental packet; `scripts/Test-CareerHandoff.ps1` checks readiness, artifact identity, exact declared grants, and recorded submission state. The fictional `examples/career-handoff.json` and `examples/application-brief.json` demonstrate local preparation without grants. Their QA and hash values are synthetic, not claims about an actual document.

Run both suites with PowerShell 7.4+:

```powershell
pwsh -NoProfile -File C:\Repos\captains-workflow\tests\Run-ContractTests.ps1
pwsh -NoProfile -File C:\Repos\captains-workflow\tests\Run-CareerTests.ps1
```

No packages, real personal documents, mailbox calls, or application submissions are needed for these tests. Real artifact checks require `-VerifyArtifact`; omitted verification is only appropriate for synthetic record testing. The validators are offline consistency checks, not permission enforcement or proof of historical authority.

## GitHub tracking

GitHub Issues are the private-safe index for framework missions and blockers. The Mission and Blocker forms keep objective, dependencies, ownership, authority boundaries, acceptance criteria, and resolution needs reviewable without copying runtime records into GitHub. Read `policies/github-tracking.md` before creating or closing an Issue. The repository supplies mission, blocker, owner, lifecycle, and priority labels; only actual observed state should change them.

The linked private [Captain's Workflow Project](https://github.com/users/jasoncarney1864/projects/1) is a view over those Issues, not a competing source of truth. Its `Kanban` Board is grouped into `Inbox`, `Ready`, `In progress`, `Waiting`, and `Done`, with `Mission ID` and `Owner` fields on cards. The enabled Project auto-add workflow adds open repository Issues labeled `owner: captain`; the Mission and Blocker forms apply that label, and the existing item-added workflow places new cards in `Inbox`. Set the card's `Owner` field during Captain triage rather than assigning every new mission to a spoke automatically. Keep personal artifacts, messages, grants, and credentials outside GitHub.

## Design decisions

- Retain the agreed names: Captain, Mailrun, Opportunity Fit, Resume Studio, Application Run, Tracker Steward, Interview Prep, Sitrep.
- Separate approved actions from unapproved proposed actions.
- Keep user authorization across turns; do not ask repeatedly for an unchanged approved action.
- Use verified post-action evidence before reporting completion.
- Load only relevant context. Model selection and numeric context budgets remain configurable; they are not required for step 1.
- A spoke is a reusable capability. A vertical slice is a small, verifiable outcome that can span several spokes.
