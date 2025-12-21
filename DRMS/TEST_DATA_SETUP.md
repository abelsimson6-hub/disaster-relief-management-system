# Test Data Setup Guide

This guide explains how to set up initial/test data for the Disaster Relief Management System (DRMS) so that all team members can work with the same data.

## Problem

Since `db.sqlite3` is in `.gitignore` (which is correct practice), each developer has their own local database. Data added manually through Django Admin is not shared with teammates.

## Solution

We've created a Django management command `setup_test_data` that creates comprehensive test data that can be shared across all team members.

## Quick Start

### 1. Run Migrations (if not already done)

```bash
cd DRMS
python manage.py migrate
```

### 2. Create Test Data

```bash
python manage.py setup_test_data
```

This will create:
- **Users**: Super admin, camp admins, volunteers, victims, donors
- **Disasters**: Sample disasters (floods, earthquakes, fires)
- **Resources**: Food, water, medical supplies, shelter materials, etc.
- **Camps/Shelters**: Emergency shelters, medical camps, distribution centers
- **Donations**: Sample donation records
- **Alerts**: Disaster alerts and weather warnings
- **Transport**: Vehicles for resource transport
- **Help Requests**: SOS requests from victims
- **Task Assignments**: Volunteer task assignments

### 3. Clear and Recreate Data (Optional)

If you want to reset and recreate all test data:

```bash
python manage.py setup_test_data --clear
```

## Test User Accounts

The command creates the following test users (all with password: `password123`):

| Username | Role | Email | Purpose |
|----------|------|-------|---------|
| `admin` | Super Admin | admin@drms.local | Full system access |
| `campadmin1` | Camp Admin | campadmin1@drms.local | Manage camps/shelters |
| `volunteer1` | Volunteer | volunteer1@drms.local | Volunteer operations |
| `volunteer2` | Volunteer | volunteer2@drms.local | Volunteer operations |
| `victim1` | Victim | victim1@drms.local | Request help/SOS |
| `victim2` | Victim | victim2@drms.local | Request help/SOS |
| `donor1` | Donor | donor1@drms.local | Make donations |

## What Data Gets Created?

### Disasters (3)
- Coastal Flood 2024 (Active, High severity)
- Mountain Earthquake (Active, Critical severity)
- Urban Fire Incident (Contained, Medium severity)

### Resources (7 types)
- Rice (5000 kg)
- Bottled Water (10000 L)
- First Aid Kits (500 boxes)
- Blankets (2000 pieces)
- Tents (300 units)
- Hygiene Kits (1500 packs)
- Flashlights (800 pieces)

### Camps/Shelters (3)
- Emergency Shelter Alpha (Shelter, 500 capacity)
- Medical Camp Beta (Medical, 200 capacity)
- Distribution Center Gamma (Distribution, 1000 capacity)

### Additional Data
- Volunteer profiles with skills
- Victim profiles with priority levels
- Donations from organizations and individuals
- Weather alerts and disaster alerts
- Help requests from victims
- Task assignments for volunteers
- Transport vehicles

## For New Team Members

When a new team member clones the repository:

1. **Create and activate virtual environment:**
   ```bash
   python -m venv venv
   .\venv\Scripts\Activate.ps1  # Windows PowerShell
   # OR
   source venv/bin/activate  # Linux/Mac
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run migrations:**
   ```bash
   python manage.py migrate
   ```

4. **Create superuser (optional, admin user already created):**
   ```bash
   python manage.py createsuperuser
   ```

5. **Load test data:**
   ```bash
   python manage.py setup_test_data
   ```

6. **Run the server:**
   ```bash
   python manage.py runserver
   ```

7. **Access Django Admin:**
   - URL: http://127.0.0.1:8000/admin/
   - Login with: `admin` / `password123`

## Customizing Test Data

To customize the test data, edit:
```
DRMS/users/management/commands/setup_test_data.py
```

The file is well-commented and organized by data type. You can:
- Add more users
- Change disaster types and details
- Modify resource quantities
- Add more camps
- Customize any other data

After making changes, run with `--clear` flag to recreate:
```bash
python manage.py setup_test_data --clear
```

## Notes

- The command uses `get_or_create()` to avoid duplicates if run multiple times
- Use `--clear` flag to delete and recreate data
- The admin user is created only if it doesn't exist (won't overwrite existing admin)
- All test data follows the same relationships and constraints as production data
- Password for all test users is `password123` (change in production!)

## Integration with Flutter/Mobile App

After running `setup_test_data`, you can:
1. Start the Django server: `python manage.py runserver`
2. Test API endpoints with the test users
3. Use the test data to build and test your Flutter frontend

See `FLUTTER_INTEGRATION_GUIDE.md` for API integration details.

