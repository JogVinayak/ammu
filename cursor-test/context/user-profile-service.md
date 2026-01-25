# user-profile-service — Context File (Amogh Project) — Spring Boot + Postgres + Liquibase + Lombok

## 0) Stack & Conventions
- Language/Framework: **Java 21+**, **Spring Boot 4.x**
- Persistence: **Spring Data JPA (Hibernate)** + **PostgreSQL**
- DB Migrations: **Liquibase** (changelogs in `src/main/resources/db/changelog/`)
- Boilerplate reduction: **Lombok** (DTOs + Entities)
- API Style: REST + JSON under `/v1`
- Auth: Requests arrive via **api-gateway** with verified JWT.
- Multi-tenancy: Every record is scoped by `tenantId`. In dev/testing you may default to a single tenant, but schema must keep `tenant_id`.
- Source of truth:
  - Identity/credentials: `auth-service`
  - Roles/permissions: `role-permission-service`
  - Tenant config: `tenant-service`

---

## 1) Purpose
`user-profile-service` stores **non-auth** user data needed by Amogh:
- Display/profile info (name, avatar)
- Learner attributes (grade/class, section, roll no)
- Relationships (parent-child, mentor-student) as **references**
- Preferences (language, notification prefs, timezone)
- Onboarding/completion flags

It does **NOT** store passwords, OTPs, sessions, or tokens.
It does **NOT** decide permissions (authorization is handled elsewhere).

---

## 2) Responsibilities
### Does
- Create and manage tenant-scoped user profiles for existing `userId`s
- Provide profile views for dashboards (student/teacher/admin)
- Maintain user relationships (parent/mentor links) as references
- Store user settings/preferences used by notification-service & UI

### Does NOT
- Authenticate users (auth-service)
- Assign roles/permissions (role-permission-service)
- Create tenants (tenant-service)
- Own “classes” domain (for MVP, class can be a string or ID; later you can introduce a class-service)

---

## 3) Data Model / POJOs (JPA Entities)

### Lombok guidelines (project-wide)
Use Lombok to reduce verbosity:
- Entities: `@Getter @Setter`, `@NoArgsConstructor`, optionally `@ToString(exclude=...)`
- DTOs: `@Data` OR `@Getter/@Setter` + `@Builder`
- Prefer `@Builder` on DTOs, not always on Entities.
- For JPA entities, avoid `@Data` (it generates `equals/hashCode` that may break with lazy proxies). Prefer `@Getter/@Setter`.

---

### 3.1 UserProfile (core entity)
**Table:** `user_profiles`

Fields:
- `UUID id` (PK)  // internal profileId
- `UUID tenantId` (NOT NULL)
- `UUID userId` (NOT NULL) // from auth-service; unique per tenant
- `String displayName` (NOT NULL)
- `String firstName` (nullable)
- `String lastName` (nullable)
- `String email` (nullable, denormalized cache; auth-service is source of truth)
- `String phone` (nullable, denormalized cache)
- `String avatarUrl` (nullable)
- `UserType userType` = `STUDENT|TEACHER|MENTOR|PARENT|ADMIN` (optional; roles are authoritative elsewhere)
- `ProfileStatus status` = `ACTIVE|SUSPENDED|DELETED`
- `Instant createdAt`, `String createdBy`
- `Instant updatedAt`, `String updatedBy`
- `long version` (`@Version` optimistic lock)

Constraints/Indexes:
- UNIQUE(`tenant_id`, `user_id`)
- INDEX(`tenant_id`, `status`)
- Optional index for search: `display_name` (or rely on search-service later)

---

### 3.2 StudentProfile (optional: separate table)
**Table:** `student_profiles`
Fields:
- `UUID id` (PK)
- `UUID tenantId`
- `UUID userId` (unique per tenant)
- `String grade` (e.g., "10")
- `String section` (e.g., "A")
- `String rollNumber` (nullable)
- `UUID classId` (nullable; if later class-service exists)
- `String board` (nullable; CBSE/ICSE/State)
- `Instant createdAt`, `Instant updatedAt`

MVP alternative:
- Put grade/section/rollNumber directly inside `UserProfile` as nullable fields to reduce joins.

---

### 3.3 UserPreference
**Table:** `user_preferences`

Fields:
- `UUID id` (PK)
- `UUID tenantId`
- `UUID userId` (unique per tenant)
- `String language` (e.g., "en", "hi", "mr")
- `String timezone` (e.g., "Asia/Kolkata")
- `boolean notificationsEnabled`
- `jsonb channels` (notification channel preferences)
- `jsonb extra` (future-safe)
- `Instant createdAt`, `Instant updatedAt`

Example `channels` JSON:
```json
{
  "inApp": true,
  "email": true,
  "sms": false,
  "whatsapp": false
}
