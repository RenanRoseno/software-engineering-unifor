# Quickstart Validation Guide

## Purpose

This guide provides the steps to validate that the donor and patient registry reaches implementation readiness for a hospital collection center. It focuses on operationally relevant flows rather than low-level code.

## Prerequisites

- Java 21
- Docker / Docker Compose
- PostgreSQL 15+
- Redis 7+
- RabbitMQ 3.13+
- AWS account or local equivalent for EKS/ECS deployment preview
- GitHub Actions or deployment automation configured for CI/CD

## Local Development Setup

1. Start infrastructure dependencies:
   - PostgreSQL
   - Redis
   - RabbitMQ
   - Prometheus/Grafana dashboard stack (optional but recommended)
2. Start the Spring Boot microservices:
   - donor-service
   - patient-service
   - test-request-service
   - audit-service
   - notification-service
3. Configure environment variables for database URLs, Redis connection, RabbitMQ host, JWT issuer, and AWS secrets.

## Validation Scenarios

### Scenario 1: Donor registration and validation

1. Log in as a collection center staff user.
2. Submit a valid donor profile with required fields.
3. Observe that the system creates a donor record with a unique donor ID.
4. Confirm eligibility validation passes and donor is marked active or deferred based on the rule set.
5. Validate that a create event is recorded in the audit log.

Expected result: donor is stored successfully, validation passes, and audit log shows actor and timestamp.

### Scenario 2: Patient intake and test request

1. Log in as a nurse or clinical officer.
2. Register a patient with hospital number, identity details, and attending clinician context.
3. Submit a blood test request with one or more test codes and urgency level.
4. Verify patient record persists and linked test request is in pending state.
5. Confirm a duplicate check warning or confirm flow is triggered when near-duplicate identity data is detected.

Expected result: patient and test request are created and linked with correct status and audit event.

### Scenario 3: Status progress and invalid transition prevention

1. Move a test request from pending to active and then to in progress.
2. Attempt an invalid transition (for example, completed without a valid collection event).
3. Verify domain validation rejects the transition and records a failure audit event.

Expected result: invalid transition is prevented and a clear error is returned.

### Scenario 4: Resilience and async workflow validation

1. Temporarily stop or slow downstream notification processing.
2. Submit a donor or patient update that triggers an event-driven workflow.
3. Verify the core transaction commits and asynchronous consumer retries or queues the message.
4. Confirm the system continues to serve requests while the downstream dependency recovers.

Expected result: the core workflow remains stable; async tasks eventually complete with retries and observability traces.

### Scenario 5: Reporting and admin access validation

1. Log in as an administrator.
2. Search by blood type, date range, patient status, or urgency level.
3. Run a report export for donor counts or pending test requests.
4. Confirm the exported scope respects least-privilege rules.

Expected result: authorized report is generated, unauthorized data is excluded, and the access event is logged.

## Deployment Validation

1. Build Docker images for all services.
2. Deploy to AWS EKS or ECS using infrastructure-as-code.
3. Validate load balancer health checks and service readiness endpoints.
4. Check autoscaling and warm-up behavior under simulated load.
5. Confirm Prometheus metrics, distributed traces, and logs are visible in the observability platform.

## Exit Criteria

The feature is ready for implementation execution when:
- Donor create/update flows pass validation.
- Patient + blood test request creation is successful and traceable.
- Audit logging covers create, update, denial, and status transitions.
- Health checks and deployment probes pass consistently.
- Messaging and cache layers behave correctly under simulated failure.
