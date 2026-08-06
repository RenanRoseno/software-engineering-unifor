# Data Model: Blood Donor and Patient Registry

## Overview

This data model defines the transactional entities for donor registration, patient intake, blood test requests, clinical collection events, access control, and audit records. The model is optimized for relational integrity, operational traceability, and compliance requirements.

## Core Entities

### 1. Donor

| Field | Type | Constraints | Notes |
|---|---|---|---|
| donor_id | UUID | PK, immutable | Unique donor identifier |
| national_id | VARCHAR(32) | unique, nullable | Optional external identity reference |
| first_name | VARCHAR(120) | not null |  |
| last_name | VARCHAR(120) | not null |  |
| date_of_birth | DATE | not null |  |
| sex | VARCHAR(20) | not null | Enum-like value |
| blood_type | VARCHAR(10) | not null | A, B, AB, O |
| rh_factor | VARCHAR(5) | not null | + or - |
| phone_number | VARCHAR(30) | not null |  |
| email | VARCHAR(255) | nullable |  |
| address_line1 | VARCHAR(255) | not null |  |
| city | VARCHAR(80) | not null |  |
| state_province | VARCHAR(80) | nullable |  |
| country | VARCHAR(80) | not null |  |
| consent_status | VARCHAR(30) | not null | granted / pending / revoked |
| eligibility_status | VARCHAR(30) | not null | eligible / deferred / ineligible |
| last_donation_date | DATE | nullable |  |
| contraindication_flags | TEXT | nullable | Structured JSON or normalized flags |
| registration_date | TIMESTAMP | not null |  |
| status | VARCHAR(30) | not null | active, suspended, archived |
| version | BIGINT | not null | Optimistic locking |
| created_by | UUID | FK to user_account |  |
| updated_by | UUID | FK to user_account |  |
| created_at | TIMESTAMP | not null |  |
| updated_at | TIMESTAMP | not null |  |

#### Validation Rules
- Donor registration requires name, date of birth, contact, blood group, consent, and eligibility status.
- Duplicate identity checks use national ID, phone, and full-name + DOB heuristics.
- If eligibility is temporarily deferred, donor cannot be used in active collections until reapproved.

### 2. Patient

| Field | Type | Constraints | Notes |
|---|---|---|---|
| patient_id | UUID | PK, immutable | Unique patient identifier |
| hospital_number | VARCHAR(40) | unique, not null | Internal hospital record number |
| first_name | VARCHAR(120) | not null |  |
| last_name | VARCHAR(120) | not null |  |
| date_of_birth | DATE | not null |  |
| sex | VARCHAR(20) | not null |  |
| phone_number | VARCHAR(30) | nullable |  |
| email | VARCHAR(255) | nullable |  |
| address_line1 | VARCHAR(255) | nullable |  |
| attending_clinician_id | UUID | FK to user_account |  |
| clinical_notes | TEXT | nullable |  |
| urgency_level | VARCHAR(20) | not null | routine / urgent / emergency |
| status | VARCHAR(30) | not null | active, in_review, archived |
| version | BIGINT | not null | Optimistic locking |
| created_by | UUID | FK to user_account |  |
| updated_by | UUID | FK to user_account |  |
| created_at | TIMESTAMP | not null |  |
| updated_at | TIMESTAMP | not null |  |

#### Validation Rules
- A patient requires hospital number, demographics, and responsible clinician or intake metadata.
- Duplicate detection must compare hospital number and identity profile.
- Emergency requests require mandatory audit log entry and explicit urgency flag.

### 3. BloodTestRequest

| Field | Type | Constraints | Notes |
|---|---|---|---|
| test_request_id | UUID | PK, immutable | Unique request ID |
| patient_id | UUID | FK to patient | Required |
| requesting_clinician_id | UUID | FK to user_account | Required |
| collection_center_id | UUID | FK to collection_center | Required |
| requested_date | TIMESTAMP | not null | Preferred collection date |
| urgency_level | VARCHAR(20) | not null | routine / urgent / emergency |
| status | VARCHAR(30) | not null | pending, active, in_progress, completed, cancelled, archived |
| ordered_tests | JSONB / TEXT | not null | List of requested test codes |
| clinical_context | TEXT | nullable | Notes |
| version | BIGINT | not null | Optimistic locking |
| created_by | UUID | FK to user_account |  |
| updated_by | UUID | FK to user_account |  |
| created_at | TIMESTAMP | not null |  |
| updated_at | TIMESTAMP | not null |  |

