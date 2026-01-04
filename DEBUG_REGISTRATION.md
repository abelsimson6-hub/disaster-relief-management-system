# Debug Registration Issue - Step by Step Guide

## Step 1: Verify Django Server is Running

**Open a new terminal/command prompt and run:**

```bash
cd DRMS
python manage.py runserver
```

You should see:
```
Starting development server at http://127.0.0.1:8000/
Quit the server with CTRL-BREAK.
```

**If you see an error, fix it first before proceeding.**

---

## Step 2: Test the API Endpoint Directly

**Open your browser and go to:**
```
http://localhost:8000/api/test/
```

**You should see:**
```json
{"message": "API working!"}
```

**If this doesn't work:**
- The server is not running correctly
- Port 8000 is blocked or in use
- Try a different port: `python manage.py runserver 8001`

---

## Step 3: Test Registration Endpoint with Browser DevTools

1. **Open Flutter Web app in Chrome**
2. **Open Developer Tools** (F12 or Right-click → Inspect)
3. **Go to Network tab**
4. **Try to register a user**
5. **Check the Network tab:**
   - Look for a request to `http://localhost:8000/api/register/`
   - Click on it to see details
   - Check:
     - **Request URL**: Should be `http://localhost:8000/api/register/`
     - **Request Method**: Should be `POST`
     - **Status Code**: What is it? (200, 400, 500, or failed?)
     - **Response**: What does it say?

---

## Step 4: Common Issues and Solutions

### Issue A: "Failed to fetch" / No network request visible

**Cause**: Server is not running or not accessible

**Solution**: 
1. Make sure Django server is running (Step 1)
2. Check if you can access `http://localhost:8000/api/test/` in browser
3. If using a different port, update `api_service.dart` baseUrl

### Issue B: CORS error in browser console

**Cause**: CORS headers not being sent

**Solution**:
1. Check that `django-cors-headers` is installed: `pip install django-cors-headers`
2. Restart Django server after installing
3. Verify `corsheaders` is in `INSTALLED_APPS` in settings.py
4. Verify `corsheaders.middleware.CorsMiddleware` is in `MIDDLEWARE` (should be near the top)

### Issue C: 400 Bad Request

**Cause**: Invalid data being sent

**Check**:
- Browser Network tab → Request Payload
- Should have: `username`, `email`, `password`, `role`
- All fields should be non-empty strings

### Issue D: 500 Internal Server Error

**Cause**: Server-side error

**Check**:
- Django server terminal/console for error messages
- Look at the traceback to see what went wrong

---

## Step 5: Manual Test with curl (Alternative)

If you have curl installed, test the endpoint directly:

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

**Linux/Mac:**
```bash
curl -X POST http://localhost:8000/api/register/ \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"testpass123","role":"victim"}'
```

**Expected response:**
```json
{"message": "User registered successfully", "user_id": 1}
```

---

## Step 6: Check Flutter Console

**In Flutter, check the debug console for:**
1. Any error messages
2. The exact error string (not just "Failed to fetch")
3. Stack traces

**The error message should tell you:**
- Network error (server not running)
- CORS error (CORS configuration issue)
- 400/500 error (data or server problem)

---

## Quick Checklist

- [ ] Django server is running (`python manage.py runserver`)
- [ ] Can access `http://localhost:8000/api/test/` in browser
- [ ] Browser shows JSON: `{"message": "API working!"}`
- [ ] Flutter web app uses `http://localhost:8000/api` as base URL
- [ ] `django-cors-headers` is installed (`pip list | findstr cors`)
- [ ] Django server was restarted after any settings changes
- [ ] Checked browser Network tab for actual error
- [ ] Checked Django server console for error messages

---

## Still Not Working?

**Please provide:**
1. What error message you see (exact text)
2. Status code from browser Network tab (if visible)
3. Any errors in Django server console
4. Screenshot of browser Network tab showing the failed request

