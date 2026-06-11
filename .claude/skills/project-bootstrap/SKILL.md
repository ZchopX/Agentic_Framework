---
name: project-bootstrap
description: Initialize this project locally with repeatable setup and verification steps. Use when the user asks to bootstrap the development environment.
---

# Project Bootstrap

## Goal
Set up local development environment and verify core services.

## Steps
1. Create environment file:
   - `cp .env.example .env`
2. Install dependencies:
   - `uv sync`
3. Start database service:
   - `docker-compose up -d db`
4. Apply migrations:
   - `uv run alembic upgrade head`
5. Start app:
   - `uv run uvicorn app.main:app --reload --port 8123`
6. Verify health endpoints:
   - `curl -s http://localhost:8123/health`
   - `curl -s http://localhost:8123/health/db`

## Expected Access Points
- Swagger UI: `http://localhost:8123/docs`
- Health: `http://localhost:8123/health`
- Database: `localhost:5433`

## Guardrails
- If prerequisites are missing (`uv`, Docker, migrations), report blocker and remediation.
- Confirm command outcomes with explicit pass or fail status.

