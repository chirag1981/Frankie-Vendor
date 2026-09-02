---
description: Build Flask application from scratch with security hardening, bug-fix convergence loop, and stunning UI design system tokens.
---

────────────────────────────────────────
🧠 Core Execution Philosophy (Karpathy Principles)
────────────────────────────────────────

1. **Think Before Coding**: Never assume or hide ambiguity. State assumptions explicitly and propose options before modifying files.
2. **Simplicity First**: Write the minimum code required to solve the problem. Avoid premature abstractions, speculative features, or unrequested configurability.
3. **Surgical Precision**: Touch only the lines and files required for the task. Never refactor adjacent code, change styling arbitrarily, or strip unrelated comments.
4. **Read Before Writing**: Fully inspect existing utilities and patterns before writing new helpers to prevent duplication.
5. **Goal-Driven Verification**: Define success criteria upfront and verify with checks and tests before declaring completion.


# Build Flask App From Scratch (v2 — Security, Bug-Fix & Stunning-UI Edition)

## Description

A comprehensive, end-to-end workflow to design, build, secure, test, optimize, and document production-quality Python Flask applications with **visually distinctive, modern UI**.

This workflow follows the global Flask Application Standards throughout every phase. The standards define the required architecture, security, database management (including casing normalization), coding practices, UI/UX quality, accessibility, testing expectations, and project organization.

---

# Prerequisites

Before beginning development:
- Analyze the current workspace.
- Detect whether this is a new Flask project or an existing one.
- Reuse and extend existing code whenever practical instead of replacing it.
- Follow the Flask Application Standards during every phase.
- Ask no more than three clarification questions before creating the implementation plan.

---

# Phase 1. Requirements Analysis

Analyze project folder and ask up to three clarification questions covering:
- Main purpose of the application.
- User roles and authentication.
- Database requirements & fields requiring casing normalization.
- Preferred UI style, mood, or brand references.

After all questions are answered, summarize requirements, assumptions, and risks, and wait for confirmation.

---

# Phase 2. Architecture & Implementation Plan

Generate a complete implementation plan artifact covering:
- **Application Architecture**: Project structure, blueprints, Config hierarchy, logging strategy.
- **Database Design**: Models, relationships, constraints, indexes, and uppercase casing normalization strategy.
- **Forms**: Flask-WTF validation rules.
- **Routes**: Endpoints, methods, authentication, authorization, and rate-limits.
- **Templates**: Layouts, shared macros, dashboard, empty/loading/error states.
- **Security Checklist**: Hashing (bcrypt/argon2), CSRF, session hardening, CSP headers, SQL injection avoidance, file upload safety.

*Pause and wait for user approval before continuing to Phase 2A.*

---

# Phase 2A. Design System (Tokens & Theming)

Before writing templates, define the design system in `static/css/tokens.css`:
- **Visual concept & Typography**: pairing, type scale (12/14/16/20/24/32/40px).
- **Color palette**: neutral scale + accent colors as CSS variables (WCAG AA contrast verified).
- **Spacing scale**: 4px base (`--space-1` to `--space-12`).
- **Component language**: cards (`.c-card`), buttons, inputs (`.uppercase-input`), tables, modals.
- **Micro-interactions**: 150–250ms transitions respecting `prefers-reduced-motion`.

---

# Phase 3. Project Scaffolding

Generate structure:
```
app/
    __init__.py
    models.py
    forms.py
    routes/
    services.py
    utils.py
    decorators.py
templates/
static/
    css/tokens.css
    css/main.css
instance/
migrations/
tests/
requirements.txt
.env.example
.gitignore
README.md
run.py
```
Install dependencies and initialize Git.

---

# Phase 4. Database Development

Implement SQLAlchemy models, relationships, foreign keys, indexes, and constraints.
Initialize Flask-Migrate, create and apply initial migration.
Verify with parameterized queries only.

---

# Phase 5. Backend Development

Implement authentication, authorization, business logic, CRUD operations, uppercase sanitization, flash messaging, and error handlers.
Verify the server starts and routes respond cleanly.

---

# Phase 5A. Security Hardening Pass (Dedicated Gate)

- [ ] Zero raw string-concatenated SQL queries.
- [ ] Jinja autoescaping active (no unverified `|safe` or `Markup()`).
- [ ] Passwords hashed with bcrypt/argon2; login rate-limited.
- [ ] Cookies: `Secure`, `HttpOnly`, `SameSite=Lax`.
- [ ] Role and ownership authorization verified (IDOR prevention).
- [ ] Global `CSRFProtect` and Talisman security headers enabled.
- [ ] File uploads sanitized and restricted by extension/size.
- [ ] `.env` excluded from version control.

---

# Phase 6. Frontend Development

Build all views using the Phase 2A `tokens.css` design system:
- Base layout, navigation, responsive dashboard.
- Component macros (KPI stat cards, data tables, badges, modals).
- Form fields with `.uppercase-input` styles.
- Empty states, loading skeletons, and error pages.

---

# Phase 7. UI/UX Review

Verify typography scale, spacing rhythm, responsive layout across mobile/tablet/desktop breakpoints, form alignment, and WCAG AA contrast.

---

# Phase 8. Integration Testing

Test authentication, authorization, CRUD operations, CSV upload casing normalization, form validation edge cases, and database updates.

---

# Phase 8A. Bug-Fix Loop (Runs to Convergence)

1. **Collect**: Gather all test issues and console errors.
2. **Triage**: Critical (breaks core flow/security) → Major (wrong behavior/UX) → Minor (cosmetic).
3. **Fix Critical & Major first.**
4. **Re-test downstream flows** after every change.
5. **Repeat** until zero Critical/Major issues remain.

---

# Phase 9. Browser Verification

Run automated browser verification:
- Verify login, navigation, form submissions, search, and delete flows.
- Verify unauthorized routes are blocked per role.
- Confirm browser console has **zero errors**.

---

# Phase 10. Performance & Code Quality Review

Audit for dead code, unused imports, N+1 database queries, and unoptimized assets. Run `ruff` / `black` / `isort`.

---

# Phase 11. Documentation

Write complete `README.md` with setup steps, environment variables list, migration commands, and architecture diagrams.

---

# Phase 12. Final Validation Checklist

✓ Flask starts cleanly
✓ Database connects and migrations succeed
✓ Models and routes function as expected
✓ Casing normalization works for all identifiers
✓ Design system token consistency verified
✓ Zero security flaws open (Phase 5A)
✓ Bug-Fix Loop (Phase 8A) converged with zero critical bugs
✓ Zero browser console errors

---

# Phase 13. Production Readiness & Deployment

- Set `DEBUG=False`, strong production `SECRET_KEY`.
- Configure production WSGI server (Gunicorn).
- Enforce HTTPS and HSTS headers.
- Run `pip-audit` for dependency vulnerabilities.
