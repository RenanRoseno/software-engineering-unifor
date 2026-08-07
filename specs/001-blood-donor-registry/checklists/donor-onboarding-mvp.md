# Donor Onboarding MVP Checklist: Blood Donor Registry

**Purpose**: Track implementation readiness for the donor-onboarding MVP, focusing on build setup, donor-service implementation, data model, security, testing, and deployment.
**Created**: 2026-08-06
**Feature**: [spec.md](../spec.md)

## Build & Foundation

- [x] CHK001 Confirm the multi-module Java 21 / Spring Boot build, CI quality gates, and local Docker stack are configured for donor-service, audit-service, identity-gateway, and shared libraries.
- [ ] CHK002 Define the Flyway baseline and schema for donor, audit, user-account, and master-data tables in PostgreSQL for the MVP scope.
- [ ] CHK003 Keep the MVP scoped to donor onboarding only and ensure patient intake and blood-test request workflows remain deferred from this release.

## Service Implementation

- [ ] CHK004 Implement the donor domain model, repository, and DTOs for the lifecycle draft -> pending-review -> active -> inactive/deactivated.
- [ ] CHK005 Implement donor create, read, update, and deactivation APIs with mandatory-field validation, duplicate detection, and clear error responses.
- [ ] CHK006 Implement donor eligibility state transitions, consent checks, and urgent-override approval rules that require physician approval and complete override metadata.
- [ ] CHK007 Wire donor events to the audit flow so create, update, deactivation, and access-denial actions emit immutable audit entries with actor, timestamp, reason, and outcome.

## Data Model & Retention

- [ ] CHK008 Ensure the donor data model captures identity, consent, eligibility, blood type/Rh, status, versioning, and created/updated audit metadata.
- [ ] CHK009 Implement retention and anonymization support so personal data is retained for 5 years and then anonymized according to policy.
- [ ] CHK010 Ensure records with historical dependencies are deactivated or archived rather than hard-deleted and preserve traceability.

## Security & Operations

- [ ] CHK011 Enforce RBAC and least-privilege access for staff, physician, administrator, and auditor/privacy-reviewer roles.
- [ ] CHK012 Implement secure authentication/session handling, authorization checks, denied-access logging, and secret-safe configuration practices.
- [ ] CHK013 Add health checks, structured logging, error envelopes, and observability hooks for donor-service and audit-service.

## Testing & Validation

- [ ] CHK014 Add unit and integration tests for donor validation, duplicate detection, invalid transitions, override approval, and retention/anonymization behavior.
- [ ] CHK015 Add contract tests for donor CRUD endpoints and audit/event payloads and verify they align with the API contract.
- [ ] CHK016 Run end-to-end validation for donor onboarding, lifecycle transitions, physician override approval, and admin/audit reporting flows.

## Deployment Readiness

- [ ] CHK017 Provision ECS/Fargate infrastructure for ALB, RDS PostgreSQL, ElastiCache Redis, Secrets Manager, IAM, and CloudWatch for the target AWS deployment.
- [ ] CHK018 Verify container readiness/liveness probes, rolling deployment behavior, and resilience settings (retry, circuit breaker, DLQ) for the MVP release.
- [ ] CHK019 Confirm deployment artifacts and runbooks support the target environment and that critical configuration is externalized from source control.
