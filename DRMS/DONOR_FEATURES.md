# Donor Features - Complete Guide

This document explains all the donor-related features that have been implemented.

## 🎯 **Donor Workflow**

### **1. Search Camps by Location**
Donors can search for camps in a specific location (e.g., "Thrissur")

**Endpoint:** `GET /shelters/list_camps/?location=thrissur`

**Example:**
```json
GET /shelters/list_camps/?location=thrissur
```

**Response:**
```json
{
  "camps": [
    {
      "id": 1,
      "name": "Thrissur Relief Camp",
      "camp_type": "shelter",
      "location": "Thrissur, Kerala",
      "status": "active",
      ...
    }
  ]
}
```

### **2. View Camp Details and Requirements**
Donors can view detailed information about a camp, including:
- Camp information (location, capacity, contact details)
- **Resource requests (requirements)** - What the camp needs
- Each requirement shows:
  - Resource name and category
  - Quantity needed
  - Priority level
  - When it's needed by
  - Reason for the request

**Endpoint:** `GET /shelters/get_camp/{camp_id}`

**Response includes:**
```json
{
  "id": 1,
  "name": "Thrissur Relief Camp",
  "location": "Thrissur, Kerala",
  "resource_requests": [
    {
      "id": 1,
      "resource_name": "Rice",
      "resource_category": "food",
      "quantity_requested": 1000.0,
      "quantity_fulfilled": 200.0,
      "quantity_needed": 800.0,
      "unit": "kg",
      "priority": "urgent",
      "status": "pending",
      "needed_by": "2024-11-05T00:00:00Z",
      "reason": "Food shortage for 500 people"
    }
  ]
}
```

### **3. Make a Donation to a Camp**
Donors can make donations to specific camps with items they want to donate.

**Endpoint:** `POST /operations/create_donation`

**Request Body:**
```json
{
  "donor_name": "John Doe",
  "donor_type": "individual",
  "camp_id": 1,
  "contact_email": "john@example.com",
  "contact_phone": "+919876543210",
  "items": [
    {
      "resource_id": 1,
      "quantity": 50.0
    },
    {
      "resource_id": 2,
      "quantity": 100.0
    }
  ]
}
```

**Response:**
```json
{
  "message": "Donation created successfully. It is pending approval from the camp admin.",
  "donation_id": 5,
  "camp_name": "Thrissur Relief Camp",
  "status": "pending",
  "donation_date": "2024-11-01T10:30:00Z"
}
```

**Important Notes:**
- Donations start as `pending` status
- Inventory is **NOT** updated until camp admin accepts the donation
- Donor will receive an acknowledgment after acceptance

### **4. View All My Donations**
Donors can see all donations they've made to different camps.

**Endpoint:** `GET /operations/my_donations`

**Response:**
```json
{
  "my_donations": [
    {
      "id": 5,
      "donor_name": "John Doe",
      "donor_type": "individual",
      "camp_id": 1,
      "camp_name": "Thrissur Relief Camp",
      "camp_location": "Thrissur, Kerala",
      "status": "accepted",
      "donation_date": "2024-11-01T10:30:00Z",
      "items": [
        {
          "resource_name": "Rice",
          "quantity": 50.0,
          "unit": "kg"
        }
      ],
      "has_acknowledgment": true,
      "acknowledgment": {
        "text": "Thank you for your generous donation!",
        "acknowledged_by": "camp_admin_user",
        "acknowledged_at": "2024-11-01T11:00:00Z"
      }
    }
  ],
  "total": 1
}
```

---

## 🏕️ **Camp Admin Workflow**

### **1. View Donations for My Camp**
Camp admins can see all donations made to their camp.

**Endpoint:** `GET /operations/camp_donations/{camp_id}`

**Query Parameters:**
- `?status=pending` - Filter by status (pending, accepted, rejected)

**Response:**
```json
{
  "camp_id": 1,
  "camp_name": "Thrissur Relief Camp",
  "donations": [
    {
      "id": 5,
      "donor_name": "John Doe",
      "donor_type": "individual",
      "status": "pending",
      "donation_date": "2024-11-01T10:30:00Z",
      "items": [
        {
          "resource_name": "Rice",
          "quantity": 50.0
        }
      ]
    }
  ],
  "total": 1,
  "pending": 1,
  "accepted": 0,
  "rejected": 0
}
```

