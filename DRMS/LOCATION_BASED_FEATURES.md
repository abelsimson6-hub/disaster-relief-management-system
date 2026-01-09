# Location-Based Features - Complete Guide

## 🎯 **Overview**

The system now uses location data for all users to enable smart matching and routing:
- **Victims** can make SOS requests to nearby volunteers
- **Resource requests** automatically go to nearest camp admin
- **Volunteers** can see nearby help requests
- **Location tracking** at registration and profile updates

---

## 📍 **Location Fields Added**

### **User Model**
- `current_location` - Address/description of location
- `latitude` - GPS latitude coordinate
- `longitude` - GPS longitude coordinate
- `location_updated_at` - Timestamp of last location update

### **HelpRequest Model**
- `latitude` - GPS latitude of request location
- `longitude` - GPS longitude of request location
- `assigned_volunteer` - Volunteer assigned to help

---

## 🔄 **Registration with Location**

### **Endpoint:** `POST /api/register/`

**Request Body:**
```json
{
    "username": "victim_user",
    "email": "victim@example.com",
    "password": "password123",
    "role": "victim",
    "current_location": "Thrissur, Kerala",
    "latitude": 10.5276,
    "longitude": 76.2144
}
```

**Response:**
```json
{
    "message": "User registered successfully",
    "user_id": 1,
    "location_saved": true,
    "nearest_camp": {
        "camp_id": 5,
        "camp_name": "Thrissur Relief Camp",
        "distance_km": null
    }
}
```

**Note:** For victims, the system automatically finds the nearest camp during registration.

---

## 🆘 **SOS Request Features**

### **1. Create SOS Request (Victim)**

**Endpoint:** `POST /api/help-requests/create/`

**Request Body:**
```json
{
    "disaster_id": 1,
    "description": "Need immediate medical help",
    "location": "Thrissur, Kerala",
    "latitude": 10.5276,
    "longitude": 76.2144
}
```

**Response:**
```json
{
    "message": "Help request created successfully",
    "help_request_id": 10,
    "requested_at": "2024-11-01T10:30:00Z",
    "nearby_volunteers": [
        {
            "id": 3,
            "user_id": 5,
            "username": "volunteer1",
            "distance_km": 2.5
        },
        {
            "id": 4,
            "user_id": 6,
            "username": "volunteer2",
            "distance_km": 5.8
        }
    ],
    "suggestion": "You can assign a volunteer from the nearby volunteers list"
}
```

**Features:**
- Automatically finds nearby volunteers within 50km
- Suggests closest available volunteers
- Uses victim's location if not provided in request

### **2. View Help Requests**

**Role-Based Views:**

**Victims:**
- See only their own requests
- `GET /api/help-requests/`

**Volunteers:**
- See requests assigned to them
- See nearby pending requests (within 50km)
- `GET /api/help-requests/`

**Super Admin:**
- See all requests
- `GET /api/help-requests/`

**Response includes:**
```json
{
    "help_requests": [
        {
            "id": 10,
            "victim": "victim_user",
            "description": "Need immediate medical help",
            "location": "Thrissur, Kerala",
            "latitude": 10.5276,
            "longitude": 76.2144,
            "assigned_volunteer_id": 5,
            "assigned_volunteer_username": "volunteer1",
            "status": "in_progress",
            "distance_km": 2.5
        }
    ]
}
```

### **3. Assign Volunteer to Help Request**

**Endpoint:** `POST /api/help-requests/{id}/assign-volunteer/`

**Option A: Manual Assignment**
```json
{
    "volunteer_id": 5,
    "auto_assign": false
}
```

**Option B: Auto-Assign Nearest Volunteer**
```json
{
    "auto_assign": true
}
```

**Response:**
```json
{
    "message": "Volunteer assigned successfully",
    "help_request_id": 10,
    "volunteer_id": 5,
    "volunteer_username": "volunteer1",
    "task_id": 15,
    "status": "in_progress"
}
```

### **4. Update Help Request Status (Volunteer)**

**Endpoint:** `PUT /api/help-requests/{id}/status/`

**Volunteers can update requests assigned to them:**
```json
{
    "status": "resolved",
    "note": "Provided medical assistance. Victim is safe now."
}
```

**Status Options:**
- `pending` - Initial status
- `in_progress` - Volunteer is helping
- `resolved` - Help completed
- `cancelled` - Request cancelled

**Permissions:**
- ✅ Volunteers can update requests assigned to them
- ✅ Super admin can update any request
- ✅ Camp admin can update any request

---

## 🏕️ **Resource Request Features**

### **Victims Can Request Resources**

**Endpoint:** `POST /api/resource-requests/create/`

**For Victims:**
```json
{
    "resource_id": 1,
    "quantity_requested": 50.0,
    "priority": "urgent",
    "needed_by": "2024-11-05T00:00:00Z",
    "reason": "Need food for family"
}
```