#### Validation Rules
- Ordered tests cannot be blank.
- Status transitions must be validated against a fixed workflow map.
- Cancellation and completion require justification and audit records.

### 4. CollectionEvent

| Field | Type | Constraints | Notes |
|---|---|---|---|
| collection_event_id | UUID | PK, immutable | Unique event id |
| donor_id | UUID | FK to donor, nullable | Used for donation collection |
| patient_id | UUID | FK to patient, nullable | Used for patient sample collection |
| test_request_id | UUID | FK to blood_test_request, nullable | Associated workflow |
| collection_center_id | UUID | FK to collection_center | Required |
| collected_by_user_id | UUID | FK to user_account | Required |
| sample_type | VARCHAR(40) | not null | e.g., whole blood, plasma |
| collection_date | TIMESTAMP | not null |  |
| outcome | VARCHAR(40) | not null | collected / deferred / failed / rejected |
| notes | TEXT | nullable |  |
| created_at | TIMESTAMP | not null |  |
| updated_at | TIMESTAMP | not null |  |

#### Validation Rules
- A collection event must reference either donor or patient workflow, not both unless explicitly modeled as both in a later release.
- Defer and failure outcomes must still record event traceability and the responsible user.

### 5. UserAccount

| Field | Type | Constraints | Notes |
|---|---|---|---|
| user_id | UUID | PK |  |
| username | VARCHAR(120) | unique, not null |  |
| email | VARCHAR(255) | unique, not null |  |
| full_name | VARCHAR(200) | not null |  |
| department | VARCHAR(120) | not null |  |
| role | VARCHAR(40) | not null | e.g., Staff, Nurse, Lab, Physician, Admin |
| active | BOOLEAN | not null |  |
| last_login_at | TIMESTAMP | nullable |  |
| created_at | TIMESTAMP | not null |  |
| updated_at | TIMESTAMP | not null |  |

### 6. AuditLogEntry

| Field | Type | Constraints | Notes |
|---|---|---|---|
| audit_id | UUID | PK |  |
| actor_user_id | UUID | FK to user_account | Required |
| action_type | VARCHAR(80) | not null | create, update, access, delete, denial |
| entity_type | VARCHAR(80) | not null | donor, patient, test_request |
| entity_id | UUID | not null | Target record |
| outcome | VARCHAR(30) | not null | success / failure |
| details | JSONB | nullable | Structured action payload |
| ip_address | VARCHAR(64) | nullable |  |
| created_at | TIMESTAMP | not null | Immutable |

#### Validation Rules
- Audit rows are append-only and should not be modified after creation.
- Access-denied events must be recorded for unauthorized attempts.

### 7. MasterData

Master data should be stored as normalized reference tables, including:
- blood_group
- rh_factor
- test_catalog
- department
- collection_center
- status_code
- eligibility_category
- urgency_level

Each reference table includes:
- id
- code
- description
- active flag
- created_at
- updated_at

## Relationships

- One donor has many collection events.
- One patient has many blood test requests.
- One patient has many collection events.
- One blood test request belongs to one patient and many collection events.
- One user account may create many donor, patient, request, and audit records.
- One audit entry belongs to one actor and one target entity.

## State and Workflow Rules

### Donor lifecycle
- Draft -> Pending Validation -> Active -> Deferred/Suspended -> Archived
- Active donor can be used for collection after final eligibility confirmed.
- Deferred or ineligible donors cannot enter active collection without revalidation.

### Patient lifecycle
- Draft -> Active -> In Review -> Completed -> Archived

### test request lifecycle
- Pending -> Active -> In Progress -> Completed / Cancelled -> Archived

Invalid transitions should be rejected by domain validator logic and must be audited.

## Indexing Strategy

Primary indexes should be created on:
- donor(national_id, status)
- donor(blood_type, rh_factor, status)
- donor(created_at)
- patient(hospital_number)
- patient(status, urgency_level)
- blood_test_request(patient_id, status, requested_date)
- blood_test_request(collection_center_id, status, requested_date)
- collection_event(collection_date, outcome)
- audit_log_entry(actor_user_id, created_at)
- audit_log_entry(entity_type, entity_id, created_at)

## Data Retention and Privacy

- PII and clinical data must be encrypted at rest.
- Access logging must capture all reads, writes, and denied actions.
- Records with historical dependencies must be archived instead of deleted.
- Data retention should align with the hospital's policy and local healthcare compliance requirements.
