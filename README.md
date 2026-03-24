# Docker Setup

This project runs three services with Docker Compose:

- `backend`: FastAPI app on `http://localhost:8000`
- `frontend`: Flutter web app served by Nginx on `http://localhost:8080`
- `db`: PostgreSQL on `localhost:5432`

## Project Structure

```text
backend/
  app/
  requirements.txt
  Dockerfile
frontend/
  web/
  Dockerfile
docker-compose.yml
README.md
```

## Run

```bash
docker compose up --build
```

## Stop

```bash
docker compose down
```

## Stop and remove DB volume

```bash
docker compose down -v
```
