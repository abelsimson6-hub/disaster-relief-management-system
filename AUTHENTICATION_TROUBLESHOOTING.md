# Authentication Troubleshooting Guide

## Quick Fix Checklist

If you're unable to login or register, follow these steps:

### 1. Check if Django Backend is Running ✅

**Most common issue**: The Django backend server is not running.

**Solution**: Open a terminal and run:
```bash
cd DRMS
python manage.py runserver
```

You should see:
```
Starting development server at http://127.0.0.1:8000/
Quit the server with CTRL-BREAK.
```

### 2. Test Backend Connection

Open your browser and go to:
```
http://localhost:8000/api/test/
```

You should see:
```json
{"message": "API working!"}
```

**If this doesn't work:**
- The server is not running or not accessible
- Port 8000 might be in use - try: `python manage.py runserver 8001`
- If using a different port, update `lib/src/services/api_service.dart` baseUrl

### 3. Check Error Messages in the App

The app now displays detailed error messages:

- **"Cannot connect to server"** → Backend is not running (see step 1)
- **"Connection timeout"** → Server is running but not responding quickly
- **"Invalid username or password"** → Wrong credentials
- **"Username already exists"** → Try a different username
- **"Email already exists"** → Try a different email

### 4. Common Issues

#### Issue A: "Cannot connect to server" Error
- **Cause**: Django server not running
- **Solution**: Run `python manage.py runserver` in the DRMS directory

#### Issue B: CORS Errors (Web Only)
- **Cause**: CORS headers not configured (usually not an issue, already configured)
- **Solution**: Backend already has CORS configured. If you see CORS errors, restart the Django server

#### Issue C: Port Already in Use
- **Cause**: Another process is using port 8000
- **Solution**: 
  ```bash
  # Use a different port
  python manage.py runserver 8001
  ```
  Then update `lib/src/services/api_service.dart` to use port 8001

#### Issue D: Invalid Credentials
- **Cause**: Wrong username/password
- **Solution**: Make sure you're using the correct credentials. Try registering a new user first.

### 5. Testing Registration Manually

If you want to test the backend directly, use curl:

**Mac/Linux:**
```bash
curl -X POST http://localhost:8000/api/register/ \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"testpass123","role":"victim"}'
```

**Windows PowerShell:**
```powershell
$body = @{
    username = "testuser"
    email = "test@example.com"
    password = "testpass123"
    role = "victim"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8000/api/register/" -Method POST -Body $body -ContentType "application/json"
```

Expected response:
```json
{"message": "User registered successfully", "user_id": 1}
```

### 6. What Was Fixed

The following improvements were made to help diagnose issues:

1. **Better Error Handling**: 
   - Connection errors are now properly caught and displayed
   - Timeout errors are handled (10 second timeout)
   - JSON parsing errors are handled gracefully

2. **Improved Error Messages**:
   - Clear messages that guide you to the solution
   - Server connection errors mention checking if backend is running
   - Detailed error messages from the server are displayed

3. **Network Error Detection**:
   - Distinguishes between connection errors and other network issues
   - Provides helpful suggestions based on error type

### 7. Still Having Issues?

1. **Check Django Server Logs**: Look at the terminal where you ran `runserver` for any error messages
2. **Check Browser Console** (for web): Open DevTools (F12) → Console tab
3. **Check Network Tab** (for web): Open DevTools (F12) → Network tab → Look for failed requests
4. **Verify Backend URL**: Check `lib/src/services/api_service.dart` → `baseUrl` matches your server URL

### 8. Platform-Specific Notes

- **Web**: Uses `http://localhost:8000/api`
- **Android Emulator**: Uses `http://10.0.2.2:8000/api` (special IP to access host's localhost)
- **iOS Simulator**: Uses `http://localhost:8000/api`
- **Desktop**: Uses `http://localhost:8000/api`

If you're running on Android emulator and backend is on your host machine, the Android emulator uses `10.0.2.2` instead of `localhost` to access the host machine's localhost.

## Quick Start Commands

```bash
# Terminal 1: Start Django Backend
cd DRMS
python manage.py runserver

# Terminal 2: Run Flutter App
flutter run
```

Make sure the backend is running BEFORE starting the Flutter app!

