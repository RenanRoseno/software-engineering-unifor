# Implementation Plan: Blood Donor and Patient Registry

**Branch**: `001-blood-donor-registry` | **Date**: 2026-08-01 | **Spec**: `/specs/001-blood-donor-registry/spec.md`

**Input**: Feature specification from `/specs/001-blood-donor-registry/spec.md`

## Summary

This feature implements a secure, auditable blood donor and patient registry for a hospital collection center. The system must reliably support donor onboarding, patient intake, blood test request creation, status tracking, duplicate detection, role-based access, and operational reporting while preserving patient privacy and clinical traceability.

The selected architecture is a Java 21, Spring Boot 3.x microservice ecosystem backed by PostgreSQL, Redis caching, RabbitMQ messaging, and AWS-hosted container orchestration. The design emphasizes transactional integrity for medical records, asynchronous processing for non-critical workflows, and high availability through multi-AZ infrastructure, health checks, autoscaling, and observability.

## Technical Context

**Language/Version**: Java 21; Spring Boot 3.2.x; Gradle or Maven multi-module build

**Primary Dependencies**: Spring Web, Spring Data JPA, Spring Security, Spring Cloud OpenFeign, Spring Cloud Stream or AMQP, Resilience4j, Micrometer, OpenAPI/Swagger, Flyway, Lombok, Jackson, AWS SDK v2, RabbitMQ client, Redis client

**Storage**: PostgreSQL 15+ as transactional source of truth; Redis for cache and session/lookup acceleration; S3 for operational exports and reports; optional partitioned reporting tables for historical analysis

**Testing**: JUnit 5, Mockito, Spring Boot Test, Testcontainers, Contract tests, integration tests, k6 or Gatling for performance validation, Postman/Newman CLI for API verification

**Target Platform**: AWS (EKS preferred; ECS Fargate acceptable), Linux containers, ALB, RDS, ElastiCache, S3, CloudWatch, IAM, Secrets Manager, ACM

**Project Type**: Web service API; microservice-based healthcare workflow platform

**Performance Goals**: p95 API latency < 300 ms for CRUD operations; donor/patient search under 500 ms for indexed queries; report generation under 5 s for standard operational exports; support 200-500 concurrent clinical users during peak hours; queue throughput sufficient for non-blocking downstream processing

**Constraints**: healthcare privacy requirements; role-based access enforcement; immutable audit records; zero data loss for critical transactions; start-of-day availability target 99.9%; incident-safe deployments; no direct secret values in code or config repositories

**Scale/Scope**: initial hospital collection center deployment with multiple roles and shared operational workflows; future expandability to multi-center, multi-region, and EMR integration

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Requirement completeness: PASS. The feature specification defines testable functional requirements, role definitions, workflow states, validation rules, and acceptance scenarios.
- Quality built in: PASS. The design includes validation, tests, traceability, immutable audit logs, and explicit operational review points.
- Security and reliability: PASS. Role-based access, least privilege, encrypted transport, audit logging, observability, retries, circuit breakers, and zero-secret configuration are part of the plan.
- Simplicity over cleverness: PASS. The design uses clear service boundaries, transactional core data stores, and asynchronous messaging without unnecessary abstraction.
- Collaborative ownership: PASS. The implementation plan is explicit, reviewable, and structured for execution by multiple engineers and reviewers.

No constitution violations require exception or complexity tracking.

## Project Structure

### Documentation (this feature)

```text
specs/001-blood-donor-registry/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── blood-registry-api.yaml
└── tasks.md              # generated in Phase 2, not required for this plan
```

### Source Code (repository root)

