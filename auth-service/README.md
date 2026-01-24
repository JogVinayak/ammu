# Auth Service

## Run
- Start local stack (Postgres + service): `docker compose up --build`
- If Postgres is already running, create DB/user: `docker exec -i auth-postgres psql -U postgres < scripts/create-auth-db.sql`
