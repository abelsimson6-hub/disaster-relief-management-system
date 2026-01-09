# Postman Setup Guide for DRMS API

## ⚠️ **IMPORTANT: Authentication Issue**

The views in individual apps (`communication`, `alerts`, `disasters`, etc.) currently use `@login_required` which is for **session-based authentication**. This **WON'T work with JWT tokens** in Postman.

## 🔧 **Solution Options**

### **Option 1: Use JWT Token Endpoints (Recommended)**

Use the existing DRF endpoints in `/api/` which already support JWT:

- `POST /api/token/` - Get JWT token
- `POST /api/token/refresh/` - Refresh token
- All ViewSet endpoints work with JWT

### **Option 2: Update Views to Support JWT**

The views need to be updated to use DRF decorators instead of `@login_required`.

**Current (Won't work with JWT):**
```python
@login_required
@require_http_methods(["GET"])
def list_messages(request):
    ...
```

**Should be (Works with JWT):**
```python
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_messages(request):
    ...
    return Response({'messages': message_list})
```

## 📋 **Working Endpoints (Already JWT-Compatible)**

These endpoints in `/api/` work with JWT tokens:

### **Authentication:**
- `POST /api/register/` - Register user
- `POST /api/login/` - Login (returns user info, not token)
- `POST /api/token/` - Get JWT access token ⭐
- `POST /api/token/refresh/` - Refresh JWT token

### **ViewSets (All support JWT):**
- `GET /api/volunteers/`
- `GET /api/disasters/`
- `GET /api/camps/`
- `GET /api/alerts/`
- `GET /api/resources/`
- `GET /api/resource-requests/`
- `GET /api/donations/`
- `GET /api/sos-requests/`
- `GET /api/tasks/`
- etc.

## 🚀 **How to Use in Postman**

### **Step 1: Get JWT Token**

**Request:**
```
POST http://localhost:8000/api/token/
Content-Type: application/json

{
    "username": "your_username",
    "password": "your_password"
}
```

**Response:**
```json
{
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

### **Step 2: Use Token in Requests**

**Option A: Bearer Token (Recommended)**
- In Postman, go to **Authorization** tab
- Select **Type: Bearer Token**
- Paste the `access` token

**Option B: Header**
- Add header: `Authorization: Bearer <your_access_token>`

### **Step 3: Make API Calls**

Example:
```
GET http://localhost:8000/api/disasters/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

## 📝 **Endpoints That Need Updates**

These endpoints in individual apps need to be updated to support JWT:

- `/api/messages/` (communication app)
- `/api/alerts/` (alerts app - custom views)
- `/api/disasters/` (disasters app - custom views)
- `/api/donations/` (operations app - custom views)
- `/api/resources/` (relief app - custom views)
- `/api/camps/` (shelters app - custom views)
- `/api/users/` (users app - custom views)

## ✅ **Quick Fix**

To make all endpoints work with JWT, you need to:

1. Replace `@login_required` with `@api_view(['GET'])` and `@permission_classes([IsAuthenticated])`
2. Replace `JsonResponse` with `Response` from DRF
3. Update imports

**Example transformation:**

**Before:**
```python
from django.http import JsonResponse
from django.contrib.auth.decorators import login_required

@login_required
@require_http_methods(["GET"])
def list_messages(request):
    ...
    return JsonResponse({'messages': message_list}, safe=False)
```

**After:**
```python
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_messages(request):
    ...
    return Response({'messages': message_list})
```

## 🎯 **Current Status**

- ✅ **DRF ViewSets** - Work with JWT (in `/api/`)
- ❌ **Custom views in apps** - Need updates for JWT support
- ✅ **Authentication endpoints** - Work (register, login, token)

## 💡 **Recommendation**

For now, use the DRF ViewSet endpoints which already work with JWT. The custom views in individual apps can be updated later if needed, or you can use the ViewSet endpoints which provide similar functionality.