```text
backend/
├── services/
│   ├── donor-service/
│   │   ├── src/main/java/com/hospital/donor
│   │   └── src/test/java/com/hospital/donor
│   ├── patient-service/
│   │   ├── src/main/java/com/hospital/patient
│   │   └── src/test/java/com/hospital/patient
│   ├── test-request-service/
│   │   ├── src/main/java/com/hospital/testrequest
│   │   └── src/test/java/com/hospital/testrequest
│   ├── audit-service/
│   │   ├── src/main/java/com/hospital/audit
│   │   └── src/test/java/com/hospital/audit
│   ├── notification-service/
│   │   ├── src/main/java/com/hospital/notification
│   │   └── src/test/java/com/hospital/notification
│   └── identity-gateway/
│       ├── src/main/java/com/hospital/identity
│       └── src/test/java/com/hospital/identity
├── shared/
│   ├── common-lib/
│   ├── contracts/
│   └── security-lib/
├── infra/
│   ├── docker/
│   ├── kubernetes/
│   ├── terraform/
│   └── monitoring/
├── scripts/
│   ├── migrate.sh
│   ├── deploy.sh
│   └── verify-health.sh
└── build.gradle / pom.xml
```

**Structure Decision**: Use a multi-service backend with explicit domain boundaries and shared contracts. The transactional source of truth remains in PostgreSQL; cache, messaging, and reporting responsibilities are separated to avoid coupling and improve operational independence.

## Architecture Overview

### Service boundaries

1. Donor Service
   - Owns donor lifecycle, identity attributes, consent and eligibility validation, and duplicate detection.
   - Exposes CRUD APIs for donor registration and status updates.
   - Writes donor events to the message bus for downstream notifications, reporting, and audit processing.

2. Patient Service
   - Owns patient identity and clinical context for intake workflows.
   - Handles patient search, duplicate checks, and patient status transitions.
   - Publishes patient-created and patient-updated events.

3. Test Request Service
   - Owns blood test requests, urgency prioritization, linking to patient records, and status management.
   - Validates request transitions and triggers collection workflows.
   - Emits events for lab workflow and notification updates.

4. Audit Service
   - Append-only immutable event store for writes, reads, access denials, and operational changes.
   - Provides secure query APIs for administrators, auditors, and privacy reviewers.
   - Consumes domain events from all services and writes to PostgreSQL in a separate, auditable write path.

5. Notification Service
   - Sends email/SMS or internal alerts for urgent requests, status updates, and approval actions.
   - Uses RabbitMQ to avoid blocking the original registration requests.

6. Identity / Access Gateway
   - Handles authentication, authorization, session management, and RBAC enforcement.
   - Integrates with OIDC/OAuth2 providers and may delegate to AWS Cognito or an internal IdP for the first release.

### Shared data responsibilities

- PostgreSQL is the source of truth for patient, donor, request, and audit records.
- Redis is used for read-heavy access patterns, such as master data, clinician lookup caches, and high-frequency patient/donor query results.
- RabbitMQ provides decoupled event delivery for non-critical actions like notifications, duplicate-analysis tasks, operations dashboards, and report refreshes.

## Data Model and Validation Strategy

The detailed entity model is in `/specs/001-blood-donor-registry/data-model.md`.

Key implementation rules:
- All domain transactions must validate required fields before moving to active state.
- Duplicate detection should be rule-based with a confidence score and explicit confirm/merge workflow.
- Status transitions must use an allowed-states matrix and be enforced by domain validators.
- All create/update/delete/denial actions must emit audit events.
- Deletion is replaced by deactivation/archive; soft delete is the default operational pattern.

## API Design

The API contract is defined in `/specs/001-blood-donor-registry/contracts/blood-registry-api.yaml`.

### Core API categories

- Donor API: create, list, get, update, deactivate, search by blood type and status.
- Patient API: create, search, get, update, link requests.
- Test Request API: create request, get details, update urgency and status, cancel/complete, query by department or center.
- Audit API: read-only access for administrators/auditors with filtering by actor, entity, outcome, and date.
- Auth API: login, logout, token refresh, RBAC metadata, permission checks.

### REST design principles

- Use versioned endpoints such as `/v1/...`.
- Require DTO validation and explicit schema errors for invalid payloads.
- Use 202 Accepted for async-heavy tasks and 201 Created for synchronous resource creation.
- Support pagination and sorting for listing endpoints.
- Use idempotency keys on write operations where repeated submission risk exists.
- Return canonical error envelopes for validation, authorization, and system failures.

