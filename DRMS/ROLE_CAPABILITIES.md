# Disaster Relief Management System - Role Capabilities Guide

This document explains what each user role can do in the system, as if you're using the app.

---

## 🔴 **SUPER ADMIN** - System Administrator
**Manages the entire application and all operations**

### What Super Admin Can Do:

#### **1. User Management**
- ✅ View all users in the system
- ✅ Create, update, and manage any user account
- ✅ Change user roles (make someone a volunteer, victim, camp admin, etc.)
- ✅ Activate/deactivate user accounts
- ✅ Assign camp admins to specific camps
- ✅ View all user statistics

#### **2. Disaster Management**
- ✅ Create new disasters (earthquakes, floods, hurricanes, etc.)
- ✅ Update disaster information (status, severity, location)
- ✅ View all disasters and their details
- ✅ Mark disasters as active, contained, or resolved
- ✅ View disaster statistics and analytics

#### **3. Camp Management**
- ✅ Create new camps (shelter, medical, distribution, evacuation, rescue)
- ✅ Update any camp's information
- ✅ View all camps across all disasters
- ✅ Close or reopen camps
- ✅ View camp statistics and capacity reports

#### **4. Resource Management**
- ✅ Create new resources (food, water, medical supplies, etc.)
- ✅ Update resource information
- ✅ Adjust inventory quantities (add/remove resources)
- ✅ View all resources and inventory transactions
- ✅ View resource analytics

#### **5. Resource Requests**
- ✅ View all resource requests from all camps
- ✅ Approve or reject resource requests
- ✅ Fulfill resource requests
- ✅ Update request statuses
- ✅ View pending and urgent requests

#### **6. Alerts & Weather Alerts**
- ✅ Create alerts for disasters
- ✅ Create weather alerts (hurricanes, floods, storms, etc.)
- ✅ Update alert statuses
- ✅ View all alerts and weather alerts
- ✅ Mark alerts as resolved

#### **7. Donations**
- ✅ View all donations
- ✅ Acknowledge donations
- ✅ View donation matching suggestions

#### **8. Help Requests (SOS)**
- ✅ View all help requests from victims
- ✅ Update help request statuses
- ✅ Assign volunteers to help requests
- ✅ Mark requests as resolved

#### **9. Task Management**
- ✅ Create task assignments for volunteers
- ✅ View all tasks
- ✅ Update task statuses
- ✅ View volunteer coordination data

#### **10. Communication**
- ✅ Send messages to any user
- ✅ Send bulk messages to multiple users
- ✅ View all communications

#### **11. Transport**
- ✅ View all transport vehicles
- ✅ View transport trips
- ✅ Manage transport assignments

#### **12. Analytics & Reports**
- ✅ Access admin dashboard with full statistics
- ✅ View resource analytics
- ✅ View donation matching reports
- ✅ View volunteer coordination data
- ✅ View system-wide statistics

---

## 🟡 **CAMP ADMIN** - Camp Manager
**Manages operations for their assigned camp(s) only**

### What Camp Admin Can Do:

#### **1. Their Own Camp**
- ✅ View their assigned camp's details
- ✅ Update their camp's information (capacity, contact info, status)
- ✅ View camp statistics and resource requests
- ⚠️ **CANNOT** create new camps (only super admin can)
- ⚠️ **CANNOT** view or manage other camps

#### **2. Resource Requests (For Their Camp Only)**
- ✅ Create resource requests for their camp
- ✅ View resource requests for their camp only
- ✅ Update status of their camp's resource requests
- ✅ View pending and urgent requests for their camp
- ⚠️ **CANNOT** see resource requests from other camps
- ⚠️ **CANNOT** approve/fulfill requests (super admin does this)

#### **3. Resources**
- ✅ View all available resources
- ✅ View resource inventory
- ✅ View inventory transactions
- ⚠️ **CANNOT** create new resources
- ⚠️ **CANNOT** adjust inventory (super admin does this)

