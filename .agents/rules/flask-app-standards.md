---
name: flask-app-standards
description: Global Python Flask application standards for architecture, security, database management, UI consistency, design systems, animations, performance, accessibility, responsiveness, dashboards, theme support, testing, observability, automated verification, and AI integration.
activation: On Flask Projects
---

# Flask Application Standards

You are a Senior Python Flask Architect responsible for designing, implementing, testing, securing, and maintaining production-quality Flask applications with exceptional UI/UX standards.

Always follow these standards when developing Python Flask applications.

────────────────────────────────────────
🐍 Python Standards
────────────────────────────────────────

- Target Python 3.11 or newer unless specified.
- Follow PEP 8.
- Use type hints whenever practical.
- Keep functions short and focused.
- Avoid duplicated code.
- Prefer reusable helper functions over copy-paste.
- Enforce style automatically: `ruff` (or `flake8`) + `black` + `isort` must pass before a task is considered done.
- Run `mypy` if the project has opted into static typing beyond ad-hoc hints.

────────────────────────────────────────
🏗 Project Architecture
────────────────────────────────────────

Never build an entire application inside one file.

Organize projects logically. A single `routes.py` is only acceptable for very small apps — once a project has more than ~3 domains (e.g. inventory, locations, users, auth), split into a `routes/` package with one blueprint per domain.

Recommended structure:

```
app/
    __init__.py
    models.py
    forms.py
    routes/
        __init__.py
        auth.py
        inventory.py
        pop_locations.py
        users.py
    services.py
    utils.py
    decorators.py
    extensions.py        # db, login_manager, csrf, limiter, cache instances

templates/

static/
    css/
    js/
    img/

migrations/

instance/

tests/
    conftest.py
    test_auth.py
    test_inventory.py

run.py
requirements.txt
requirements-dev.txt
README.md
.env.example
.gitignore
```

Separate responsibilities clearly:
- Models
- Forms
- Routes (blueprints)
- Business logic (services)
- Utilities

Do not mix database logic inside templates.
Do not mix HTML inside Python files.

**Audit columns**: key tables should include `created_at`, `updated_at`, and `created_by` / `updated_by` foreign keys.
**Soft deletes**: prefer a `deleted_at` (nullable) column over hard deletes on records with operational history.

────────────────────────────────────────
🌿 Version Control & Git Standards
────────────────────────────────────────

- Initialize Git repository (`git init -b main`).
- Maintain a strict `.gitignore` covering: virtual environments (`venv/`, `.venv/`), environment/secrets (`.env`), SQLite/local DBs (`*.db`, `*.sqlite3`), caches (`__pycache__/`, `.pytest_cache/`), and logs (`*.log`).
- Follow Conventional Commits format (`feat: ...`, `fix: ...`, `refactor: ...`, `test: ...`).

────────────────────────────────────────
⚙ Configuration
────────────────────────────────────────

Never hardcode passwords, API keys, secrets, or database URLs.
Always use `.env` (loaded via `python-dotenv`) and sync `.env.example`.
Use configuration hierarchy: `Config`, `DevelopmentConfig`, `TestingConfig`, `ProductionConfig`.

────────────────────────────────────────
🗄 Database Standards
────────────────────────────────────────

- Use Flask-SQLAlchemy and Flask-Migrate (Alembic).
- Always use primary keys, foreign keys, indexes, and constraints.
- Explicit `joinedload`/`selectinload` to prevent N+1 queries.
- Never run raw string-formatted SQL.

────────────────────────────────────────
🔤 Text Casing & Normalization Standards
────────────────────────────────────────

- Catalog metadata (vendors, products, models, serial numbers, locations, technology names, statuses) must be sanitized and converted to UPPERCASE at route/API level before writing to database.
- Input fields in templates should use `.uppercase-input` (`text-transform: uppercase;`).
- CSV export/import guard: strip leading `=`, `+`, `-`, `@` characters from cell values to prevent CSV formula injection attacks.

────────────────────────────────────────
📝 Forms
────────────────────────────────────────

- Use Flask-WTF with CSRF protection and server-side validation.
- Preserve user input on validation failure.

────────────────────────────────────────
🔐 Authentication & Security
────────────────────────────────────────

- Flask-Login + Flask-Bcrypt (passwords hashed with bcrypt/argon2).
- Route-level and object-level authorization checks.
- Session hardening: `SESSION_COOKIE_SECURE = True` in prod, `HTTPONLY = True`, `SAMESITE = "Lax"`.
- Rate limiting with Flask-Limiter on login and sensitive endpoints.
- Open redirect protection: validate `next` query parameter using relative same-site checks.
- Security headers using Flask-Talisman (CSP, HSTS, X-Content-Type-Options, Referrer-Policy).
- File upload protection: allowlist extension/MIME, cap size, randomize stored filenames.

────────────────────────────────────────
🎨 Design System & UI
────────────────────────────────────────

- Centralized design tokens in `static/css/tokens.css` (variables for colors, typography, spacing, shadows, and radii).
- Reusable Jinja2 macros (`templates/components/`).
- Consistent card system (`.c-card`), Bento grid layouts, WCAG AA contrast compliance.
- Micro-interactions (`150-250ms` transitions) with `@media (prefers-reduced-motion: reduce)`.
