# Tasks: Blood Donor and Patient Registry

**Input**: Design documents from `/specs/001-blood-donor-registry/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize the multi-service repository and shared runtime foundation needed for the registry.

- [X] T001 Create the multi-module backend structure under `backend/services/`, `backend/shared/`, and `backend/infra/` per the implementation plan
- [X] T002 Initialize the Java 21 / Spring Boot 3.x build with Gradle or Maven and shared dependency versions in `backend/build.gradle` and `backend/settings.gradle`
- [X] T003 [P] Configure CI quality gates, static analysis, and test execution in `.github/workflows/ci.yml` and `backend/build.gradle`
- [X] T004 [P] Add the local infrastructure stack for PostgreSQL, Redis, RabbitMQ, and monitoring in `backend/infra/docker/docker-compose.yml`
- [X] T005 [P] Define environment configuration templates and secret placeholders in `backend/infra/docker/.env.example`, `backend/services/*/src/main/resources/application.yml`, and `backend/infra/terraform/variables.tf`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the core platform services, persistence, messaging, and security rules, without which no user story can be implemented safely.

- [ ] T006 Implement the PostgreSQL Flyway baseline and schema for donors, patients, requests, collection events, audit logs, and master data in `backend/infra/db/migration/V001__init_registry_schema.sql`
- [ ] T007 Create the shared domain models, validation utilities, and API DTOs in `backend/shared/common-lib/src/main/java/com/hospital/common/` and `backend/shared/contracts/src/main/java/com/hospital/contracts/`
- [ ] T008 [P] Configure Spring Security, OAuth2/OIDC integration, and RBAC metadata in `backend/shared/security-lib/src/main/java/com/hospital/security/` and `backend/services/identity-gateway/src/main/java/com/hospital/identity/`
- [ ] T009 [P] Configure Redis caching, cache keys, and master-data bootstrap in `backend/services/*/src/main/java/com/hospital/*/config/RedisConfig.java` and `backend/services/*/src/main/java/com/hospital/*/cache/`
- [ ] T010 [P] Implement RabbitMQ topology, message contracts, and publisher configuration in `backend/services/*/src/main/java/com/hospital/*/messaging/` and `backend/services/*/src/main/resources/application.yml`
- [ ] T011 Implement the append-only audit event model and immutable writer path in `backend/services/audit-service/src/main/java/com/hospital/audit/`
- [ ] T012 Implement global health checks, structured logging, error envelopes, and validation exception handling in `backend/shared/common-lib/src/main/java/com/hospital/common/` and `backend/services/*/src/main/java/com/hospital/*/exception/`

**Checkpoint**: Foundation ready - user story implementation can begin in parallel.

---

## Phase 3: User Story 1 - Register a new blood donor for collection center screening (Priority: P1) 🎯 MVP

**Goal**: Allow staff to create and maintain a trustworthy donor record with validation, consent, duplicate checks, and audit logging.

**Independent Test**: A staff user can create a complete donor profile, validate required data, and confirm the donor record is available for future collection workflows.

### Implementation for User Story 1

- [ ] T013 [P] [US1] Create the `Donor` entity, repository, and persistence model in `backend/services/donor-service/src/main/java/com/hospital/donor/domain/Donor.java` and `backend/services/donor-service/src/main/java/com/hospital/donor/repository/DonorRepository.java`
- [ ] T014 [P] [US1] Implement donor validation, duplicate detection, consent checks, and eligibility state transitions in `backend/services/donor-service/src/main/java/com/hospital/donor/service/DonorService.java`
- [ ] T015 [US1] Implement donor create/get/update/deactivate API endpoints and request/response DTOs in `backend/services/donor-service/src/main/java/com/hospital/donor/api/DonorController.java`
- [ ] T016 [US1] Emit donor created/updated/deactivated events and write immutable audit entries in `backend/services/donor-service/src/main/java/com/hospital/donor/events/DonorEventProducer.java` and `backend/services/audit-service/src/main/java/com/hospital/audit/service/AuditPublisher.java`
- [ ] T017 [P] [US1] Add contract tests for donor CRUD and validation in `backend/services/donor-service/src/test/java/com/hospital/donor/DonorApiContractTest.java`
- [ ] T018 [P] [US1] Add a donor registration integration test covering valid entry, duplicate detection, and invalid field rejection in `backend/services/donor-service/src/test/java/com/hospital/donor/DonorRegistrationIT.java`

**Checkpoint**: User Story 1 is fully functional and testable independently.

---

## Phase 4: User Story 2 - Register a patient and create a blood test request (Priority: P1)

**Goal**: Support patient intake and test ordering with valid clinical metadata, urgency handling, and patient-to-request linkage.

**Independent Test**: A clinician can register a patient and create a blood test request that is searchable, traceable, and linked to the correct patient record.

### Implementation for User Story 2

- [ ] T019 [P] [US2] Create the `Patient` and `BloodTestRequest` aggregates and repositories in `backend/services/patient-service/src/main/java/com/hospital/patient/domain/Patient.java`, `backend/services/test-request-service/src/main/java/com/hospital/testrequest/domain/BloodTestRequest.java`, and their repository packages
- [ ] T020 [P] [US2] Implement patient duplicate detection, request validation, and urgency/state rules in `backend/services/patient-service/src/main/java/com/hospital/patient/service/PatientService.java` and `backend/services/test-request-service/src/main/java/com/hospital/testrequest/service/TestRequestService.java`
- [ ] T021 [US2] Implement patient intake and blood test request create/list/update API endpoints in `backend/services/patient-service/src/main/java/com/hospital/patient/api/PatientController.java` and `backend/services/test-request-service/src/main/java/com/hospital/testrequest/api/TestRequestController.java`
- [ ] T022 [US2] Implement request workflow validation and collection-center linkage for patient test orders in `backend/services/test-request-service/src/main/java/com/hospital/testrequest/service/RequestWorkflowValidator.java`
- [ ] T023 [P] [US2] Add contract tests for patient and request API endpoints in `backend/services/patient-service/src/test/java/com/hospital/patient/PatientApiContractTest.java` and `backend/services/test-request-service/src/test/java/com/hospital/testrequest/TestRequestApiContractTest.java`
- [ ] T024 [P] [US2] Add an end-to-end patient intake and request lifecycle integration test in `backend/services/patient-service/src/test/java/com/hospital/patient/PatientIntakeIT.java` and `backend/services/test-request-service/src/test/java/com/hospital/testrequest/TestRequestLifecycleIT.java`

**Checkpoint**: User Stories 1 and 2 can both be validated independently and continue to work in parallel.

---

## Phase 5: User Story 3 - Update records and track test or collection status (Priority: P1)

**Goal**: Capture operational status changes, collection outcomes, and immutable audit evidence for donor and patient workflow progression.

**Independent Test**: A user can move records through status changes, reject invalid transitions, and confirm the system preserves audit clarity and historical context.

### Implementation for User Story 3

- [ ] T025 [US3] Create the `CollectionEvent` domain model and repository in `backend/services/test-request-service/src/main/java/com/hospital/testrequest/domain/CollectionEvent.java` and `backend/services/test-request-service/src/main/java/com/hospital/testrequest/repository/CollectionEventRepository.java`
- [ ] T026 [US3] Implement collection outcomes, defer/fail handling, and status transition validation in `backend/services/test-request-service/src/main/java/com/hospital/testrequest/service/CollectionEventService.java`
- [ ] T027 [US3] Implement read-only audit queries, access-denial logging, and immutable event retrieval in `backend/services/audit-service/src/main/java/com/hospital/audit/api/AuditController.java`
- [ ] T028 [P] [US3] Seed master data for blood groups, RH factors, departments, urgency levels, status codes, and collection centers in `backend/infra/db/migration/V002__seed_master_data.sql`
- [ ] T029 [P] [US3] Implement operational reporting and export logic for donor counts, patient activity, and pending requests in `backend/services/audit-service/src/main/java/com/hospital/audit/service/ReportingService.java` and `backend/services/audit-service/src/main/java/com/hospital/audit/api/ReportController.java`
- [ ] T030 [P] [US3] Add status-flow regression and invalid-transition tests in `backend/services/test-request-service/src/test/java/com/hospital/testrequest/StatusTransitionIT.java` and `backend/services/audit-service/src/test/java/com/hospital/audit/AuditLogIT.java`

**Checkpoint**: Core workflow tracking is complete and independently testable.

---

## Phase 6: User Story 4 - Manage access, reports, and operational oversight (Priority: P2)

**Goal**: Secure the registry for multiple roles, enforce least privilege, and support administrator and auditor review workflows.

**Independent Test**: An authorized administrator can search records, review audit logs, and export approved reports without exposing restricted clinical data.

### Implementation for User Story 4

- [ ] T031 [P] [US4] Implement user-account and role-permission models in `backend/services/identity-gateway/src/main/java/com/hospital/identity/domain/UserAccount.java` and `backend/shared/security-lib/src/main/java/com/hospital/security/authorization/`
- [ ] T032 [US4] Enforce least-privilege access control for donor, patient, request, and reporting APIs in `backend/shared/security-lib/src/main/java/com/hospital/security/config/SecurityConfig.java` and service-level security checks
- [ ] T033 [P] [US4] Implement admin/auditor search, data redaction, denial logging, and report authorization checks in `backend/services/audit-service/src/main/java/com/hospital/audit/service/AdminAuditService.java`
- [ ] T034 [P] [US4] Add an integration test for denied access and approved administrative report export in `backend/services/audit-service/src/test/java/com/hospital/audit/AdminAccessIT.java`
- [ ] T035 [US4] Validate session timeout, credential handling, and audit coverage with security review tasks in `backend/infra/security/` and `backend/services/identity-gateway/src/test/java/com/hospital/identity/`

**Checkpoint**: Security and oversight workflows are in place and independently verifiable.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Finalize production readiness across AWS deployment, resilience, observability, and end-to-end validation.

- [ ] T036 [P] Provision AWS infrastructure-as-code for EKS/ECS, ALB, RDS, ElastiCache, S3, IAM, Secrets Manager, ACM, and CloudWatch in `backend/infra/terraform/` and `backend/infra/kubernetes/`
- [ ] T037 [P] Add Resilience4j patterns, retry/backoff policies, circuit breakers, and idempotent consumer logic in `backend/shared/common-lib/src/main/java/com/hospital/common/resilience/` and `backend/services/*/src/main/java/com/hospital/*/messaging/`
- [ ] T038 [P] Add OpenTelemetry tracing, log correlation, metric dashboards, and alerting in `backend/infra/monitoring/prometheus.yml`, `backend/infra/monitoring/grafana/`, and service `MeterRegistry` instrumentation
- [ ] T039 Run the end-to-end validation suite and k6/Newman performance checks for donor onboarding, patient intake, status transitions, and admin reporting in `backend/tests/e2e/` and `backend/tests/perf/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Starts immediately; no dependencies.
- **Foundational (Phase 2)**: Depends on Setup completion and blocks all user story work.
- **User Stories (Phases 3-6)**: Depend on Foundational completion; each story is independently testable.
- **Polish (Phase 7)**: Depends on completion of all user stories and security review.

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Phase 2; no dependency on other stories.
- **User Story 2 (P1)**: Can start after Phase 2; can be implemented in parallel with US1.
- **User Story 3 (P1)**: Depends on US1 and US2 for workflow linkage; can begin once core domains exist.
- **User Story 4 (P2)**: Depends on baseline security and audit foundations; can be implemented once US1-US3 are stable.

