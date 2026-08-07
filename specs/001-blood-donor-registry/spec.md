# Feature Specification: Blood Donor Registry

**Feature Branch**: `001-blood-donor-registry`

**Created**: 2026-08-01

**Status**: Draft

**Input**: User description: "Create a comprehensive feature specification for a CRUD system to register blood donors and patients for blood tests in a hospital collection center. Include functional requirements, data model, roles, workflows, validations, security constraints, user stories, acceptance criteria, and non-functional requirements. The output should be a clear product spec suitable for implementation planning."

## MVP Clarifications (confirmed 2026-08-06)

- The initial release (MVP) covers donor onboarding only. Patient intake and blood-test request workflows are deferred to a later phase.
- Donor records in the MVP follow the lifecycle: draft -> pending-review -> active -> inactive/deactivated.
- Urgent overrides require approval from a licensed medical officer/physician; every override must be logged with the reason and reviewer identity.
- Personal data is restricted to authorized roles, retained for 5 years, and then anonymized.
- The initial deployment target is AWS ECS/Fargate with RDS PostgreSQL and ElastiCache Redis.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Register a new blood donor for collection center screening (Priority: P1)

A collection center staff member can create a donor record with personal and medical eligibility information, verify the donor's identity and consent, and save the record for future donation scheduling or follow-up. This process ensures that only eligible donors are available for blood collection and reduces duplicate or incomplete records.

**Why this priority**: This is the foundational workflow for the system and directly supports safe blood collection. Without a trustworthy donor registry, the center cannot manage eligibility, scheduling, or donor communication.

**Independent Test**: A staff user can create a complete donor profile, validate required data, and confirm the donor is available for future collection activities.

**Acceptance Scenarios**:

1. **Given** the staff member is logged in with donor-registration permissions, **When** they create a donor with valid personal details, blood type, consent, and eligibility data, **Then** the system stores the record in draft state, routes it to pending-review, and only marks it active after review approval.
2. **Given** a required donor field is missing or invalid, **When** the user tries to save the record, **Then** the system rejects the submission with a clear validation message and preserves the record in draft state instead of creating a partial entry.

---

### User Story 2 (Deferred for Phase 2) - Register a patient and create a blood test request (Priority: P2)

Patient intake and blood-test request workflows are intentionally deferred from the MVP. This backlog item remains planned for a later phase when the donor onboarding service is stable and the hospital is ready to expand into patient and test-order workflows.

**Why this priority**: Patient intake is a core hospital workflow, but it is not required for the donor-onboarding MVP and should be delivered after the donor registry core is validated.

**Independent Test**: A clinician can create a complete patient record and test request that can be searched, updated, and tracked through collection and completion stages.

**Acceptance Scenarios**:

1. **Given** the user has patient-registration access, **When** they register a patient and add a blood test request with ordered tests and urgency, **Then** the system creates a unique patient record and a valid pending test order linked to that patient.
2. **Given** the patient already exists in the system with the same identity data, **When** the user attempts to create a duplicate record, **Then** the system flags the potential duplicate and requires confirmation or merging before final submission.

---

### User Story 3 - Update donor records and track donation or collection status (Priority: P1)

Authorized staff can view, update, and monitor donor records as the collection process advances. The system tracks status changes across donor intake, eligibility review, sample collection, and completion so operational teams have a single source of truth.

**Why this priority**: Accurate donor status tracking prevents missed follow-up, duplicate work, and unsafe collection decisions.

**Independent Test**: A user can find an active donor record, update fields or status, and confirm the system preserves historical context and audit traceability.

**Acceptance Scenarios**:

1. **Given** an active donor record exists, **When** a staff member updates status, eligibility, or collection details, **Then** the system saves the change and records the event with the actor and timestamp.
2. **Given** a donor record is marked as inactive or deactivated, **When** the status update is submitted, **Then** the system prevents invalid transitions and communicates the final state to the relevant user roles.

---

### User Story 4 - Manage access, reports, and operational oversight (Priority: P2)

Hospital administrators and authorized reviewers can search donor records, monitor donor workflow performance, audit user activity, and export approved reports without altering clinical data beyond their assigned permissions. This supports operational oversight and regulatory accountability.

**Why this priority**: Governance, auditability, and reporting are essential for high-volume health operations but do not block initial donor-registration use cases.

