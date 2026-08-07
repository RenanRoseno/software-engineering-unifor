# Quickstart Validation Guide

## Purpose

This guide provides the steps to validate the donor-onboarding MVP for a hospital collection center. It focuses on operationally relevant donor-registration flows rather than low-level code. Patient intake and blood-test request workflows are deferred to a later phase and are intentionally excluded from this validation guide.

## Prerequisites

- Java 21
- Docker / Docker Compose
- PostgreSQL 15+
- Redis 7+
- RabbitMQ 3.13+
- AWS account or local equivalent for ECS/Fargate deployment preview
- GitHub Actions or deployment automation configured for CI/CD

## Local Development Setup

1. Start infrastructure dependencies:
   - PostgreSQL
   - Redis
   - RabbitMQ
   - Prometheus/Grafana dashboard stack (optional but recommended)
2. Start the Spring Boot microservices:
   - donor-service
   - audit-service
   - identity-gateway
3. Configure environment variables for database URLs, Redis connection, RabbitMQ host, JWT issuer, and AWS secrets.

## Validation Scenarios

### Scenario 1: Donor registration and validation

1. Log in as a collection center staff user.
2. Submit a valid donor profile with required fields.
3. Observe that the system creates a donor record with a unique donor ID.
4. Confirm eligibility validation passes and donor is moved through the approved lifecycle states (draft, pending-review, active, or inactive/deactivated) based on the rule set.
5. Validate that a create event is recorded in the audit log.

Expected result: donor is stored successfully, validation passes, and audit log shows actor and timestamp.

### Scenario 2: Donor lifecycle progression and invalid transition prevention

1. Create a donor record in draft state.
2. Submit it for review so it moves to pending-review.
3. Approve the review so it moves to active.
4. Attempt an invalid state transition, such as moving an inactive donor back to active without a reactivation reason.
5. Verify domain validation rejects the transition and records a failure audit event.

Expected result: donor state changes follow the approved lifecycle, invalid transitions are prevented, and a clear error is returned.

### Scenario 3: Urgent override approval and auditability

1. Create or update a donor record that requires an urgent eligibility override.
2. Submit the override with a reason and request physician approval.
3. Confirm the override is accepted only when reviewed by a licensed medical officer/physician.
4. Verify the audit log captures the override request, reviewer identity, timestamp, and outcome.

Expected result: urgent overrides are permitted only under the approved authority and are fully traceable.

### Scenario 4: Privacy and retention handling

1. Create a donor record with personal data.
2. Confirm the record is accessible only to authorized roles.
3. Trigger or simulate the anonymization workflow after the 5-year retention period.
4. Verify the personal data is anonymized while the donor reference remains available for operational history.

Expected result: donor data is retained according to policy, restricted to authorized roles, and anonymized after the retention period.

### Scenario 5: Reporting and admin access validation

1. Log in as an administrator.
2. Search donor records by blood type, date range, status, or eligibility.
3. Run a report export for donor counts or collection activity.
4. Confirm the exported scope respects least-privilege rules.

Expected result: authorized report is generated, unauthorized data is excluded, and the access event is logged.

## Deployment Validation

1. Build Docker images for the donor-service, audit-service, and identity-gateway.
2. Deploy to AWS ECS/Fargate using infrastructure-as-code.
3. Validate load balancer health checks and service readiness endpoints.
4. Check autoscaling and warm-up behavior under simulated load.
5. Confirm Prometheus metrics, distributed traces, and logs are visible in the observability platform.

## Exit Criteria

The feature is ready for implementation execution when:
- Donor create/update flows pass validation.
- Donor eligibility review and lifecycle transitions are successful and traceable.
- Audit logging covers create, update, denial, override approval, and status transitions.
- Health checks and deployment probes pass consistently.
- Messaging and cache layers behave correctly under simulated failure.
