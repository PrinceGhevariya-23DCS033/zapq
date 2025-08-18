# 🚨 URGENT: Fix Firestore Rules for Business Owner Dashboard

## Problem
Business owners getting permission error: `The caller does not have permission to execute the specified operation.`

## Solution
**Update your Firebase Firestore Security Rules immediately:**

### Step 1: Go to Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your ZapQ project
3. Go to **Firestore Database** → **Rules**

### Step 2: Replace the bookings collection rules
**Find this section in your rules:**
```javascript
// Bookings collection - OLD RULE (causing error)
match /bookings/{bookingId} {
  allow read: if request.auth != null && 
    (request.auth.uid == resource.data.customerId || 
     request.auth.uid == resource.data.businessOwnerId);
  // ... rest of rules
}
```

**Replace with this NEW RULE:**
```javascript
// Bookings collection - FIXED RULE for business owners
match /bookings/{bookingId} {
  allow read: if request.auth != null && 
    (request.auth.uid == resource.data.customerId || 
     exists(/databases/$(database)/documents/businesses/$(resource.data.businessId)) &&
     get(/databases/$(database)/documents/businesses/$(resource.data.businessId)).data.ownerId == request.auth.uid);
  allow create: if request.auth != null && 
    request.auth.uid == request.resource.data.customerId;
  allow update: if request.auth != null && 
    (request.auth.uid == resource.data.customerId || 
     exists(/databases/$(database)/documents/businesses/$(resource.data.businessId)) &&
     get(/databases/$(database)/documents/businesses/$(resource.data.businessId)).data.ownerId == request.auth.uid);
  allow delete: if request.auth != null && 
    (request.auth.uid == resource.data.customerId || 
     exists(/databases/$(database)/documents/businesses/$(resource.data.businessId)) &&
     get(/databases/$(database)/documents/businesses/$(resource.data.businessId)).data.ownerId == request.auth.uid);
}
```

### Step 3: Click "Publish" to deploy the rules

## What This Fixes
- ✅ Business owners can now access bookings for their businesses
- ✅ Permission errors will be resolved
- ✅ Owner dashboard will load booking data correctly

## Technical Explanation
The old rule was looking for a `businessOwnerId` field that doesn't exist in our booking documents. The new rule:
1. Checks if the business exists
2. Verifies that the authenticated user is the owner of that business
3. Allows access if they are the owner

**This fix is critical for the business owner dashboard to work!**