**Independent Test**: An authorized administrator can list active donor records, review audit entries, and generate a report without exposing restricted information outside the assigned role.

**Acceptance Scenarios**:

1. **Given** the user has administrative or audit permissions, **When** they search by date, blood type, or donor eligibility, **Then** the system returns only authorized donor records matching the selected criteria.
2. **Given** a user without proper permissions attempts to view or edit restricted data, **When** they submit the action, **Then** the system denies access and records the unauthorized attempt.

---

### Edge Cases

- What happens when a donor record contains missing required identifiers such as full name, date of birth, or contact information?
- How does the system handle a duplicate donor with near-identical personal details?
- What if a donor is temporarily ineligible due to recent donation or a medical contraindication?
- How does the system handle an urgent eligibility override and its audit trail?
- What if a user attempts to delete a record that has historic donation or collection dependency?

## Requirements *(mandatory)*

Note: The initial release (MVP) covers donor onboarding only. Patient and test-request capabilities are explicitly deferred to a later phase.

### Functional Requirements

- **FR-001**: The system MUST allow collection center staff to create, view, update, and deactivate donor records with complete personal and clinical eligibility information.
- **FR-002**: The system MUST assign a unique donor identifier for every created donor record. Patient identifiers are deferred to a later phase and are not required in the MVP.
- **FR-003**: The system MUST support patient registration in a future phase, including demographic data, contact details, and linked blood test requests.
- **FR-004**: The system MUST allow future patient and test-request workflows to create blood test requests associated with a specific patient, including ordered tests, urgency, requesting clinician, and collection date.
- **FR-005**: For the MVP donor workflow, the system MUST maintain a donor lifecycle with the states draft, pending-review, active, and inactive/deactivated. Patient and test-request lifecycle states remain deferred.
- **FR-006**: The system MUST validate mandatory fields before saving new donor records and prevent the creation of incomplete donor entries.
- **FR-007**: The system MUST support searching and filtering donor records by donor identification, blood type, date range, status, and collection center.
- **FR-008**: The system MUST detect likely duplicate donor registrations based on identity attributes and require explicit confirmation before finalizing a duplicate entry.
- **FR-009**: The system MUST record donor eligibility details, consent, contraindications, and last donation date to ensure safe blood collection decisions.
- **FR-010**: The system MUST support role-based access so staff, nurses, lab personnel, medical officers, and administrators see only the information necessary for their responsibilities.
- **FR-011**: The system MUST track all critical donor create, update, status, approval, and access actions in an audit log with user identity and timestamp.
- **FR-012**: The system MUST support donor eligibility updates and status changes without losing historical record integrity.
- **FR-013**: The system MUST prevent deletion of donor records that have active or historical dependencies, and instead use a controlled archival or deactivation flow.
- **FR-014**: The system MUST permit authorized users to generate operational reports for donor counts and collection activity by date or department.
- **FR-015**: The system MUST support urgent donor-eligibility overrides only when approved by a licensed medical officer/physician and must maintain a complete audit trail for the override.
- **FR-016**: The system MUST retain sensitive donor data according to the hospital's retention policy for 5 years and then anonymize the data while ensuring authorized access only.

### Roles

- **Collection Center Staff**: Registers donors, validates completeness of intake data, and supports schedule coordination.
- **Nurse / Clinical Officer**: Registers patients, initiates blood test requests, and confirms clinical details.
- **Laboratory Technician**: Reviews collection status, updates sample readiness, and records completion of test activities.
- **Medical Officer / Physician**: Reviews patient information, verifies urgency, and approves clinical decisions related to the request.
- **Administrator**: Manages user access, master data, reports, and operational oversight.
- **Auditor / Privacy Reviewer**: Reviews access logs and data handling compliance without modifying transaction records.

### Data Model

