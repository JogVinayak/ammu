# recall-service

Recall scheduling service for Amogh. It calculates next-study timeouts for topics based on the option chosen by the student and emits reminders (currently logged).

## Running locally

```bash
./gradlew bootRun
```

Default port: `8091`

## Database

Postgres connection (override via env vars):
- `jdbc:postgresql://localhost:5432/recall`
- user: `recall_user`
- password: `recall_password`

## API (behind gateway: /v1/recall/**)

- `POST /recall/attempts`
- `GET /recall/schedule/{topicId}`
- `GET /recall/due?asOf=&limit=`
- `POST /recall/schedule/{topicId}/reset`

All endpoints require headers:
- `X-Tenant-Id`
- `X-User-Id`
- `Authorization: Bearer <jwt>`

## Reminder scheduler

Enabled by default. It logs due reminders and updates `last_notified_at` in `recall_schedule`.

Config:
```
recall.reminders.enabled=true
recall.reminders.interval-ms=60000
recall.reminders.cooldown-seconds=3600
recall.reminders.batch-size=200
```
