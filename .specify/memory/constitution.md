<!--
Sync Impact Report
Version change: 1.0.0 -> 1.1.0
Modified sections: Development Workflow & Quality Gates (added Commit Discipline rule)
Added sections: none
Removed sections: none
Templates requiring updates:
	- .specify/templates/plan-template.md ✅ no change required (implicit; commit discipline enforced at task granularity)
	- .specify/templates/spec-template.md ✅ no change needed
	- .specify/templates/tasks-template.md ✅ already contains commit guidance (now formally governed)
	- .specify/templates/checklist-template.md ✅ no change needed
	- .specify/templates/agent-file-template.md ✅ no change needed
Follow-up TODOs: none
-->

# BandLab Upptime Constitution

## Core Principles

### I. Public Transparency
The status of monitored services MUST be publicly accessible, accurate, human-readable, and
machine-consumable. Every outage MUST appear on the status page within 5 minutes of detection.
Historical uptime percentages (daily, 7‑day, 30‑day, rolling 90‑day) MUST be retained and verifiable
from committed data. Manual edits to historical incident data are PROHIBITED—corrections require
append-only clarification notes.

Rationale: Trust is earned through fast, frank disclosure. Immutable, reproducible data prevents
quiet degradation and selective reporting.

### II. Everything-as-Code Automation
All monitoring checks, SLAs/SLO thresholds, escalation mappings, notification channels, and
credentials references MUST be declared as code in the repository (never only in a UI). Any runtime
secret values MUST be injected via environment or secret manager—never stored in plaintext.
Manual configuration drift is NOT permitted; detection of drift triggers a corrective PR.

Rationale: Declarative configuration enables reproducibility, review, rollback, and peer audit.

### III. Reliability & Fast Incident Response
Checks MUST run at least every 5 minutes (critical endpoints every 1 minute if cost allows). An
incident MUST be opened if 2 consecutive failures (or 1 for critical) occur. Mean Time To Detect
(MTTD) target: <3 minutes critical, <6 minutes standard. Mean Time To Acknowledge (MTTA) target: <10
minutes. Post‑incident review REQUIRED for any outage >10 minutes or repeated (≥3 similar alerts in
7 days). No silent suppression: temporary mute windows MUST be time-bound and codified.

Rationale: Rapid, consistent detection shortens user impact and improves systemic resilience.

### IV. Security & Least Privilege
Monitoring tooling MUST use least-privilege tokens (read-only where possible). Secrets MUST NOT be
committed. Dependency updates affecting monitoring agents MUST undergo security review if they
introduce new network paths, privilege elevation, or cryptographic changes. Third-party endpoints
monitored MUST be categorized (internal, partner, public) with access rules.

Rationale: Observability should not expand attack surface; guardrails limit blast radius.

### V. Testability & Observability
All custom check logic MUST include a deterministic local test (e.g., mock endpoint or contract test)
verifying success and failure paths. Synthetic incident generation MUST be possible (flag or script)
to validate pipeline from detection → alert → status page publish. Logs MUST be structured (JSON or
key=value) and include correlation identifiers. Timeouts, retries, and error classification MUST be
explicitly configured—not left to implicit defaults.

Rationale: If it cannot be tested or observed, it will fail silently.

## Operational Standards

1. Monitoring Cadence: Default 5m; critical endpoints 1m; non-critical, low‑value endpoints may be
	15m but MUST be labeled.
2. SLOs: Uptime SLO default 99.90%; critical endpoints 99.95%; explicit SLO file stored under
	`slo/` or equivalent directory.
3. Incident Lifecycle: Detect → Acknowledge → Communicate → Mitigate → Resolve → Review. Each stage
	MUST have a timestamp logged.
4. Status Page Updates: Initial notice ≤5 minutes (critical) / ≤10 (standard) after detection;
	updates every ≥30 minutes during active incidents.
5. Data Integrity: Raw check results retained for ≥30 days; aggregated stats retained ≥365 days.
6. Secrets: Access via environment/secret store only; rotation documented; rotation review quarterly.
7. Performance: Check execution (excluding network latency) SHOULD complete <1s average; any check
	exceeding 3s median MUST justify complexity.
8. Tooling: Prefer upstream Upptime conventions; deviations require rationale in PR description.

## Development Workflow & Quality Gates

1. CI MUST validate: lint, formatting, schema of checks, secret scanning, dry‑run of status build.
2. Every PR touching monitoring config MUST include: (a) rationale, (b) risk assessment, (c) rollback
	plan.
3. At least one reviewer other than author REQUIRED for all config or logic changes (Principle II).
4. New or modified checks MUST include a local reproducibility note (how to run/fail intentionally).
5. Reliability Gate (Principle III): Adding a critical check requires confirming no existing check
	covers same endpoint—deduplicate or merge.
6. Security Gate (Principle IV): Any new token scope listed; diff must show scope minimization.
7. Observability Gate (Principle V): Log fields (timestamp, endpoint, latency_ms, status, attempt,
	error_class) MUST be present.
8. Rollback: Each change MUST identify a single command or revert commit path to restore prior
	state.
9. Documentation: README (or status docs) MUST reflect any new category of monitored service before
	merge.
10. Prohibited: Merging failing CI (unless a documented emergency hotfix)—hotfix MUST open follow-up
	 remediation issue within 24h.
11. Commit Discipline: After completing each enumerated task (or a minimal cohesive sub-task if
	 decomposition is finer), a commit MUST be created. Commit message MUST start with the task ID
	 (e.g., "T012: implement latency parser") and describe the atomic change. Multi-task commits are
	 PROHIBITED unless the tasks are inseparable for build integrity; such commits MUST list all task
	 IDs and include justification.

## Governance

Supremacy: This constitution governs monitoring and operational quality for the BandLab Upptime
repository. Where other documents conflict, this takes precedence.

Amendments: Proposed via PR labeled `governance`. PR MUST include: (a) change summary, (b) impact
assessment, (c) semantic version bump justification, (d) migration/transition steps if applicable.
Approval requires ≥2 reviewers OR (for urgent security) 1 reviewer + post‑merge retrospective within
48h.

Versioning Policy: Semantic style X.Y.Z
 - MAJOR: Removal or redefinition of a principle; governance process changes removing safeguards.
 - MINOR: Addition of a new principle or materially expanding operational standards/gates.
 - PATCH: Non-substantive clarifications, wording, formatting, typo fixes.

Compliance Reviews: Quarterly scheduled audit verifying principle adherence (sampling recent 10 PRs
touching monitoring logic). Findings tracked as issues labeled `governance-audit` and MUST be
resolved or triaged within 14 days.

Enforcement: Reviewers MUST block merges that violate non‑negotiable language (MUST/PROHIBITED). Any
post‑merge violation triggers an immediate follow-up PR or revert within 24h.

Exceptions: Temporary exceptions require explicit `EXCEPTION:` note in PR body, max duration 30 days,
and an issue tracking removal. Exceptions auto-expire; re‑authorization requires new review.

Ratification: Initial adoption on 2025-10-11 with version 1.0.0.

**Version**: 1.1.0 | **Ratified**: 2025-10-11 | **Last Amended**: 2025-10-11