### **2. Accept or Reject Donations**
Camp admins can accept or reject donations made to their camp.

**Endpoint:** `PUT /operations/update_donation_status/{donation_id}`

**Request Body:**
```json
{
  "status": "accepted",
  "acknowledgment_text": "Thank you for your generous donation! We appreciate your support."
}
```

**Status Options:**
- `pending` - Initial status
- `accepted` - Camp admin accepts the donation
- `rejected` - Camp admin rejects the donation

**What Happens When Accepted:**
1. Donation status changes to `accepted`
2. Resource inventory is updated (items added to available quantity)
3. Inventory transaction is created for audit trail
4. Acknowledgment is automatically created/updated
5. Donor can see the acknowledgment in their donation list

**Response:**
```json
{
  "message": "Donation accepted successfully",
  "donation_id": 5,
  "previous_status": "pending",
  "new_status": "accepted",
  "acknowledgment_id": 1,
  "acknowledged_at": "2024-11-01T11:00:00Z"
}
```

### **3. View Pending Donations in Camp Details**
When viewing camp details, camp admins can see pending donations.

**Endpoint:** `GET /shelters/get_camp/{camp_id}`

**Response includes:**
```json
{
  "id": 1,
  "name": "Thrissur Relief Camp",
  "pending_donations": [
    {
      "id": 5,
      "donor_name": "John Doe",
      "donor_type": "individual",
      "items": [
        {
          "resource_name": "Rice",
          "quantity": 50.0
        }
      ],
      "donation_date": "2024-11-01T10:30:00Z"
    }
  ],
  "statistics": {
    "pending_donations_count": 1
  }
}
```

---

## 📊 **Complete Donation Flow**

```
1. Donor searches camps by location
   ↓
2. Donor views camp details and requirements
   ↓
3. Donor makes donation to specific camp
   ↓ (Status: pending)
4. Camp Admin views pending donations
   ↓
5. Camp Admin accepts/rejects donation
   ↓ (If accepted)
6. Inventory updated automatically
   ↓
7. Acknowledgment sent to donor
   ↓
8. Donor sees acknowledgment in their donation list
```

---

## 🔒 **Security & Permissions**

### **Donor Permissions:**
- ✅ Can view all camps
- ✅ Can search camps by location
- ✅ Can view camp requirements
- ✅ Can create donations
- ✅ Can view their own donations
- ❌ Cannot see other donors' donations
- ❌ Cannot accept/reject donations

### **Camp Admin Permissions:**
- ✅ Can view donations for their camp only
- ✅ Can accept/reject donations for their camp
- ✅ Can send acknowledgments
- ❌ Cannot see donations for other camps
- ❌ Cannot accept/reject donations for other camps

### **Super Admin Permissions:**
- ✅ Can view all donations
- ✅ Can accept/reject any donation
- ✅ Can manage all camps

---

## 📝 **Database Changes Required**

The `Donation` model has been updated to include:
- `camp` field (ForeignKey to Camp) - Links donation to specific camp
- `status` field - Tracks donation status (pending, accepted, rejected)

**You need to create and run a migration:**
```bash
python manage.py makemigrations operations
python manage.py migrate
```

---

## 🎯 **Key Features Summary**

1. ✅ **Location-based camp search** - Donors can find camps by location
2. ✅ **Camp requirements visibility** - Donors can see what each camp needs
3. ✅ **Camp-specific donations** - Donations are linked to specific camps
4. ✅ **Donation tracking** - Donors can see all their donations
5. ✅ **Camp admin approval** - Donations require camp admin acceptance
6. ✅ **Automatic inventory update** - Inventory updated when donation accepted
7. ✅ **Acknowledgment system** - Camp admins can send thank you messages
8. ✅ **Status tracking** - Donations have pending/accepted/rejected status

All features are now implemented and ready to use! 🎉