**Features:**
- Automatically finds nearest camp (within 100km)
- Request goes to that camp's admin
- No need to specify camp_id

**Response:**
```json
{
    "message": "Resource request created successfully",
    "request_id": 20,
    "camp_name": "Thrissur Relief Camp",
    "request_date": "2024-11-01T10:30:00Z"
}
```

**For Camp Admins:**
- Must specify `camp_id`
- Can only create for their own camp

**For Super Admins:**
- Must specify `camp_id`
- Can create for any camp

---

## 📍 **Update Location**

### **Update User Location**

**Endpoint:** `PUT /api/users/{id}/update/`

**Request Body:**
```json
{
    "current_location": "New Location, City",
    "latitude": 10.5276,
    "longitude": 76.2144
}
```

**Response:**
```json
{
    "message": "User profile updated successfully",
    "user_id": 1,
    "updated_at": "2024-11-01T10:30:00Z",
    "location_updated": true
}
```

---

## 🔍 **Location-Based Matching Logic**

### **Distance Calculation**
- Uses Haversine formula for accurate distance calculation
- Returns distance in kilometers
- Handles missing coordinates gracefully

### **Volunteer Matching**
- Searches within 50km radius by default
- Returns up to 10 nearest volunteers
- Sorted by distance (closest first)
- Only shows available volunteers

### **Camp Matching**
- Searches within 100km radius
- Only active camps
- Returns nearest camp

### **Camp Admin Matching**
- Finds nearest camp admin based on camp location
- Used for automatic resource request routing

---

## 📊 **Complete Workflow**

### **Victim Workflow:**
1. **Register** with location → System finds nearest camp
2. **Create SOS Request** → System finds nearby volunteers
3. **Admin assigns volunteer** → Volunteer gets notification
4. **Volunteer helps** → Updates status to "resolved"
5. **Create Resource Request** → Automatically goes to nearest camp admin

### **Volunteer Workflow:**
1. **Register** with location
2. **View nearby requests** → See pending requests within 50km
3. **Get assigned** → Admin assigns them to a request
4. **Help victim** → Update status as they work
5. **Mark resolved** → When help is complete

### **Camp Admin Workflow:**
1. **View resource requests** → See requests from victims in their area
2. **Approve/fulfill** → Manage resource distribution
3. **View help requests** → Monitor SOS requests in their region

### **Super Admin Workflow:**
1. **View all requests** → See everything
2. **Assign volunteers** → Manually or auto-assign
3. **Monitor system** → Track all activities

---

## 🎯 **Key Features Summary**

| Feature | Description | Who Can Use |
|---------|-------------|-------------|
| **Location Registration** | Capture location at signup | All roles |
| **SOS to Nearby Volunteers** | Auto-find nearby volunteers | Victims |
| **View Nearby Requests** | See requests within 50km | Volunteers |
| **Auto-Assign Volunteer** | System finds nearest volunteer | Super Admin |
| **Resource to Nearest Camp** | Auto-route to nearest camp | Victims |
| **Update Location** | Update current location | All roles |
| **Distance Display** | See distance to requests | Volunteers, Admins |

---

## 🔒 **Security & Permissions**

- ✅ Victims can only see their own requests
- ✅ Volunteers can see assigned + nearby requests
- ✅ Volunteers can only update assigned requests
- ✅ Camp admins see requests for their camp
- ✅ Super admin sees everything
- ✅ Location data is optional but recommended

---

## 📝 **Database Migration Required**

Run these migrations:
```bash
python manage.py makemigrations users
python manage.py makemigrations operations
python manage.py migrate
```

**New Fields:**
- User: `current_location`, `latitude`, `longitude`, `location_updated_at`
- HelpRequest: `latitude`, `longitude`, `assigned_volunteer`
- ResourceRequest: `requested_by` now allows victims

---

## 🚀 **API Endpoints Summary**

### **Registration & Location**
- `POST /api/register/` - Register with location
- `PUT /api/users/{id}/update/` - Update location

### **SOS Requests**
- `POST /api/help-requests/create/` - Create SOS (auto-finds volunteers)
- `GET /api/help-requests/` - List requests (role-based)
- `POST /api/help-requests/{id}/assign-volunteer/` - Assign volunteer
- `PUT /api/help-requests/{id}/status/` - Update status

### **Resource Requests**
- `POST /api/resource-requests/create/` - Create request (auto-routes to camp)

---

## ✅ **All Features Implemented!**

- ✅ Location capture at registration
- ✅ Location-based volunteer matching
- ✅ Location-based camp matching
- ✅ Auto-assignment of volunteers
- ✅ Auto-routing of resource requests
- ✅ Volunteer status updates
- ✅ Distance calculations
- ✅ Role-based request visibility

The system is now fully location-aware! 🎉

