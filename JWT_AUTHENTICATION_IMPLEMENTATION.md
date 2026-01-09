# JWT Authentication Implementation - Complete Guide

## Overview

This document describes the complete JWT-based authentication system implemented for the Disaster Relief Management System (Django REST Framework + Flutter).

## Backend Implementation (Django)

### 1. Django Settings (`DRMS/DRMS/settings.py`)

#### JWT Configuration
```python
from datetime import timedelta

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': False,
    'UPDATE_LAST_LOGIN': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'AUTH_HEADER_TYPES': ('Bearer',),
    'AUTH_HEADER_NAME': 'HTTP_AUTHORIZATION',
    'USER_ID_FIELD': 'id',
    'USER_ID_CLAIM': 'user_id',
    'AUTH_TOKEN_CLASSES': ('rest_framework_simplejwt.tokens.AccessToken',),
    'TOKEN_TYPE_CLAIM': 'token_type',
}
```

#### REST Framework Configuration
```python
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
}
```

#### CORS Configuration (Already Configured)
- `CORS_ALLOW_ALL_ORIGINS = True` (for development)
- `CORS_ALLOW_CREDENTIALS = True`
- All necessary headers and methods are allowed

### 2. Authentication Endpoints (`DRMS/api/views.py`)

#### Register Endpoint
**URL:** `POST /api/register/`
**Permission:** `AllowAny` (public)

**Request:**
```json
{
  "username": "testuser",
  "email": "test@example.com",
  "password": "securepassword123",
  "role": "victim"
}
```

**Response (201 Created):**
```json
{
  "message": "User registered successfully",
  "user_id": 1,
  "username": "testuser",
  "role": "victim",
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Error Response (400 Bad Request):**
```json
{
  "error": "Username already exists"
}
```

#### Login Endpoint (JWT Token)
**URL:** `POST /api/token/`
**Permission:** `AllowAny` (public)
**Uses:** `TokenObtainPairView` from SimpleJWT

**Request:**
```json
{
  "username": "testuser",
  "password": "securepassword123"
}
```

**Response (200 OK):**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Error Response (401 Unauthorized):**
```json
{
  "detail": "No active account found with the given credentials"
}
```

#### Token Refresh Endpoint
**URL:** `POST /api/token/refresh/`
**Permission:** `AllowAny` (public)
**Uses:** `TokenRefreshView` from SimpleJWT

**Request:**
```json
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

**Response (200 OK):**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

#### User Profile Endpoint
**URL:** `GET /api/user/profile/`
**Permission:** `IsAuthenticated` (requires JWT token)

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK) - Volunteer:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user": {
      "id": 1,
      "username": "volunteer1",
      "email": "vol@example.com",
      "role": "volunteer"
    },
    "availability": true,
    "experience": "5 years",
    "skills": []
  },
  "user": {
    "id": 1,
    "username": "volunteer1",
    "email": "vol@example.com",
    "role": "volunteer"
  },
  "role": "volunteer"
}
```

**Response (200 OK) - Donor/Admin:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "username": "donor1",
    "email": "donor@example.com",
    "role": "donor"
  },
  "user": {
    "id": 1,
    "username": "donor1",
    "email": "donor@example.com",
    "role": "donor"
  },
  "role": "donor"
}
```

### 3. Protected Endpoints

All viewsets are protected with `permission_classes = [permissions.IsAuthenticated]`:
- `/api/volunteers/`
- `/api/disasters/`
- `/api/camps/`
- `/api/alerts/`
- `/api/resources/`
- `/api/resource-requests/`
- `/api/donations/`
- `/api/sos-requests/`
- `/api/tasks/`
- `/api/transports/`
- All admin endpoints

### 4. Running Server on 0.0.0.0 for Mobile Access

**Script:** `DRMS/start_server.sh`

```bash
#!/bin/bash
cd "$(dirname "$0")"
python manage.py runserver 0.0.0.0:8000
```

**Usage:**
```bash
cd DRMS
chmod +x start_server.sh
./start_server.sh
```

This allows connections from mobile devices on the same network.

## Frontend Implementation (Flutter)

### 1. API Service (`lib/services/api_service.dart`)

#### Token Storage
- **Access Token:** Stored in SharedPreferences with key `access_token`
- **Refresh Token:** Stored in SharedPreferences with key `refresh_token`
- **User Info:** Stored with keys `user_id`, `username`, `user_role`

#### Base URL Configuration
- **Web/Desktop:** `http://localhost:8000/api`
- **Android Emulator:** `http://10.0.2.2:8000/api`
- **iOS Simulator:** `http://localhost:8000/api`

#### Automatic Token Refresh
The `authenticatedRequest` method automatically:
1. Attaches `Authorization: Bearer <access_token>` header
2. On 401 response, attempts to refresh the token
3. Retries the original request with the new token
4. If refresh fails, clears all tokens and throws exception

#### Login Method
```dart
static Future<Map<String, dynamic>> login(String username, String password)
```
- Calls `/api/token/` endpoint
- Saves access and refresh tokens
- Returns success/error map

#### Register Method
```dart
static Future<Map<String, dynamic>> register({
  required String username,
  required String email,
  required String password,
  required String role,
})
```
- Calls `/api/register/` endpoint
- If tokens are returned, saves them automatically
- Returns success/error map with tokens (if successful)

