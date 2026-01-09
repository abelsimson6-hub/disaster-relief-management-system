# Request Flow Summary Table

## Complete Request Flow for All Roles

This table shows what happens when each role makes a request, who receives it, and who can accept/resolve it.

| **Role** | **Request Type** | **Who Receives It** | **Who Can Accept/Resolve** | **Status Flow** |
|----------|------------------|---------------------|---------------------------|-----------------|
| **Victim** | SOS Help Request | • Nearby Volunteers (auto-suggested)<br>• Super Admin (can view all) | • Super Admin (assigns volunteer)<br>• Assigned Volunteer (updates status) | `pending` → `in_progress` → `resolved` |
| **Victim** | Resource Request (food, water, etc.) | • Nearest Camp Admin (auto-assigned based on location) | • Camp Admin (approves/rejects/fulfills)<br>• Super Admin (can override) | `pending` → `approved` → `fulfilled` |
| **Donor** | Donation to Camp | • Camp Admin of selected camp | • Camp Admin (accepts/rejects)<br>• Super Admin (can override) | `pending` → `accepted` → (acknowledgment sent) |
| **Camp Admin** | Resource Request for their camp | • Super Admin (can view all)<br>• Themselves (for their own camp) | • Super Admin (approves/fulfills)<br>• Themselves (for their own camp) | `pending` → `approved` → `fulfilled` |
| **Volunteer** | Task Assignment | • Themselves (assigned tasks)<br>• Super Admin (assigns tasks) | • Themselves (updates status)<br>• Super Admin (can update) | `assigned` → `in_progress` → `completed` |
| **Super Admin** | Any Request | • Themselves (creates/manages all) | • Themselves (full control) | All statuses |

---

## Detailed Request Flows

### 1. **Victim SOS Request Flow**

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

**Who can see it:**
- ✅ Super Admin: All requests
- ✅ Volunteers: Nearby pending requests + their assigned requests
- ✅ Victim: Only their own requests

**Who can resolve it:**
- ✅ Super Admin: Can assign volunteer and update status
- ✅ Assigned Volunteer: Can update status to resolved
- ❌ Camp Admin: Cannot manage SOS requests
- ❌ Other Volunteers: Cannot update unless assigned

---

### 2. **Victim Resource Request Flow**

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

**Who can see it:**
- ✅ Camp Admin: Requests for their camp only
- ✅ Super Admin: All requests
- ✅ Victim: Only their own requests

**Who can resolve it:**
- ✅ Camp Admin: Approves/rejects/fulfills requests for their camp
- ✅ Super Admin: Can override and fulfill any request
- ❌ Volunteers: Cannot manage resource requests
- ❌ Donors: Cannot see resource requests

---

### 3. **Donor Donation Flow**

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

**Who can see it:**
- ✅ Donor: All their own donations
- ✅ Camp Admin: Donations for their camp only
- ✅ Super Admin: All donations

**Who can resolve it:**
- ✅ Camp Admin: Accepts/rejects donations for their camp
- ✅ Super Admin: Can override and accept any donation
- ❌ Volunteers: Cannot manage donations
- ❌ Victims: Cannot see donations

---

### 4. **Camp Admin Resource Request Flow**

```
Camp Admin creates resource request for their camp
    ↓
Request visible to:
    • Super Admin (all requests)
    • Themselves (for their own camp)
    ↓
Super Admin or Camp Admin approves
    ↓
Super Admin or Camp Admin fulfills
    ↓
Inventory updated automatically
```

**Who can see it:**
- ✅ Camp Admin: Requests for their camp only
- ✅ Super Admin: All requests

**Who can resolve it:**
- ✅ Camp Admin: Can approve/fulfill for their own camp
- ✅ Super Admin: Can approve/fulfill any request
- ❌ Other Camp Admins: Cannot see other camps' requests

---

### 5. **Volunteer Task Assignment Flow**

```
Super Admin or Camp Admin creates task assignment
    ↓
Task assigned to specific volunteer
    ↓
Volunteer sees task in their dashboard
    ↓
Volunteer updates status: assigned → in_progress → completed
    ↓
Super Admin sees status update
```

**Who can see it:**
- ✅ Volunteer: Only their assigned tasks
- ✅ Super Admin: All tasks
- ✅ Camp Admin: Tasks for their camp's volunteers

**Who can resolve it:**
- ✅ Volunteer: Can update their own task status
- ✅ Super Admin: Can update any task
- ✅ Camp Admin: Can update tasks for their camp's volunteers

---

## Location-Based Features

### **Automatic Routing Based on Location:**

1. **Victim SOS Requests:**
   - System finds volunteers within 50km of victim's location
   - Suggests nearest available volunteers

2. **Victim Resource Requests:**
   - System finds nearest camp within 100km
   - Auto-assigns to that camp's admin

3. **Donor Camp Search:**
   - Donors can search camps by location name
   - View all camps in that location
   - See camp requirements before donating

---

## Permission Matrix

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

## Key Points

1. **Victims** make SOS requests → **Volunteers** help → **Super Admin** monitors
2. **Victims** make resource requests → **Camp Admin** (nearest camp) resolves
3. **Donors** donate to camps → **Camp Admin** accepts → acknowledgment sent
4. **Camp Admins** manage only their assigned camp
5. **Super Admin** has full visibility and control over everything
6. **Location-based routing** automatically assigns requests to nearest available resources

