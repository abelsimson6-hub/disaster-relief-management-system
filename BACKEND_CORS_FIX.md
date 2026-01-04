# Backend CORS Configuration - Flutter Web Fix

## Issue
Flutter Web shows "ClientException: Failed to fetch" when trying to register.

## Diagnosis

### 1. CORS Configuration Status ✅
The Django backend CORS configuration is **correctly set up**:
- `CORS_ALLOW_ALL_ORIGINS = True` - Allows all origins (including Flutter web on any port)
- `CORS_ALLOW_CREDENTIALS = True` - Allows credentials
- `CORS_ALLOW_HEADERS` includes all necessary headers (authorization, content-type, etc.)
- `CORS_ALLOW_METHODS` includes POST
- CORS middleware is properly positioned in MIDDLEWARE list

### 2. Register Endpoint Status ✅
The `/api/register/` endpoint:
- Exists at: `http://localhost:8000/api/register/`
- Accepts POST requests
- Uses `@csrf_exempt` decorator (bypasses CSRF for API)
- Returns proper JSON responses

## Common Causes & Solutions

### Cause 1: Django Server Not Running ❌
**Solution**: Start the Django development server:
```bash
cd DRMS
python manage.py runserver
```

The server should start on `http://127.0.0.1:8000/`

**Verify it's running**: Open `http://localhost:8000/api/test/` in your browser. You should see:
```json
{"message": "API working!"}
```

### Cause 2: Port Conflict ⚠️
**Solution**: If port 8000 is already in use:
```bash
python manage.py runserver 8001
```
Then update Flutter `api_service.dart` to use port 8001.

### Cause 3: Browser CORS Cache 🔄
**Solution**: Clear browser cache or use incognito/private mode.

### Cause 4: Network/Firewall 🔒
**Solution**: Ensure no firewall is blocking localhost:8000

## Testing the Register Endpoint

### Test 1: Using curl (Command Line)
```bash
curl -X POST http://localhost:8000/api/register/ \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"testpass123","role":"victim"}'
```

Expected response:
```json
{"message": "User registered successfully", "user_id": 1}
```

### Test 2: Using Browser Developer Tools
1. Open browser DevTools (F12)
2. Go to Network tab
3. Try registering from Flutter app
4. Check the request details:
   - Request URL should be: `http://localhost:8000/api/register/`
   - Request Method: POST
   - Request Headers should include: `Content-Type: application/json`
   - Response should show CORS headers: `Access-Control-Allow-Origin: *`

### Test 3: Direct Browser Test
You cannot test POST requests directly from browser address bar, but you can test GET endpoints:
- Open: `http://localhost:8000/api/test/`
- Should show: `{"message": "API working!"}`

## Verification Checklist

- [ ] Django server is running (`python manage.py runserver`)
- [ ] Server responds at `http://localhost:8000/api/test/`
- [ ] No port conflicts (port 8000 available)
- [ ] Browser can access `http://localhost:8000/api/test/`
- [ ] Flutter web app base URL is `http://localhost:8000/api`
- [ ] CORS middleware is in INSTALLED_APPS
- [ ] CORS middleware is early in MIDDLEWARE list
- [ ] `CORS_ALLOW_ALL_ORIGINS = True` in settings.py

## Current CORS Settings (settings.py)

```python
# CORS Configuration for Flutter/Mobile apps
CORS_ALLOW_ALL_ORIGINS = True  # ✅ Allows all origins
CORS_ALLOW_CREDENTIALS = True  # ✅ Allows credentials
CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]
CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]
```

These settings are **correct** for Flutter Web development.

## Next Steps

1. **Ensure Django server is running**: `cd DRMS && python manage.py runserver`
2. **Test the API endpoint**: Visit `http://localhost:8000/api/test/`
3. **Try registration again from Flutter Web**
4. **Check browser console** for any error messages
5. **Check Django server logs** for incoming requests

If the server is running and the test endpoint works, but registration still fails, check the browser's Network tab for the exact error message and response headers.

