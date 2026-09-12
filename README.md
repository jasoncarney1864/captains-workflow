# Captain's Workflow

Status: step 1 implemented. This repository contains the framework; global skill installation and the Mailrun pilot are subsequent work.

Permanent checkout: `C:\Repos\captains-workflow`.
Private GitHub remote: `https://github.com/jasoncarney1864/captains-workflow`.
Keep the checkout and private runtime data on local, unsynced storage. Do not place them in OneDrive or another cloud-drive folder. GitHub is the approved remote for reusable framework files only.

Captain is the coordinating role; Bilbi is the conversational identity. The framework uses specialist skills without requiring a separate agent for every skill. Creating parallel agents is subject to the host's rules and the user's authorization.

## Working plan

1. **Complete:** shared policies and Mission Brief schema.
2. Next: Mailrun pilot, producing a review packet from a bounded inbox scope.
3. Contract tests and approval-boundary checks.
4. Resume Studio and Application Run as dependent slices.
5. GitHub Issues/Projects for missions and blockers.

## Files

- `AGENTS.md`: Captain's operating instructions and routing map.
- `policies/authority.md`: action authority, consent continuity, and recovery.
- `policies/handoffs.md`: context, evidence, and completion contracts.
- `schemas/mission-brief.schema.json`: machine-readable Mission Brief, schema version 1.0.0.
- `templates/mission-brief.json`: copyable, structurally valid template; placeholders must be resolved before execution.
- `examples/mailrun-review.json`: fictional read-only pilot brief; not a request to execute.

## Use

Captain interprets the user request, fills a Mission Brief, checks required facts and capabilities, routes to the responsible spoke, verifies its result, and closes with a concise Sitrep. Straightforward requests need no separate interview. Resolve only uncertainties that affect the outcome or authority.

Validate briefs against the JSON schema. Schema validity proves structure, not permission, truth, or readiness: Captain must also verify evidence, dependencies, action authority, and absence of unresolved placeholders.

Keep reusable policies, schemas, and fictional examples under version control. Store real mission briefs, outputs, authorization records, personal profiles, and tracker data outside this repository. Credentials belong in the host's credential facilities, never in briefs. The ignore file is a convenience, not a privacy boundary; inspect staged content before publishing.

Future deployment must explicitly install or reference these files in the host environment. Merely saving this folder does not activate global behavior. Host instructions and tool permissions remain authoritative; these policies cannot grant capabilities or override them.

## Design decisions

- Retain the agreed names: Captain, Mailrun, Opportunity Fit, Resume Studio, Application Run, Tracker Steward, Interview Prep, Sitrep.
- Separate approved actions from unapproved proposed actions.
- Keep user authorization across turns; do not ask repeatedly for an unchanged approved action.
- Use verified post-action evidence before reporting completion.
- Load only relevant context. Model selection and numeric context budgets remain configurable; they are not required for step 1.
- A spoke is a reusable capability. A vertical slice is a small, verifiable outcome that can span several spokes.