#### Get User Profile Method
```dart
static Future<Map<String, dynamic>> getUserProfile()
```
- Calls `/api/user/profile/` with authentication
- Returns profile data in consistent format

### 2. App State (`lib/app_state.dart`)

#### Login Flow
1. User enters username/password
2. `handleLogin()` calls `ApiService.login()`
3. If successful, fetches user profile
4. Extracts role from profile data
5. Saves user info (id, username, role)
6. Navigates to appropriate dashboard based on role

#### Registration Flow
1. User fills registration form
2. `ApiService.register()` is called
3. If tokens are returned, they're saved automatically
4. User profile is fetched
5. User is auto-logged in and navigated to dashboard
6. If no tokens, redirects to login screen

#### Role-Based Navigation
```dart
void navigateToDashboard(RoleType role) {
  switch (role) {
    case RoleType.victim:
      _setScreen(Screen.victimDashboard);
      break;
    case RoleType.donor:
      _setScreen(Screen.donorDashboard);
      break;
    case RoleType.volunteer:
      _setScreen(Screen.volunteerDashboard);
      break;
    case RoleType.admin:
      _setScreen(Screen.adminDashboard);
      break;
    case RoleType.campAdmin:
      _setScreen(Screen.campAdminDashboard);
      break;
  }
}
```

### 3. Data Fetching

All data fetching methods handle DRF pagination:
- Checks for `results` key in response (paginated)
- Falls back to direct list if not paginated
- Returns consistent `{'success': bool, 'data': List}` format

**Example:**
```dart
final disastersResult = await ApiService.getDisasters();
if (disastersResult['success'] == true) {
  final disasters = disastersResult['data'] ?? [];
  // Use disasters list in UI
}
```

## API Response Structure

### Paginated Responses (DRF Default)
```json
{
  "count": 100,
  "next": "http://localhost:8000/api/disasters/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Flood 2024",
      ...
    }
  ]
}
```

### Non-Paginated Responses
```json
[
  {
    "id": 1,
    "name": "Flood 2024",
    ...
  }
]
```

The Flutter ApiService automatically handles both formats and extracts the `results` array or uses the list directly.

## Testing

### Backend Testing

1. **Start Server:**
   ```bash
   cd DRMS
   python manage.py runserver 0.0.0.0:8000
   ```

2. **Test Registration:**
   ```bash
   curl -X POST http://localhost:8000/api/register/ \
     -H "Content-Type: application/json" \
     -d '{"username":"testuser","email":"test@example.com","password":"testpass123","role":"victim"}'
   ```

3. **Test Login:**
   ```bash
   curl -X POST http://localhost:8000/api/token/ \
     -H "Content-Type: application/json" \
     -d '{"username":"testuser","password":"testpass123"}'
   ```

4. **Test Protected Endpoint:**
   ```bash
   curl -X GET http://localhost:8000/api/user/profile/ \
     -H "Authorization: Bearer <access_token>"
   ```

### Flutter Testing

1. **Start Backend Server** (required)
2. **Run Flutter App:**
   ```bash
   flutter run -d chrome
   ```

3. **Test Registration:**
   - Open app
   - Navigate to register screen
   - Fill form and submit
   - Should auto-login and navigate to dashboard

4. **Test Login:**
   - Use registered credentials
   - Should navigate to appropriate dashboard

5. **Test Data Fetching:**
   - After login, dashboards should load real data from backend
   - Check for network errors in console

## Security Notes

1. **Development Settings:**
   - `DEBUG = True` should be `False` in production
   - `ALLOWED_HOSTS = ['*']` should be restricted in production
   - `CORS_ALLOW_ALL_ORIGINS = True` should be restricted in production

2. **Token Security:**
   - Tokens are stored in SharedPreferences (device storage)
   - For production, consider using Flutter Secure Storage
   - Tokens expire after 60 minutes (access) or 7 days (refresh)

3. **HTTPS:**
   - In production, use HTTPS for all API calls
   - Update `baseUrl` in ApiService to use `https://`

## Troubleshooting

### "Cannot connect to server"
- Ensure Django server is running
- Check base URL matches server address
- For mobile, ensure server is on `0.0.0.0:8000`

### "Authentication failed"
- Token may be expired, try logging in again
- Check if refresh token is valid
- Verify JWT configuration in settings.py

### "401 Unauthorized"
- Token refresh should happen automatically
- If persists, user needs to login again
- Check if token is being sent in Authorization header

### "Failed to parse response"
- Check API response format matches expected structure
- Verify serializers return correct format
- Check network tab in browser DevTools

## Summary

The JWT authentication system is fully implemented with:
- ✅ Django SimpleJWT configuration
- ✅ Register endpoint with token generation
- ✅ Login endpoint (token obtain)
- ✅ Token refresh endpoint
- ✅ Protected endpoints with IsAuthenticated
- ✅ Flutter token storage and management
- ✅ Automatic token refresh on 401
- ✅ Role-based navigation
- ✅ Data fetching with pagination support
- ✅ Server binding to 0.0.0.0 for mobile access

All endpoints are secured, tokens are properly managed, and the Flutter app correctly handles authentication and data fetching from the backend.

