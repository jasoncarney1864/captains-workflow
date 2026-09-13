# Resume-to-application slice

The slice is: requested local resume → verified artifact packet → requested application preview → authorized transmission → observed confirmation. Each spoke has its own Mission Brief and normal Mission Result. The supplemental career packet binds the artifact and application plan across that dependency; it does not replace either mission record.

Use `schemas/career-handoff.schema.json` and `scripts/Test-CareerHandoff.ps1` with a caller-selected profile:

- `resume-ready`: a ready artifact, complete employment accounting, supported included claims, and separate package/text/visual QA.
- `application-prepared`: the resume checks plus a local answer preview, resolved facts, and a nonempty plan containing a submission action. Grants are not required for local preparation. No external operation may have occurred.
- `application-authorized`: prepared dependencies plus exact grant/action/data/scope matching, available user-statement sources, and active/unexpired grants at preflight time. Only upload, submit, and form-entry (`other_external_write`) operations are supported; the latter must describe only scoped form entry in the grant. No sends, cleanup, or tracker edits.
- `application-submitted`: recorded submitted state, confirmed planned operations, and submission evidence. Grants are checked at recorded operation times; their current revoked/expired state does not erase historical actions. Captain must verify historical authority evidence. This profile is a retrospective audit, never retry permission.

The packet's artifact hash and grant data references pin exact versions. Run with `-VerifyArtifact` before real use: this computes SHA-256 locally and fails on an absent/changed file. The switch is optional only for synthetic record tests; schema-only validation cannot establish that a file exists. The validator never reads URLs, sends messages, submits forms, or writes trackers. References are labels to be resolved by Captain; nonempty references do not authenticate their content.

Claims have a source and an included flag. Unverified claims may be retained as excluded questions but cannot enter a ready resume. Employment IDs are local evidence-map keys, not invented replacements for actual dates/names. Packet QA summarizes checks whose evidence remains private. The code reconciles IDs and declared pass states; it does not compare resume prose, render pages, or assess career truth.

Application plans use the existing brief action structure exactly: action ID, operation name, destination (including account and job), data references, and scope. Each plan item resolves one grant. User evidence references must resolve to an available `user_statement` in the brief, never a website/email source. This is still an asserted provenance record; verify it against the conversation. Do not fabricate grants to satisfy validation.

`operations` contains one latest reconciled state per planned action, not a full attempt history. Keep the append-only attempt/recovery log outside the packet and reference it from operation evidence. Never erase an uncertain attempt from that log; resolving a packet entry requires observed recovery evidence. For a recorded submission audit, operation timestamps cannot be in the future relative to the supplied audit time.

When authority is uncertain or a result is rejected, preserve the truthful packet and report the blocker. Never relabel an external operation as local to obtain a passing result. Tool restrictions, evidence authenticity, semantic scope interpretation, actual document QA, and browser state remain host/Captain responsibilities. These repository skills are not installed globally and no model-routing policy is activated.