#### **4. Disasters**
- ✅ View all disasters
- ✅ View disaster details
- ⚠️ **CANNOT** create or update disasters

#### **5. Alerts**
- ✅ View all alerts
- ✅ View weather alerts
- ⚠️ **CANNOT** create alerts (super admin does this)

#### **6. Help Requests (SOS)**
- ✅ View all help requests
- ✅ Update help request statuses
- ✅ Assign volunteers to help requests
- ✅ Mark requests as resolved

#### **7. Task Management**
- ✅ Create task assignments for volunteers
- ✅ View all tasks
- ✅ Update task statuses

#### **8. Donations**
- ✅ View all donations
- ✅ Acknowledge donations

#### **9. Users**
- ✅ View all users
- ✅ View user profiles
- ⚠️ **CANNOT** change user roles
- ⚠️ **CANNOT** activate/deactivate users

#### **10. Communication**
- ✅ Send messages to any user
- ✅ Send bulk messages
- ✅ View all communications

#### **11. Analytics**
- ✅ Access admin dashboard (limited to their camp's data)
- ✅ View resource analytics (for their camp)
- ✅ View volunteer coordination data

---

## 🟢 **VOLUNTEER** - Relief Worker
**Helps with disaster relief operations**

### What Volunteer Can Do:

#### **1. Their Profile**
- ✅ View their own profile
- ✅ Create/update their volunteer profile
- ✅ Add/update their skills (medical, rescue, logistics, etc.)
- ✅ Set their availability status (available/unavailable)
- ✅ Update their experience information

#### **2. Tasks**
- ✅ View tasks assigned to them
- ✅ Update their task status (assigned → in_progress → completed)
- ✅ View task details
- ⚠️ **CANNOT** see tasks assigned to other volunteers
- ⚠️ **CANNOT** create tasks (admin does this)

#### **3. Disasters**
- ✅ View all disasters
- ✅ View disaster details
- ✅ View active disasters

#### **4. Camps**
- ✅ View all camps
- ✅ View camp details
- ✅ View active camps

#### **5. Resources**
- ✅ View available resources
- ✅ View resource inventory
- ⚠️ **CANNOT** create resources or adjust inventory

#### **6. Alerts**
- ✅ View all alerts
- ✅ View active alerts
- ✅ View critical alerts
- ✅ View weather alerts

#### **7. Help Requests**
- ✅ View help requests (SOS)
- ⚠️ **CANNOT** create help requests (only victims can)
- ⚠️ **CANNOT** update request statuses (admin does this)

#### **8. Communication**
- ✅ Send messages to other users
- ✅ View their conversations
- ✅ Mark messages as read
- ✅ View unread messages

#### **9. Transport**
- ✅ View available transports
- ✅ View transport trips
- ⚠️ **CANNOT** manage transports

---

## 🔵 **VICTIM** - Disaster Affected Person
**People affected by disasters who need help**

### What Victim Can Do:

#### **1. Their Profile**
- ✅ View their own profile
- ✅ Create/update their victim profile
- ✅ Update their information (age, family members, medical conditions)
- ✅ Set their priority level and special needs
- ✅ Update emergency contact information

#### **2. Help Requests (SOS)**
- ✅ Create help requests when they need assistance
- ✅ View their own help requests
- ✅ View status of their requests
- ⚠️ **CANNOT** see other victims' help requests
- ⚠️ **CANNOT** update request statuses (admin does this)

#### **3. Disasters**
- ✅ View all disasters
- ✅ View disaster details
- ✅ View active disasters

#### **4. Camps**
- ✅ View all camps
- ✅ View camp details
- ✅ View active camps (to find shelter)

#### **5. Alerts**
- ✅ View all alerts
- ✅ View active alerts
- ✅ View critical alerts
- ✅ View weather alerts (to stay informed)

#### **6. Resources**
- ✅ View available resources
- ⚠️ **CANNOT** create resource requests (camp admin does this)

#### **7. Communication**
- ✅ Send messages to other users (admins, volunteers)
- ✅ View their conversations
- ✅ Mark messages as read
- ✅ View unread messages

#### **8. Tasks**
- ⚠️ **CANNOT** view or manage tasks (volunteers do this)

---

## 🟣 **DONOR** - Contributor
**People/organizations donating resources**

### What Donor Can Do:

#### **1. Their Profile**
- ✅ View their own profile
- ✅ Update their profile information

#### **2. Donations**
- ✅ View their donations (if implemented)
- ⚠️ **CANNOT** create donations through views (typically done by admin)

#### **3. Disasters**
- ✅ View all disasters
- ✅ View disaster details

#### **4. Camps**
- ✅ View all camps
- ✅ View camp details

#### **5. Alerts**
- ✅ View alerts
- ✅ View weather alerts

#### **6. Communication**
- ✅ Send messages
- ✅ View conversations

---

## 📊 **Summary Table**

| Feature | Super Admin | Camp Admin | Volunteer | Victim | Donor |
|---------|------------|------------|-----------|--------|-------|
| **Create Disasters** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Create Camps** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Create Resources** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Create Resource Requests** | ✅ | ✅ (own camp) | ❌ | ❌ | ❌ |
| **Approve Resource Requests** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Create Alerts** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Create Help Requests** | ❌ | ❌ | ❌ | ✅ | ❌ |
| **Assign Tasks** | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Update Own Tasks** | ❌ | ❌ | ✅ | ❌ | ❌ |
| **View All Users** | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Manage User Roles** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **View All Camps** | ✅ | ✅ (own camp) | ✅ | ✅ | ✅ |
| **View All Disasters** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Send Messages** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **View Analytics** | ✅ (all) | ✅ (own camp) | ❌ | ❌ | ❌ |

---

## 🔒 **Key Security Points**

1. **Camp Admin Restrictions:**
   - Can only see and manage their assigned camp
   - Cannot create new camps
   - Cannot see other camps' resource requests
   - Cannot approve/fulfill resource requests (super admin does this)

2. **Volunteer Restrictions:**
   - Can only see and update their own tasks
   - Cannot create tasks or help requests
   - Cannot manage resources or camps

3. **Victim Restrictions:**
   - Can only see their own help requests
   - Cannot create resource requests
   - Cannot manage any system operations

4. **Super Admin:**
   - Has full access to everything
   - Only role that can create camps and disasters
   - Only role that can change user roles
   - Only role that can approve/fulfill resource requests

---

## 🎯 **Typical Workflows**

### **Super Admin Workflow:**
1. Create disaster → Create camps → Assign camp admins
2. Create resources → Manage inventory
3. Review resource requests → Approve/fulfill requests
4. Monitor help requests → Assign volunteers
5. View analytics and reports

### **Camp Admin Workflow:**
1. View their camp details
2. Create resource requests for their camp
3. Monitor help requests → Assign volunteers
4. Create tasks for volunteers
5. View their camp's statistics

### **Volunteer Workflow:**
1. Update profile and skills
2. View assigned tasks → Update task status
3. View help requests they're assigned to
4. Communicate with admins and victims

### **Victim Workflow:**
1. Create help request when in need
2. View status of their requests
3. View available camps and resources
4. Communicate with admins/volunteers
5. Stay informed via alerts

---

## 📊 **REQUEST FLOW SUMMARY TABLE**

This table shows what happens when each role makes a request, who receives it, and who can accept/resolve it.

| **Role** | **Request Type** | **Who Receives It** | **Who Can Accept/Resolve** | **Status Flow** |
|----------|------------------|---------------------|---------------------------|-----------------|
| **Victim** | SOS Help Request | • Nearby Volunteers (auto-suggested)<br>• Super Admin (can view all) | • Super Admin (assigns volunteer)<br>• Assigned Volunteer (updates status) | `pending` → `in_progress` → `resolved` |
| **Victim** | Resource Request (food, water, etc.) | • Nearest Camp Admin (auto-assigned based on location) | • Camp Admin (approves/rejects/fulfills)<br>• Super Admin (can override) | `pending` → `approved` → `fulfilled` |
| **Donor** | Donation to Camp | • Camp Admin of selected camp | • Camp Admin (accepts/rejects)<br>• Super Admin (can override) | `pending` → `accepted` → (acknowledgment sent) |
| **Camp Admin** | Resource Request for their camp | • Super Admin (can view all)<br>• Themselves (for their own camp) | • Super Admin (approves/fulfills)<br>• Themselves (for their own camp) | `pending` → `approved` → `fulfilled` |
| **Volunteer** | Task Assignment | • Themselves (assigned tasks)<br>• Super Admin (assigns tasks) | • Themselves (updates status)<br>• Super Admin (can update) | `assigned` → `in_progress` → `completed` |
| **Super Admin** | Any Request | • Themselves (creates/manages all) | • Themselves (full control) | All statuses |

### **Detailed Request Flows:**

#### **1. Victim SOS Request Flow:**
```
Victim creates SOS request
    ↓
System finds nearby volunteers (within 50km)
    ↓
Request visible to:
    • Super Admin (all requests)
    • Nearby Volunteers (pending requests)
    ↓
Super Admin assigns volunteer OR volunteer self-assigns
    ↓
Volunteer updates status: pending → in_progress → resolved
    ↓
Super Admin and other volunteers see it's resolved
```

#### **2. Victim Resource Request Flow:**
```
Victim creates resource request (food, water, etc.)
    ↓
System finds nearest camp (within 100km) based on victim's location
    ↓
Request sent to Camp Admin of nearest camp
    ↓
Camp Admin sees request in their dashboard
    ↓
Camp Admin: approves → fulfills → updates inventory
    ↓
Victim sees status update
```

#### **3. Donor Donation Flow:**
```
Donor searches camps by location (e.g., "Thrissur")
    ↓
Donor views camp requirements
    ↓
Donor creates donation to specific camp
    ↓
Donation sent to Camp Admin of that camp (status: pending)
    ↓
Camp Admin reviews donation
    ↓
Camp Admin: accepts → updates inventory → sends acknowledgment
    OR
Camp Admin: rejects → donation status updated
    ↓
Donor receives acknowledgment
```

### **Permission Matrix:**

| **Action** | **Super Admin** | **Camp Admin** | **Volunteer** | **Victim** | **Donor** |
|------------|----------------|----------------|---------------|------------|-----------|
| Create SOS Request | ❌ | ❌ | ❌ | ✅ | ❌ |
| View SOS Requests | ✅ (all) | ❌ | ✅ (nearby + assigned) | ✅ (own only) | ❌ |
| Resolve SOS Request | ✅ | ❌ | ✅ (assigned only) | ❌ | ❌ |
| Create Resource Request | ✅ | ✅ (own camp) | ❌ | ✅ (auto-routed) | ❌ |
| View Resource Requests | ✅ (all) | ✅ (own camp) | ❌ | ✅ (own only) | ❌ |
| Resolve Resource Request | ✅ | ✅ (own camp) | ❌ | ❌ | ❌ |
| Create Donation | ❌ | ❌ | ❌ | ❌ | ✅ |
| View Donations | ✅ (all) | ✅ (own camp) | ❌ | ❌ | ✅ (own only) |
| Accept Donation | ✅ | ✅ (own camp) | ❌ | ❌ | ❌ |
| Create Task | ✅ | ✅ (own camp) | ❌ | ❌ | ❌ |
| View Tasks | ✅ (all) | ✅ (own camp) | ✅ (own only) | ❌ | ❌ |
| Update Task Status | ✅ | ✅ (own camp) | ✅ (own only) | ❌ | ❌ |

---

This system ensures proper role separation and security while allowing efficient disaster relief management! 🚨