## Messaging and Event Flows

### Event taxonomy

- donor.created
- donor.updated
- donor.eligibility.changed
- patient.created
- patient.updated
- test-request.created
- test-request.status.changed
- collection.event.created
- audit.entry.created
- notification.email.requested
- report.refresh.requested

### Messaging flow pattern

1. Domain service validates business state.
2. Service persists the transactional record in PostgreSQL.
3. Service emits a domain event to RabbitMQ.
4. Consumers process downstream tasks asynchronously:
   - Audit Service writes append-only records.
   - Notification Service sends alerts and reminders.
   - Reporting service updates summaries.
   - Duplicate-check service runs confidence analysis.
5. The user receives a synchronous success response after the primary transaction commits.

### Asynchronous processing requirements

- Non-blocking workflows use at-least-once delivery semantics with idempotent consumers.
- Message consumers must be idempotent; duplicates must not create duplicate notifications or duplicate audit entries.
- Dead-letter queues must capture failed jobs for investigation and reprocessing.
- Retry backoff policies must be configured for transient failures and downstream outages.

## Deployment Topology

### AWS deployment model

- Application Load Balancer in front of multiple service replicas
- EKS or ECS Fargate cluster for Spring Boot services
- RDS PostgreSQL with Multi-AZ failover and read replicas for reporting workloads
- ElastiCache Redis cluster to serve caches and hot lookups
- S3 bucket for bulk export and operational snapshots
- SQS or RabbitMQ cluster with message persistence and queue durability
- AWS Secrets Manager for database credentials, auth secrets, and API keys
- CloudWatch / Prometheus + Grafana for metrics, logs, and dashboards
- Route 53 or AWS internal DNS for service discovery and traffic routing

### Container strategy

- Build immutable Docker images for every service
- Use Kubernetes Deployments or ECS task definitions with rolling updates
- Define separate readiness and liveness probes for safe startup and self-healing
- Keep service state stateless; all critical state in PostgreSQL/Redis/RabbitMQ
- Use horizontal pod autoscaling or ECS autoscaling with CPU and memory thresholds

### HA and load balancing

- Run multiple replicas per service in at least two availability zones
- Use ALB or NLB for ingress, TLS termination, and health-based routing
- Keep database in multi-AZ with automatic failover
- Use Redis replication and failover for hot-path caches
- Use per-service autoscaling rules to maintain response under peak load

## Observability and Monitoring

### Metrics

- HTTP API latency, throughput, error rate, and saturation by service and endpoint
- DB connection pool usage, query latency, slow query counts, deadlocks
- Redis hit ratio, cache misses, connection count
- RabbitMQ queue depth, consumer lag, dead-letter traffic
- JVM metrics: heap, GC pauses, thread count, memory pressure

### Logs

- Structured JSON logs with correlation IDs, user IDs (or pseudonymous IDs), request IDs, and service names
- Centralized log aggregation to CloudWatch, ELK, or a managed logging service

### Tracing

- OpenTelemetry instrumentation across all services
- Trace propagation via HTTP headers and message headers
- Distributed traces for donor creation, patient registration, collection event updates, and notification processing
- Include trace IDs in logs and alerts for end-to-end diagnosis

### Health checks

- Liveness endpoint: process and dependency health at a coarse level
- Readiness endpoint: service is ready to receive traffic only when DB, MQ, and cache connectivity are healthy
- Kubernetes/ECS health checks must fail if application cannot access required dependencies

## Security

### Authentication and authorization

- Use OAuth2/OIDC with JWTs or AWS Cognito integration
- Store only minimal identity attributes in application tokens
- Enforce RBAC at the gateway and service layer
- Restrict access to donor, patient, and audit APIs by role and department
- Use least privilege for lab staff, physicians, administrators, and auditors

### Data protection

