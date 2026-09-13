---
name: resume-studio
description: Create requested tailored resumes and evidence-backed document handoffs for Captain's Workflow. A job-fit review alone does not request resume creation.
---

# Resume Studio

Read the repository [authority policy](../../policies/authority.md), [handoff policy](../../policies/handoffs.md), and [career handoff contract](../../policies/career-handoffs.md). Keep this skill with the repository. It is not a global installation.

## Build the requested document

- Resolve the requested role and actual current master resume from the Mission Brief. Read the complete master, not merely a filename, embedded skill profile, old output, or cached summary. If extraction fails, try an available supported reader. If still unavailable, return blocked with the missing source; never claim master grounding.
- Use available document-format skills when actually creating DOCX/PDF files. Keep the editable master untouched. Tailor emphasis, summary, and ordering within roles while preserving all employment entries, dates, employers, and factual qualifications unless the user explicitly requests a different scope.
- Build a claim-to-source map for changed/new statements. Role requirements are not career evidence. User-confirmed additions may supplement the master with provenance; mark unsupported claims unresolved and omit them from the deliverable. Missing evidence is not proof of missing experience. Do not invent metrics, leadership, certifications, clearance, or availability.
- Produce only the requested formats. Use a verified local unsynced directory outside this repository for actual documents, extracted text, and private evidence. Do not silently read from or write to a cloud drive; resolve an approved local source if needed.

## QA and handoff

Check package integrity, extracted text, employment coverage, and visual layout separately. Visual QA requires inspecting rendered pages; successful conversion or text extraction is not visual QA. When a check cannot be performed, report unknown and keep the package unready for downstream submission. Recheck after any document edit.

Return the normal Mission Result plus a career handoff packet using `schemas/career-handoff.schema.json`. Record an absolute artifact path, SHA-256 from the actual final file, career source references, claim provenance, full employment-ID accounting, and evidence for each QA dimension. For multiple requested formats, make one packet per artifact. Application Run selects the packet for the exact file to be transmitted.

Validate the packet with `scripts/Test-CareerHandoff.ps1 -Profile resume-ready -VerifyArtifact`. This checks recorded consistency and local file identity, not whether the resume is truthful or visually polished; Captain must inspect the underlying evidence. A failed check leaves the resume mission partial/blocked as appropriate, not ready.

Deliver the document and disclose any limitations. Resume preparation grants no upload, send, external draft, application, or tracker permission. Route to Application Run only when the user requests that next outcome; preserve any existing applicable authorization without asking again just because the spoke changes.
