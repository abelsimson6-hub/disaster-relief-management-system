# Disaster Relief Management System (DRMS)

DRMS is a Django + Django REST Framework backend that coordinates end-to-end disaster response: user management, volunteer coordination, camp operations, resource inventory, SOS handling, transport logistics, and alerting. It exposes a fully documented REST API consumed by web/mobile clients (see `FLUTTER_INTEGRATION_GUIDE.md` for the companion Flutter app).

---

## Key Capabilities

- **Role-aware accounts**: custom `User` model with super admin, camp admin, volunteer, victim, and donor flows.
- **Operational data**: disasters, camps, alerts, weather alerts, communications, resources, inventory logs, donations, transports.
- **Workflow tracking**: SOS/help requests, volunteer task assignments, transport trips, and rich status/audit history for every critical record.
- **Analytics-ready**: admin dashboard endpoints summarize camps, resources, donations, alerts, and tasks in real time.

---

## Project Structure

| Path | Purpose |
| --- | --- |
| `DRMS/` | Django project config (`settings.py`, `urls.py`, `wsgi.py`). |
| `api/` | REST API viewsets, serializers, and routes mounted under `/api/`. |
| `users/`, `shelters/`, `relief/`, `operations/`, `disasters/`, `alerts/`, `communication/` | Domain apps with models, migrations, and admin integrations. |
| `manage.py` | Django management entry point. |
| `requirements.txt` | Python dependencies. |
| `FLUTTER_INTEGRATION_GUIDE.md` | Dedicated instructions for the Flutter front-end. |

---

## Prerequisites

- Python 3.12 (matching the bundled virtual environment)
- pip / venv
- SQLite (bundled by default)

Optional: Postman or curl for API testing, Flutter SDK for the client app.

---

## Quick Start

```bash
cd DRMS
python -m venv venv          # optional if you want a fresh environment
venv\Scripts\activate        # Windows PowerShell
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser  # follow prompts
python manage.py runserver
```

The API will be available at `http://127.0.0.1:8000/api/`. Django admin lives at `http://127.0.0.1:8000/admin/`.

> **⚠️ Important: Before Flutter Integration**  
> If you've just cloned/pulled this repo or made model changes, you **must** run migrations first:
> ```bash
> python manage.py makemigrations
> python manage.py migrate
> ```
> This ensures all new fields (inventory tracking, victim priority levels, transport trips, status history, geographic areas) are created in your database. The Flutter app expects these fields to exist.

> **Need Flutter?** After the backend is running and migrations are applied, follow `FLUTTER_INTEGRATION_GUIDE.md` to point the Flutter app at this API (includes auth, token refresh, and key workflows).

---

## Environment & Configuration

All core settings live in `DRMS/DRMS/settings.py`. Important toggles:

- `DEBUG`: leave `True` for local development; switch to `False` in production.
- `ALLOWED_HOSTS`: set to your domain/IP when deploying.
- `CORS_ALLOW_ALL_ORIGINS`: currently enabled for dev; limit it in production or supply explicit `CORS_ALLOWED_ORIGINS`.
- `DATABASES`: defaults to SQLite. Replace with Postgres/MySQL settings if needed.
- `AUTH_USER_MODEL = 'users.User'`: do not change without updating migrations.

---

## Core API Surface

All endpoints require JWT authentication unless otherwise noted. Obtain tokens via:

- `POST /api/register/` – create victim/volunteer/donor accounts.
- `POST /api/login/` – password auth (non-JWT convenience).
- `POST /api/token/` + `POST /api/token/refresh/` – obtain/refresh access tokens.

### Functional Groups

- **Users & Profiles**: `/api/volunteers/`, `/api/user/profile/`
- **Disasters & Camps**: `/api/disasters/`, `/api/camps/`
- **Alerts**: `/api/alerts/`, `/api/weather-alerts/`
- **Resources & Inventory**: `/api/resources/`, `/api/resource-requests/`, `/api/resource-inventory/`
- **Donations**: `/api/donations/` (+ `/acknowledge/` action)
- **SOS & Tasks**: `/api/sos-requests/`, `/api/tasks/`
- **Transport**: `/api/transports/`, `/api/transport-trips/`
- **Dashboards** (admin/camp admin only): `/api/admin/dashboard/`, `/api/admin/resource-analytics/`, `/api/admin/donation-matching/`, `/api/admin/volunteer-coordination/`
- **System Summary**: `/api/summary/` for a human-readable feature checklist.

Each viewset provides standard CRUD plus custom actions (e.g., `/pending/`, `/urgent/`, `/available/`, `/upcoming/`). Refer to `api/views.py` for full behavior.

---

## Database & Migrations

Run migrations after any model change:

```bash
python manage.py makemigrations
python manage.py migrate
```

SQLite DB file (`db.sqlite3`) is tracked locally. Back it up or switch to a production-grade database before deployment.

---

## Testing & Linting

```bash
python manage.py test
```

Add pytest/coverage or linting tools as needed. The repo currently relies on Django’s test runner and type-safe models/serializers.

---

## Deployment Notes

- Disable `DEBUG`, configure `ALLOWED_HOSTS`, and tighten CORS.
- Set up HTTPS termination (e.g., Nginx/Apache) and point Gunicorn/Uvicorn to `DRMS.wsgi`.
- Use environment variables or `.env` files for secrets (SECRET_KEY, database credentials, email/SMS providers).
- Schedule backups for the production database and media (if you add uploads).

---

## Flutter Integration

The backend is ready for direct consumption by the Flutter client. The dedicated guide covers:

- Configuring base URLs and JWT headers
- Auth/login/Register flows
- Resource request creation and analytics consumption
- SOS/task assignment UX
- Real-time dashboards

👉 See `FLUTTER_INTEGRATION_GUIDE.md` for detailed, copy/paste-ready snippets.

---

## Support & Next Steps

- Create initial super admin via `createsuperuser`, then assign camp admins/volunteers.
- Seed baseline data (disasters, camps, resources) through Django admin or fixtures.
- Hook up notification channels (SMS/email/push) by extending the `communication` app.

Feel free to open issues or extend the API for additional workflows. This README is intentionally concise; the Flutter guide contains app-specific steps, and the source files describe the rest. Enjoy building! 🎯