- TLS in transit for all APIs and inter-service calls
- Encryption at rest for PostgreSQL, Redis, and S3
- Secret management via AWS Secrets Manager or equivalent
- Mask or redact sensitive data in logs and exports
- Restrict admin exports and audits to approvals with explicit authorization

### Compliance and auditability

- Immutable append-only audit log for all critical actions
- Record actor identity, timestamp, target entity, outcome, and context
- Denied access attempts must be stored as audit events
- Retention and archival policies must comply with hospital rules and legal requirements

## Resilience and Scalability

### Resilience patterns

- Circuit breakers via Resilience4j for downstream services and external dependencies
- Retry with exponential backoff for transient network and dependency failures
- Bulkhead isolation to prevent one domain from exhausting shared resources
- Timeouts on all external calls and database queries
- Data validation before persistence to fail safely and prevent partial writes
- Dead-letter queues for message processing failures and replay support

### Scalability patterns

- Stateless service design for horizontal scaling
- Read replica for reporting and analytics workloads
- Redis cache for hot metadata and repeated reads
- Database indexing on identity, date, status, and center fields
- Materialized summaries or reporting tables for operational dashboards
- Asynchronous processing for notification, export, and duplicate-analysis tasks

### Performance boosters explicitly required

- Caching: Redis for master data, search hot spots, and session metadata
- Database indexing: unique and composite indexes for search, duplicate checks, and status filters
- Asynchronous processing: RabbitMQ queues for notification, reporting, and downstream event processing
- Load balancing: ALB/NLB across service replicas
- Autoscaling: HPA/ECS scaling based on CPU, memory, queue depth, and request latency
- Health checks: readiness/liveness checks done at container orchestration level
- Circuit breakers: protect downstream services and message consumers
- Retries: controlled exponential backoff on transient communication failures
- Distributed tracing: OpenTelemetry across user requests and queued workflows
- Containerized deployment: Docker images with Kubernetes/ECS orchestration

## High-Availability Strategy

- Deploy all critical services across multiple availability zones.
- Keep DB primary and failover instances in multi-AZ mode.
- Configure Redis failover and persistence.
- Use load-balanced stateless services and auto-healing deployment policies.
- Maintain a strict no-downtime release process using rolling updates and canary checks.
- Back up PostgreSQL regularly and test restore procedures.
- Quarantine or isolate unhealthy services with readiness gates and queue backpressure.
- Run synthetic checks and smoke tests before allowing production traffic to full scale.

## Implementation Phases

### Phase 0: Research and Decision Completion
- Confirm final service boundaries and data ownership.
- Finalize database schema and index design.
- Validate duplicate detection strategy.
- Document compliance, privacy, and retention requirements.
- Approve AWS topology and observability stack.

### Phase 1: Core Domain and Contract Design
- Create and validate domain modules: donor, patient, test request, audit, notification.
- Establish API contracts and DTO validation rules.
- Define persistence model, status matrices, and event contracts.
- Prepare quickstart and deployment validation guides.

### Phase 2: Service Implementation
- Implement donor, patient, and test-request services.
- Add Spring Security and RBAC enforcement.
- Add Flyway migration scripts and seed/reference data.
- Implement message producers and consumers for notification/audit/report flows.

### Phase 3: Resilience and Observability
- Add health endpoints, retries, circuit breakers, distributed tracing, and metrics collection.
- Configure autoscaling, queue monitoring, and alert thresholds.
- Validate failure scenarios and replay workflows.

### Phase 4: Production Readiness and Deployment
- Deploy via CI/CD to containerized AWS platform.
- Validate zero-downtime deployment and rollback path.
- Run load, security, and smoke tests.
- Approve release readiness with architecture and compliance reviewers.

## Exit Criteria for Execution Readiness

The implementation is ready to begin when:
- the service boundaries are approved,
- the data model is stable,
- the contracts are agreed,
- AWS topology and observability are designed,
- security and audit controls are in place,
- and operational review is signed off by engineering, security, and compliance stakeholders.

## Complexity Tracking

No constitution violations were identified; no complexity exceptions are required.
