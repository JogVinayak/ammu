| Microservice                | What it does (1–2 lines)                                                                                                                |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| api-gateway                 | Single entry point for all clients. Routes requests to services, handles rate limits, auth token validation, and basic request shaping. |
| auth-service                | Login/signup, OTP/password flows, token issuance/refresh, session/device management.                                                    |
| tenant-service              | Multi-tenant org/school setup: tenant creation, config, domains, plans, branding, tenant-level policies.                                |
| user-profile-service        | User profile data (student/teacher/parent/mentor), preferences, avatars, basic settings.                                                |
| role-permission-service     | RBAC/ABAC rules: roles, permissions, role assignment, dashboard access rules per tenant.                                                |
| content-service             | Core learning content store: topics, modules, notes “source of truth” metadata, versions, tags.                                         |
| content-workflow-service    | Git-like workflow: draft → review → publish, approvals, change requests, version promotion/rollback.                                    |
| mindmap-service             | Mind map nodes/structures, layouts, map metadata, map sharing rules, map snapshots.                                                     |
| graph-relations-service     | Edges between concepts (with strength/TTL), prerequisites, backlinks; updates graph metrics on changes.                                 |
| notes-service               | Note blocks in Markdown + LaTeX, attachments references, note templates, note rendering metadata.                                       |
| annotation-service          | Student highlights/comments/reflection notes on read-only content (and later collaborative annotations).                                |
| recall-service              | Active recall orchestration: generates/serves recall items (flashcards/MCQs/blur notes/one-liners/teach-back prompts).                  |
| flashcard-service           | Flashcard CRUD, scheduling data hooks, card decks, card performance tracking events.                                                    |
| mcq-service                 | MCQ bank, options/explanations, difficulty/tags, and validation rules for assessments.                                                  |
| quiz-session-service        | Runs quizzes: session state, timing, attempts, scoring, review of wrong answers, anti-cheat basics.                                     |
| revision-scheduler-service  | Computes “what to revise next” per learner using TTL/edge strength + spaced repetition rules.                                           |
| edge-strength-service       | Updates edge strength/TTL based on recall outcomes (correct/incorrect/latency/confidence), decays over time.                            |
| notification-service        | Sends notifications (push/email/WhatsApp/SMS later) for due revisions, approvals, reminders, system alerts.                             |
| audit-log-service           | Immutable audit trail for admin actions and content changes (who/what/when), compliance-friendly logs.                                  |
| search-service              | Full-text + semantic-ish search indexing over notes/maps/questions; tenant-scoped search and filters.                                   |
| media-service               | File upload/download, virus scan hooks, storage links (S3/GCS), image/pdf metadata; access-controlled URLs.                             |
| analytics-service           | Learning analytics: retention trends, revision adherence, content effectiveness, cohort insights.                                       |
| reporting-service           | Generates exportable reports (PDF/CSV), scheduled reports, tenant dashboards summaries.                                                 |
| admin-console-service       | Admin operations backend: user/role/tenant management endpoints, moderation tools, support tooling.                                     |
| integration-webhook-service | Integrations: inbound/outbound webhooks, LMS/SSO hooks later, event subscriptions, retries and signatures.                              |
