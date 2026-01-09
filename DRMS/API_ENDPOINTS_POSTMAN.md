# Complete API Endpoints for Postman

## 🔑 **Authentication (Works with Postman)**

### **1. Get JWT Token**
```
POST http://localhost:8000/api/token/
Content-Type: application/json

{
    "username": "admin",
    "password": "password123"
}
```

**Response:**
```json
{
    "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

### **2. Register User**
```
POST http://localhost:8000/api/register/
Content-Type: application/json

{
    "username": "newuser",
    "email": "user@example.com",
    "password": "password123",
    "role": "donor"
}
```

### **3. Login (Session-based, returns user info)**
```
POST http://localhost:8000/api/login/
Content-Type: application/json

{
    "username": "admin",
    "password": "password123"
}
```

---

## ✅ **Working Endpoints (JWT-Compatible)**

All these endpoints work with JWT tokens in Postman. Add this header:
```
Authorization: Bearer <your_access_token>
```

### **Disasters**
- `GET /api/disasters/` - List all disasters
- `POST /api/disasters/` - Create disaster
- `GET /api/disasters/{id}/` - Get disaster details
- `GET /api/disasters/active/` - Get active disasters

### **Camps**
- `GET /api/camps/` - List all camps
- `POST /api/camps/` - Create camp
- `GET /api/camps/{id}/` - Get camp details
- `GET /api/camps/active/` - Get active camps

### **Alerts**
- `GET /api/alerts/` - List all alerts
- `POST /api/alerts/` - Create alert
- `GET /api/alerts/active/` - Get active alerts
- `GET /api/alerts/critical/` - Get critical alerts

### **Weather Alerts**
- `GET /api/weather-alerts/` - List weather alerts
- `POST /api/weather-alerts/` - Create weather alert
- `GET /api/weather-alerts/active/` - Get active weather alerts
- `GET /api/weather-alerts/high_risk/` - Get high risk alerts

### **Resources**
- `GET /api/resources/` - List all resources
- `POST /api/resources/` - Create resource
- `GET /api/resources/{id}/` - Get resource details
- `GET /api/resources/active/` - Get active resources

### **Resource Requests**
- `GET /api/resource-requests/` - List resource requests
- `POST /api/resource-requests/` - Create resource request
- `GET /api/resource-requests/pending/` - Get pending requests
- `GET /api/resource-requests/urgent/` - Get urgent requests

### **Donations**
- `GET /api/donations/` - List donations
- `POST /api/donations/` - Create donation
- `GET /api/donations/{id}/` - Get donation details
- `POST /api/donations/{id}/acknowledge/` - Acknowledge donation

### **Help Requests (SOS)**
- `GET /api/sos-requests/` - List help requests
- `POST /api/sos-requests/` - Create help request
- `GET /api/sos-requests/pending/` - Get pending requests
- `POST /api/sos-requests/{id}/assign_volunteer/` - Assign volunteer

### **Tasks**
- `GET /api/tasks/` - List tasks
- `POST /api/tasks/` - Create task
- `GET /api/tasks/my_tasks/` - Get my tasks (for volunteers)

### **Volunteers**
- `GET /api/volunteers/` - List volunteers
- `POST /api/volunteers/` - Create volunteer profile
- `GET /api/volunteers/available/` - Get available volunteers

### **Transports**
- `GET /api/transports/` - List transports
- `GET /api/transports/available/` - Get available transports
- `GET /api/transport-trips/` - List transport trips
- `GET /api/transport-trips/upcoming/` - Get upcoming trips

### **Admin Dashboard**
- `GET /api/admin/dashboard/` - Admin dashboard stats
- `GET /api/admin/resource-analytics/` - Resource analytics
- `GET /api/admin/donation-matching/` - Donation matching
- `GET /api/admin/volunteer-coordination/` - Volunteer coordination

### **User Profile**
- `GET /api/user/profile/` - Get current user profile

---

## ⚠️ **Endpoints That Need JWT Support Update**

These endpoints are created but use `@login_required` which won't work with JWT tokens. They need to be updated:

### **Communication**
- `/api/messages/` - List messages
- `/api/messages/send/` - Send message
- `/api/messages/{id}/` - Get message

### **Custom Views in Apps**
The custom views in individual apps need DRF decorators to work with JWT. See `POSTMAN_SETUP.md` for details.

---

## 📋 **Postman Collection Setup**

### **1. Create Environment Variables**
- `base_url`: `http://localhost:8000`
- `access_token`: (will be set after login)

### **2. Pre-request Script (for token refresh)**
```javascript
// Auto-refresh token if expired
if (pm.environment.get("access_token")) {
    // Add token refresh logic if needed
}
```

### **3. Collection-Level Authorization**
Set Bearer Token at collection level:
- Type: Bearer Token
- Token: `{{access_token}}`

---

## 🧪 **Testing in Postman**

### **Step 1: Get Token**
1. Create request: `POST {{base_url}}/api/token/`
2. Body: `{"username": "admin", "password": "password123"}`
3. Save `access` token to environment variable

### **Step 2: Use Token**
1. Set collection authorization to Bearer Token
2. Use `{{access_token}}` variable
3. All requests will automatically include the token

### **Step 3: Test Endpoints**
Example:
```
GET {{base_url}}/api/disasters/
Authorization: Bearer {{access_token}}
```

---

## 🔍 **Troubleshooting**

### **401 Unauthorized**
- Token expired → Get new token from `/api/token/`
- Token not included → Check Authorization header

### **403 Forbidden**
- Wrong role → Check user role matches endpoint requirements
- Not authenticated → Ensure token is valid

### **404 Not Found**
- Check URL path
- Ensure server is running
- Check URL patterns in `urls.py`

---

## ✅ **Summary**

**Working Now:**
- All DRF ViewSet endpoints (`/api/disasters/`, `/api/camps/`, etc.)
- JWT authentication endpoints
- Admin dashboard endpoints

**Needs Update:**
- Custom views in individual apps (communication, alerts, disasters, etc.)
- These use `@login_required` instead of DRF decorators

**Recommendation:**
Use the DRF ViewSet endpoints which already work perfectly with JWT tokens in Postman!

