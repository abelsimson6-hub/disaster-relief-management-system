# Quick Start Guide - Test Data Setup

## ✅ Yes, this is the data setup you need!

This replaces manual data entry and makes it shareable with your team.

---

## 🔄 How It Works

### Step 1: Commit the Command (Not the Data)
- ✅ **Commit**: The `setup_test_data.py` file (the command code)
- ❌ **Don't commit**: `db.sqlite3` (database file - stays in .gitignore)

### Step 2: Run the Command
After you or your teammates run:
```bash
python manage.py setup_test_data
```

The command **creates the data in your local database** (not in git).

---

## 👀 View Data in Django Admin

### 1. Start the Server
```bash
python manage.py runserver
```

### 2. Open Django Admin
Go to: **http://127.0.0.1:8000/admin/**

### 3. Login
- Username: `admin`
- Password: `password123`

### 4. You'll See All The Data!

**Users Section:**
- Users (admin, campadmin1, volunteer1, volunteer2, victim1, victim2, donor1)
- Volunteers
- Victims
- Camp Admins

**Disasters Section:**
- Disasters (Coastal Flood, Mountain Earthquake, Urban Fire)

**Relief Section:**
- Resources (Rice, Water, Medical Supplies, etc.)
- Resource Requests

**Shelters Section:**
- Camps (Emergency Shelter Alpha, Medical Camp Beta, etc.)

**Operations Section:**
- Donations
- Transport
- Help Requests
- Task Assignments

**Alerts Section:**
- Alerts
- Weather Alerts

---

## 📋 Summary

| What | Status |
|------|--------|
| Is this the data setup? | ✅ YES - This is it! |
| Commit the command code? | ✅ YES - Commit `setup_test_data.py` |
| Commit the database? | ❌ NO - `db.sqlite3` stays in .gitignore |
| Data visible in Admin? | ✅ YES - After running the command |
| Team can use it? | ✅ YES - They run the same command |

---

## 🚀 For Your Team

When teammates clone your repo:
1. `pip install -r requirements.txt`
2. `python manage.py migrate`
3. `python manage.py setup_test_data` ← **This creates the data in their database**
4. `python manage.py runserver`
5. Login to admin with `admin` / `password123`

Everyone will see the same test data in their Django admin! 🎉

