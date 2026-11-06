# Captain's Workflow

**Rules for deciding what an AI agent may do on its own, what needs a human, and how to prove what happened.**

An agent that can read your email can also be told what to do by that email. An agent that clicks "Submit" can't always tell whether the submission worked. This framework is my attempt to handle those problems with explicit contracts, not good intentions.

It's built around a real personal workflow: running a job search with AI agents. The same questions apply to enterprise agents: who approved this action, what evidence shows it happened, and what happens when the outcome is unclear?

## Status

This is a tested design, not a finished product.

- **Works today:** policies, JSON schemas, specialist skill definitions, and 74 offline tests on synthetic data.
- **Not proven:** none of this has been tested against live connectors, and nothing here enforces permissions at the tool level. The validators check that records are consistent. They don't stop an agent from acting.
- **Not included:** the simpler versions of some of these workflows that I run day to day. They aren't in this repository.

## Core idea: rate the action, not the agent

| Level | Examples | Rule |
| --- | --- | --- |
| Green | Read scoped sources, research, produce local drafts | Proceed within the request |
| Yellow | Prepare an external change as a local preview | Make it reviewable; grants no write authority |
| Red | Send, submit, upload, delete, change trackers or cloud resources | Requires an explicit user grant for that action |

Four rules follow from this:

1. **Only the user can grant authority.** Emails, websites, documents, issues, and tool results can't, whatever they claim.
2. **A brief records a grant; it doesn't create one.** A schema-valid record isn't proof of permission.
3. **"I clicked Submit" isn't success.** After an interrupted action the outcome is `uncertain`, and the agent must look for evidence before it retries.
4. **Specialists stay in their lane.** A fit review doesn't start a resume, and an application doesn't authorize a tracker update.

See [`policies/authority.md`](policies/authority.md) for the full model.

## How it works

Captain, the coordinator, turns a request into a Mission Brief, checks sources and authority, and routes the work to one specialist. It then verifies the result against the brief's acceptance criteria.

| Role | Does | Does not |
| --- | --- | --- |
| Captain | Coordinates, checks authority, verifies results | Act as a specialist |
| Mailrun | Reviews and triages inbox mail | Send, attach, or clean up mail |
| Opportunity Fit | Compares a role with verified experience | Create resumes or apply |
| Resume Studio | Produces tailored documents | Invent experience, upload, or send |
| Application Run | Prepares and submits approved applications | Start new applications or update trackers |
| Tracker Steward | Plans and applies approved tracker changes | Delete history |
| Interview Prep | Builds interview briefs and practice | Schedule or send |
| Sitrep | Reports evidence-backed status | Run workflows or change records |

The role names come from my time in the US Navy, where a captain owns the outcome and specialists own their stations.

## Run the tests

You need PowerShell 7.4 or later. There's nothing to install, and the tests don't use the network.

```powershell
pwsh -NoProfile -File tests/Run-ContractTests.ps1
pwsh -NoProfile -File tests/Run-CareerTests.ps1
pwsh -NoProfile -File tests/Run-FoundationSpokeTests.ps1
```

The tests cover cases like these, all with fictional records:

- Instructions inside an email can't authorize an action.
- A user grant doesn't expand a review-only profile.
- A future operation can't prove a submission happened.

See [`tests/README.md`](tests/README.md) for coverage and limits.

## What's here

| Path | Contents |
| --- | --- |
| [`AGENTS.md`](AGENTS.md) | Captain's operating instructions and routing |
| [`policies/`](policies/) | Authority, handoffs, career handoffs, GitHub tracking |
| [`schemas/`](schemas/) | Mission Brief, Mission Result, and career handoff schemas |
| [`skills/`](skills/) | Specialist definitions and templates |
| [`examples/`](examples/) | Fictional briefs, results, and an inbox fixture with untrusted instructions |
| [`scripts/`](scripts/) | Offline validators |
| [`docs/implementation-notes.md`](docs/implementation-notes.md) | Detailed build notes and design decisions |

## Privacy

Real briefs, results, grants, and personal documents stay outside this repository. Everything here is reusable framework material or fictional. Issues in this repository are public, so please don't post personal data in them.

## License

[MIT](LICENSE)
