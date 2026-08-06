# Research: Blood Donor and Patient Registry

## Decision Summary

- Use a Java 21 / Spring Boot 3.x microservice architecture with a relational PostgreSQL primary database, Redis for caching, and RabbitMQ for async integration.
- Split responsibilities into donor, patient, test-request, audit, notification, and identity/lookup services to keep business domains isolated and auditable.
- Implement AWS deployment on EKS (or ECS Fargate) with ALB, RDS, ElastiCache Redis, S3 for reports, and CloudWatch + OpenTelemetry for observability.
- Enforce strong role-based access using Spring Security, OAuth2/OIDC, JWTs or AWS Cognito integration, and least-privilege policy enforcement.
- Use optimistic locking, database indexes, materialized reporting tables, and asynchronous event-driven updates for high-write and high-read availability under clinical workloads.

## Rationale

### 1. Microservice boundaries fit hospital workflows
The system contains distinct functional domains: donor management, patient intake, blood test requests, collection actions, and audit/compliance. Service separation reduces outage blast radius and allows independent scaling per workload. The donor and patient domains share patient-safe workflows but are independent enough to evolve without cross-cutting release risk.

### 2. PostgreSQL is the right transactional backbone
The workflow requires strong transactional integrity, history retention, concurrency control, and audit logging. PostgreSQL supports row-level locking, referential integrity, indexes, partitioning, and JSONB if needed for flexible clinical metadata while preserving relational consistency.

### 3. RabbitMQ supports asynchronous clinical workflows without blocking user actions
Registration, duplicate detection, notifications, report generation, and integration tasks should not block front-end interactions. RabbitMQ decouples the registration flows from downstream work such as duplicate checks, analytics, notifications, and export tasks.

### 4. Redis improves performance for reference and high-frequency reads
Reference data (blood types, departments, status codes, active eligibility flags, patient lookups) and frequent identity queries benefit from Redis caching. It reduces repeated SQL reads for shared, relatively static data while preserving transactional source-of-truth in PostgreSQL.

### 5. AWS containerized deployment aligns with operational requirements
The required architecture calls for high availability, autoscaling, health checks, and resilient deployment. EKS/ECS with ALB, RDS, ElastiCache, S3, and CloudWatch provide a cloud-native operational model consistent with the hospital's data safety and uptime requirements.

## Alternatives Considered

### Monolith-first design
Pros: faster initial delivery for a single team.
Cons: harder to isolate compliance-critical workflows, more difficult to scale donor and patient domains independently, and riskier to deploy change sets affecting all business flows.
Decision: reject for v1 because domain isolation, audit separation, and future scale justify explicit service boundaries.

### NoSQL primary store
Pros: flexible schema for fast writes and document patterns.
Cons: weaker relational integrity, harder audit provenance, more complex cross-entity joins, and incompatible with strong reporting and compliance requirements.
Decision: reject for transactional core; use PostgreSQL as the source of truth.

### Synchronous integration between services
Pros: simpler at first glance.
Cons: worsens latency, creates cascading failure risk, and violates resilience expectations for clinical operations.
Decision: reject; use RabbitMQ and asynchronous event-bus patterns for non-critical workflows.

### Single-region cloud deployment with direct database access only
Pros: lower initial cost.
Cons: weaker resilience and lower availability under infrastructure failures.
Decision: reject; use multi-AZ database and service deployment with health checks, autoscaling, and load balancers.

## Key Research Findings

- Blood donor and patient registries are heavily read/write mixed with strong validation and audit requirements. This favors a transactional relational core plus a cache layer and async processing pipeline.
- Duplicate detection should be performed with deterministic rules and a confidence score rather than a single exact-match check.
- High-volume access patterns can be optimized through DB indexes on identifiers, status, date, blood type, and center/department fields.
- Reporting by date, department, blood type, and urgency should use a read-optimized reporting model or materialized views rather than direct OLTP queries.
- Security patterns for healthcare data require TLS, secret management, least-privilege access, session controls, auditability, and encryption in transit and at rest.
- Cloud-native health and readiness probes remain mandatory for container orchestration to enable safe rollouts and auto-recovery.

## Open Issues and Decisions Pending Implementation

- Exact AWS region, tenancy model, and disaster recovery target (single-region vs multi-region) will be finalized during infrastructure design.
- Real identity integration with hospital master data and EMR systems may be added after MVP but should not block the core registry design.
- The exact retention policy and privacy controls will be aligned with hospital legal and compliance teams during the design review.

## Implementation Guidance

The design should prioritize correctness over cleverness:

1. Keep transactional validations in the domain service layer.
2. Use events for downstream processing, not for core business validation.
3. Treat audit records as append-only and immutable.
4. Separate operational reporting from OLTP performance-critical queries.
5. Have every HTTP endpoint expose idempotency and audit-friendly semantics for clinical operations.
