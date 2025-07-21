# PostgreSQL example
docker run --rm --init `
  --name dbhub `
  --publish 8080:8080 `
  bytebase/dbhub `
  --transport http `
  --port 8080 `
  --dsn "postgres://julika_admin:3198692z@postgresql-julika.alwaysdata.net:5432/julika_test?sslmode=disable"