### Parallel Opportunities

- T003, T004, and T005 can run in parallel during Setup.
- T008, T009, and T010 can run in parallel during Foundational.
- T013/T014, T019/T020, and T025/T028 can run in parallel by separate engineering teams once the foundation is complete.
- Contract and integration tests under each user story can run in parallel with implementation of adjacent components.

---

## Parallel Example: User Story 1

```bash
# Donor service parallel workstreams
Task: "Create Donor entity and repository in backend/services/donor-service/.../domain/Donor.java"
Task: "Implement donor validation and duplicate detection in backend/services/donor-service/.../DonorService.java"
Task: "Add Donor contract tests in backend/services/donor-service/src/test/java/com/hospital/donor/DonorApiContractTest.java"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational.
3. Complete Phase 3: User Story 1.
4. Validate donor onboarding end-to-end.
5. Stop and confirm the MVP is stable before continuing to patient intake.

### Incremental Delivery

1. Add User Story 1 -> validate donor lifecycle and audit.
2. Add User Story 2 -> validate patient intake and test-order creation.
3. Add User Story 3 -> validate collection tracking and operational reporting.
4. Add User Story 4 -> validate admin and audit governance.
5. Complete Phase 7 for production deployment and resilience hardening.

### Team Strategy

- Team A: donor service and validation
- Team B: patient service and test-request service
- Team C: audit service, security, and reporting
- Team D: infrastructure, deployment, and monitoring

---

## Notes

- [P] tasks are parallelizable and should be assigned to different files or independent streams.
- Each task includes a direct file or service path to reduce ambiguity for engineering teams.
- Every user story is independently testable and should remain deployable after its phase completes.
- Validation tasks are intentionally written before production completion to support TDD and release readiness.
- The tasks are ready to execute by service teams, database engineers, security reviewers, and platform/DevOps engineers.