- **Donor**: Represents an individual eligible or ineligible to donate blood. Includes personal identity data, contact details, date of birth, sex, blood type, Rh factor, registration date, consent status, eligibility status, last donation date, and any medical contraindication flags.
- **Patient**: Represents an individual receiving blood tests in the hospital collection center. Includes hospital patient number, demographics, contact information, attending clinician, clinical notes, urgency level, and active care context.
- **Blood Test Request**: Represents a clinical request for one or more blood tests. Includes patient linkage, ordered tests, urgency, ordering clinician, requested collection date, and current workflow status.
- **Collection Event / Donation Record**: Represents the operational record of a donor collection or patient sample collection. Includes date, center, collected by, sample type, outcome, and traceability links.
- **User Account / Role Assignment**: Represents a person who accesses the system and their assigned privileges. Includes name, username, department, role, active status, and last login metadata.
- **Audit Log Entry**: Represents immutable evidence of a business event. Includes actor, timestamp, action type, affected record references, and outcome.
- **Master Data**: Standard reference values such as blood groups, test types, eligibility categories, departments, and status codes used consistently across workflows.

### Workflow Overview

1. **Donor registration workflow**: A staff member creates the donor record, verifies identity and eligibility, records consent, and saves the record as active or temporarily deferred.
2. **Deferred patient workflow**: Patient intake and blood-test request handling are planned for phase 2 and are not part of the MVP.
3. **Sample collection workflow**: Staff collect blood or process the donor sample, update the collection status, and link it to the related donor record and personnel.
4. **Completion workflow**: Authorized personnel update the final donor status after the donation process is complete.
5. **Review and reporting workflow**: Administrators and auditors review operational metrics, access logs, and compliance records without altering the underlying clinical data.

### Validation Rules

- Mandatory fields are required for donor registration before a donor record can reach an active state.
- Blood type values must conform to the approved hospital list and include Rh status when applicable.
- Duplicate identity checks must be performed for new donor records.
- Donor eligibility must be confirmed before a record is marked available for donation.
- Incomplete, inconsistent, or expired consent must prevent the record from being used in live collection workflows.
- Donor lifecycle transitions must follow the defined sequence draft -> pending-review -> active -> inactive/deactivated and must reject invalid moves.
- User actions must be validated against the minimum permission level required for the task.
- Urgent eligibility overrides require explicit approval from a licensed medical officer/physician and complete audit logging.

### Security Constraints

- All donor records MUST be treated as confidential medical information and restricted to authorized personnel based on role.
- Access MUST be enforced through role-based access control, with least-privilege permissions for donor registration, lab processing, and administrative oversight.
- Sensitive data MUST be protected in transit and at rest according to the hospital's security policy.
- Every read, write, update, delete, and access-denied event relevant to medical or personal data MUST be logged for audit and investigation.
- Administrative exports or bulk reports MUST require explicit authorization and must not expose data beyond the approved scope.
- Session timeout, secure authentication, and account lockout controls MUST be enforced for non-public user access.
- Personal data MUST be retained for 5 years and then anonymized in line with hospital privacy policy and legal requirements.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: New donor records are created and validated in under 3 minutes for standard intake workflows in 95% of cases.
- **SC-002**: At least 98% of submitted donor records pass validation without requiring a second submission due to missing or invalid information.
- **SC-003**: 100% of critical donor data changes and access attempts are captured in the audit log with actor and timestamp information.
- **SC-004**: 90% of donor records transition from draft or pending-review to active or inactive/deactivated status within the expected timeframe for routine cases.
- **SC-005**: Hospital staff can complete primary donor registration workflows without more than one manual escalation per 20 transactions.
- **SC-006**: The system reduces duplicate donor record creation by at least 75% compared to manual intake processes.

## Assumptions

- The hospital operates a single collection center with a shared operational workflow for donor intake and donor eligibility review.
- The initial release supports a web-based or desktop-based user interface for donor-registration staff, lab staff, and administrators.
- Existing hospital identity systems may be reused later, but the initial feature is implemented as a local registry with strong validation rules and role controls.
- Data retention and privacy handling follow the healthcare organization's policy and legal obligations, with 5-year retention and anonymization after that period.
- The feature scope for the MVP includes donor registration and donor eligibility management; patient intake and blood test request workflows are deferred to a later phase.
- Emergency or urgent donor-eligibility overrides are handled using the same controlled workflow with enhanced logging and physician approval.

## Additional Implementation Guidance

This feature is intended to support the operational needs of a hospital collection center and should be implemented with emphasis on data quality, privacy, traceability, and predictable workflow transitions. The system should avoid partial records, support duplicate prevention, and provide consistent access boundaries across authorized roles. It should be suitable for implementation planning as a business-critical patient-safety workflow with strong audit requirements.
