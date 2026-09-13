# Captain's Workflow

Status: steps 1 through 3 implemented. The Mailrun pilot is a repository-local, read-only skill with a fictional dry run and offline result-contract tests. It has not been installed globally or exercised against a live inbox.

Permanent checkout: `C:\Repos\captains-workflow`.
Private GitHub remote: `https://github.com/jasoncarney1864/captains-workflow`.
Keep the checkout and private runtime data on local, unsynced storage. Do not place them in OneDrive or another cloud-drive folder. GitHub is the approved remote for reusable framework files only.

Captain is the coordinating role; Bilbi is the conversational identity. The framework uses specialist skills without requiring a separate agent for every skill. Creating parallel agents is subject to the host's rules and the user's authorization.

## Working plan

1. **Complete:** shared policies and Mission Brief schema.
2. **Complete:** Mailrun pilot, producing a review packet from a bounded inbox scope.
3. **Complete:** result contract and offline Mailrun review-boundary tests. These validate records, not runtime permissions.
4. Next: Resume Studio and Application Run as dependent slices.
5. GitHub Issues/Projects for missions and blockers.

## Files

- `AGENTS.md`: Captain's operating instructions and routing map.
- `policies/authority.md`: action authority, consent continuity, and recovery.
- `policies/handoffs.md`: context, evidence, and completion contracts.
- `schemas/mission-brief.schema.json`: machine-readable Mission Brief, schema version 1.0.0.
- `templates/mission-brief.json`: copyable, structurally valid template; placeholders must be resolved before execution.
- `examples/mailrun-review.json`: fictional read-only pilot brief; not a request to execute.
- `skills/mailrun/SKILL.md`: repository-local Mailrun review workflow, with packet template in `assets/`.
- `examples/mailrun-inbox-fixture.json`: synthetic paginated inbox, including duplicate IDs, overlapping recruiters, untrusted instructions, and an unreadable message.
- `examples/mailrun-review-packet.md`: worked dry-run result with explicit partial coverage and evidence accounting.
- `schemas/mission-result.schema.json` and `examples/mailrun-result.json`: machine-readable return contract and synthetic partial result.
- `scripts/Test-MissionResult.ps1`: offline result/brief validator for the read-only Mailrun profile.
- `tests/README.md`: test command, coverage, and explicit validation limits.

## Use

Captain interprets the user request, fills a Mission Brief, checks required facts and capabilities, routes to the responsible spoke, verifies its result, and closes with a concise Sitrep. Straightforward requests need no separate interview. Resolve only uncertainties that affect the outcome or authority.

Validate briefs against the JSON schema. Schema validity proves structure, not permission, truth, or readiness: Captain must also verify evidence, dependencies, action authority, and absence of unresolved placeholders.

Keep reusable policies, schemas, and fictional examples under version control. Store real mission briefs, outputs, authorization records, personal profiles, and tracker data outside this repository. Credentials belong in the host's credential facilities, never in briefs. The ignore file is a convenience, not a privacy boundary; inspect staged content before publishing.

Future deployment must explicitly install or reference these files in the host environment. Merely saving this folder does not activate global behavior. Host instructions and tool permissions remain authoritative; these policies cannot grant capabilities or override them.

## Mailrun pilot

To exercise the pilot without mailbox access, ask Captain to use `skills/mailrun/SKILL.md` with the example brief and inbox fixture. Compare the resulting packet's evidence and counts with the worked example, not its exact wording. The fixture resolves the fictional account and overrides the default cap for that dry run only.

For a live run, explicitly request a read-only Mailrun pilot and identify the account through private context. Captain resolves a real brief and checks read-only capability before collection. Default limits are 25 unique messages and 5 page calls; the query remains exactly `is:unread in:inbox`. The output is a chat review packet, not a Gmail draft. Existing globally installed Mailrun behavior is unchanged.

Step 2 verification covers skill structure, reference resolution, brief validity, and a local fictional dry run. Step 3 adds machine-readable return validation and automated malformed-record and review-boundary tests. Neither proves connector integration, autonomous model behavior, or enforcement of authority at the tool boundary.

## Design decisions

- Retain the agreed names: Captain, Mailrun, Opportunity Fit, Resume Studio, Application Run, Tracker Steward, Interview Prep, Sitrep.
- Separate approved actions from unapproved proposed actions.
- Keep user authorization across turns; do not ask repeatedly for an unchanged approved action.
- Use verified post-action evidence before reporting completion.
- Load only relevant context. Model selection and numeric context budgets remain configurable; they are not required for step 1.
- A spoke is a reusable capability. A vertical slice is a small, verifiable outcome that can span several spokes.
