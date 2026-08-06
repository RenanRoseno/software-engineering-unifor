<!--
Sync Impact Report
Version change: 1.0.0 -> 1.1.0
Modified principles: I. Quality and Correctness -> I. Requirements are explicit and testable; II. Evidence-Driven Delivery -> II. Quality is built in; III. Security, Reliability, and Operations -> III. Security and reliability are non-negotiable; IV. Simplicity and Maintainability -> IV. Simplicity over cleverness; V. Collaborative Ownership -> V. Collaborative ownership
Added sections: none
Removed sections: none
Deferred items: TODO(RATIFICATION_DATE): record the formal ratification date once the project is approved
-->

# Software Engineering Constitution

## Core Principles

### I. Requirements are explicit and testable
Every task must start from a defined requirement, user need, or defect. Acceptance criteria must be written before implementation begins, and any requirement that cannot be tested or observed is not complete. This reduces ambiguity, rework, and scope drift.

### II. Quality is built in
All production code must be correct, readable, maintainable, and reviewable. New behavior must include automated tests or explicit validation evidence. Defect prevention takes precedence over speed, and unverified changes are not considered complete.

### III. Security and reliability are non-negotiable
Inputs must be validated, secrets must never be committed to source control, and failure modes must be explicit and recoverable. Changes must preserve privacy, minimize operational risk, and fail safely when dependencies or infrastructure are unavailable.

### IV. Simplicity over cleverness
The simplest design that satisfies the requirement and remains understandable to the next engineer is preferred. Speculative abstractions, hidden coupling, duplicated logic, and unnecessary dependencies are prohibited without clear justification.

### V. Collaborative ownership
Engineering is a shared responsibility. Changes must be reviewed before merge, decisions must be explained in context, and contributors must leave the repository in a state that others can safely maintain and extend. Feedback is expected and must be addressed or explicitly resolved.

## Engineering Standards

- All work occurs in version control with traceable commits and clear branch intent.
- Define acceptance criteria before implementation and update documentation when behavior or interfaces change.
- Prefer small, reviewable changes; do not mix unrelated refactors with feature work.
- Keep dependencies minimal, documented, and compatible with the supported runtime.
- Store configuration, secrets, and environment assumptions outside source control.
- Preserve backward compatibility unless a breaking change is explicitly approved.

## Delivery Workflow

- Define the problem, scope, and success criteria before coding.
- Validate with the smallest relevant checks: unit, integration, lint, build, or explicit manual review.
- Require at least one knowledgeable reviewer before merge; unresolved review concerns block completion.
- Record risk, rollback, and operational impact for changes that affect shared systems or production.
- Do not merge a change with failing required checks, unresolved review comments, or undocumented exceptions.

## Governance

This constitution governs engineering decisions for this repository. When principles conflict with convenience or local preference, the constitution takes precedence. Any amendment must be proposed, discussed, reviewed, and recorded in this document before it is enforced.

Amendments follow semantic versioning:
- MAJOR: removal or redefinition of a principle or mandatory rule with backward-incompatible effect.
- MINOR: addition of a principle or material expansion of guidance.
- PATCH: clarification, wording correction, or non-semantic refinement.

All changes require:
- a clear rationale and affected scope,
- review by at least one maintainer or designated reviewer,
- update of the version metadata and amendment date,
- documentation of migration, rollback, or operational follow-up when required.

Compliance review is expected for every merge and governance change. Reviewers must confirm that the work aligns with these standards, that required checks are satisfied, and that any exceptions are explicit, temporary, and approved.

**Version**: 1.1.0 | **Ratified**: TODO(RATIFICATION_DATE): record the formal ratification date once the project is approved | **Last Amended**: 2026-08-01
