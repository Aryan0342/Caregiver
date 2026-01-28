# Admin Panel Development Prompt for Cursor

## Project Overview
You are building a web-based admin panel for a Flutter mobile app called "Dag in beeld" (Day in view) - a pictogram-based communication app for caregivers and clients. The app uses Firebase (Firestore, Auth) and Cloudinary for image storage.

## IMPORTANT CHANGES - UPDATED REQUIREMENTS

### Key Changes from Previous Version:
1. **ARASAAC Integration Removed**: The app no longer fetches pictograms from ARASAAC. All pictograms are now custom and uploaded by admins.
2. **Cloudinary Instead of Firebase Storage**: Images are now stored in Cloudinary, not Firebase Storage.
3. **Dynamic Category Management**: Categories are no longer hardcoded. Admins can create, edit, and delete categories through the admin panel.
4. **Category Filtering**: The app only displays categories that have at least one active pictogram. Empty categories are hidden.
5. **Start from Zero**: The system starts with zero categories and zero pictograms. Everything is managed through the admin panel.

## Current App Architecture

### Firebase Collections Structure:
1. **`caregivers/{caregiverId}`** - User profiles
   - Fields: `name`, `role`, `sex`, `organisation`, `location`, `language`, `createdAt`
   - Subcollection: `settings/{settingsId}` - Contains PIN hashes and other settings

2. **`categories/{categoryId}`** - Pictogram categories (NEW - dynamically managed)
   - Fields: `name` (String - default name), `nameEn` (String - English name), `nameNl` (String - Dutch name), `description` (String?), `isActive` (Boolean), `createdAt` (Timestamp), `updatedAt` (Timestamp)
   - Categories are created and managed by admins
   - Only categories with at least one active pictogram are shown in the app

3. **`custom_pictograms/{pictogramId}`** - All pictograms (previously "custom", now all pictograms)
   - Fields: `keyword` (String - required), `category` (String - category ID, not key), `imageUrl` (String - Cloudinary URL), `description` (String?), `isActive` (Boolean), `uploadedAt` (Timestamp), `uploadedBy` (String - admin UID)
   - **Important**: The `category` field stores the category document ID (e.g., "abc123"), not a category key

4. **`admin_users/{adminId}`** - Admin user management
   - Fields: `email` (String), `isAdmin` (Boolean), `createdAt` (Timestamp)

5. **`pictogram_sets/{setId}`** - User-created pictogram sets
   - Fields: `userId` (String), `name` (String), `pictograms` (Array), `createdAt` (Timestamp)

6. **`picto_requests/{requestId}`** - Pictogram requests from users
   - Fields: `keyword` (String - required), `category` (String - category ID), `description` (String - optional), `requestedBy` (String - user UID), `status` (String - pending/approved/rejected/completed), `adminNote` (String - optional), `createdAt` (Timestamp), `updatedAt` (Timestamp)

## Requirements

### 1. Authentication
- Use Firebase Authentication (Email/Password)
- Only users in `admin_users` collection with `isAdmin: true` can access the panel
- Implement login page with email/password
- Store admin session (use Firebase Auth persistence)

### 2. Dashboard/Statistics Page
- Display total number of registered users (count from `caregivers` collection)
- Display total number of pictograms (count from `custom_pictograms` collection where `isActive: true`)
- Display total number of categories (count from `categories` collection where `isActive: true`)
- Display total number of pictogram sets (count from `pictogram_sets` collection)
- Display total number of pending picto requests (count from `picto_requests` collection where `status: 'pending'`)
- Show recent activity (last 10 registered users, last 10 uploaded pictograms, last 10 requests)
- Use cards/widgets for each statistic with icons

### 3. Category Management Page (NEW - CRITICAL)

#### Overview:
- This is a new page for managing pictogram categories
- Categories are dynamically created and managed (not hardcoded)
- The app only shows categories that have at least one active pictogram

#### Category List Section:
- Display all categories in a table or grid
- Show: Category Name (with language toggle), Description, Number of Pictograms, Created Date, Status (Active/Inactive)
- Filter by status (active/inactive)
- Search by name
- Pagination (show 20-50 categories per page)

#### Create Category:
- Form fields:
  - **Name** (required, String) - Default/fallback name
  - **Name (English)** (required, String) - English display name
  - **Name (Dutch)** (required, String) - Dutch display name
  - **Description** (optional, String) - Category description
- Create button that:
  1. Creates document in `categories` collection with:
     - `name`: Default name
     - `nameEn`: English name
     - `nameNl`: Dutch name
     - `description`: User input (if provided)
     - `isActive`: true
     - `createdAt`: Server timestamp
     - `updatedAt`: Server timestamp
  2. Shows success/error message

#### Edit Category:
- Update category name (all three fields), description
- Toggle active/inactive status
- **Important**: When deactivating a category, consider what happens to pictograms in that category (they should remain but category won't show in app if inactive)

#### Delete Category:
- **Warning**: Only allow deletion if category has no pictograms
- If category has pictograms, show warning and prevent deletion
- When deleting, remove from Firestore

#### Implementation Details:
- Use Firestore collection: `categories`
- Order by `name` or `createdAt`
- When checking if category has pictograms, query `custom_pictograms` collection where `category == categoryId`

### 4. User Management Page
- List all registered users from `caregivers` collection
- Display: Name, Email (from Firebase Auth), Role, Client Name, Age Range, Registration Date
- Search/filter functionality
- Pagination (show 20-50 users per page)
- Export to CSV option (optional)

### 5. Pictogram Request Management Page

#### Overview:
- Display all pictogram requests from users in a table or list view
- Show: Request ID, Keyword, Category (show category name, not ID), Description, Requested By (user email/name), Status, Created Date, Admin Note
- Filter by status (pending, approved, rejected, completed)
- Filter by category (use category names, not IDs)
- Search by keyword
- Pagination (show 20-50 requests per page)

#### Request Status Management:
- **Pending** (default) - New requests waiting for review
- **Approved** - Request approved, pictogram will be created
- **Rejected** - Request rejected (with optional admin note)
- **Completed** - Pictogram has been created and added to collection

#### Actions per Request:
- **View Details** - Show full request information
- **Approve** - Change status to "approved" (add admin note if needed)
- **Reject** - Change status to "rejected" (require admin note explaining why)
- **Mark as Completed** - Change status to "completed" (after pictogram is uploaded)
- **Add/Edit Admin Note** - Add internal notes about the request
- **Delete** - Remove request from database (use with caution)

#### Workflow:
1. User submits request via app → Status: "pending"
2. Admin reviews request → Can approve or reject
3. If approved → Admin creates pictogram → Status: "completed"
4. If rejected → Admin adds note explaining why → Status: "rejected"

#### Implementation Details:
- Use Firestore collection: `picto_requests`
- Order by `createdAt` descending (newest first)
- Show user information by looking up `caregivers/{requestedBy}` collection
- When marking as completed, optionally link to the created `custom_pictograms` document
- **Category Display**: Look up category name from `categories` collection using the category ID stored in the request

### 6. Pictogram Management Page

#### Upload Section:
- File upload input (accept PNG, JPG, JPEG images)
- Form fields:
  - **Keyword** (required, String) - Dutch keyword for the pictogram
  - **Category** (required, Dropdown) - Select from active categories in `categories` collection (show category names, store category ID)
  - **Description** (optional, String) - Additional description
- Image preview before upload
- Upload button that:
  1. **Uploads image to Cloudinary** (not Firebase Storage):
     - Use Cloudinary upload API
     - Store in a folder like `pictograms/` or `custom_pictograms/`
     - Get the Cloudinary URL (secure URL)
  2. Creates document in `custom_pictograms` collection with:
     - `keyword`: User input
     - `category`: Selected category document ID (not name/key)
     - `imageUrl`: Cloudinary URL (secure URL)
     - `description`: User input (if provided)
     - `isActive`: true
     - `uploadedAt`: Server timestamp
     - `uploadedBy`: Current admin user UID
  3. Shows success/error message

#### List/Manage Section:
- Display all pictograms in a grid or table
- Show: Thumbnail image (from Cloudinary), Keyword, Category (show category name by looking up from `categories`), Upload Date, Status (Active/Inactive)
- Actions per pictogram:
  - **Edit** - Update keyword, category (dropdown with categories), description
  - **Deactivate/Activate** - Toggle `isActive` field (don't delete, just deactivate)
  - **Delete** - Remove from Firestore and delete image from Cloudinary
- Filter by category (show category names)
- Search by keyword
- Pagination

#### Implementation Details:
- **Cloudinary Setup**: 
  - Install Cloudinary SDK: `npm install cloudinary`
  - Configure Cloudinary with API credentials (cloud name, API key, API secret)
  - Use unsigned uploads or signed uploads (recommended: signed uploads for security)
  - Store Cloudinary URL in `imageUrl` field
- **Category Reference**: Always store category document ID in `category` field, but display category name by looking up from `categories` collection

### 7. Technology Stack
- **Framework**: React.js or Vue.js (your choice, but React is recommended)
- **UI Library**: Material-UI (MUI) or Tailwind CSS + Headless UI
- **Firebase SDK**: Firebase JS SDK v9+ (modular)
- **Cloudinary SDK**: Cloudinary JavaScript SDK for image uploads
- **Routing**: React Router or Vue Router
- **State Management**: React Context/Redux or Vuex (optional, can use Firebase real-time listeners)
- **Image Handling**: HTML5 File API, Cloudinary Upload API

### 8. Design Requirements
- Modern, clean, professional admin panel design
- Responsive layout (works on desktop and tablet)
- Color scheme: Match the app's theme colors:
  - Primary Blue: `#4A90E2`
  - Primary Blue Light: `#6BA3D8`
  - Accent Orange: `#FF6B35`
  - Accent Green: `#3DA55F`
  - Background Light: `#F5F7FA`
  - Text Primary: `#2C3E50`
- Use cards, tables, and modern UI components
- Loading states for async operations
- Error handling with user-friendly messages

### 9. Firebase Configuration
- Use the same Firebase project as the Flutter app
- Initialize Firebase with config from `firebase_options.dart` or create a separate web config
- **No Firebase Storage rules needed** - using Cloudinary instead

### 10. Cloudinary Configuration
- Set up Cloudinary account and get credentials:
  - Cloud Name
  - API Key
  - API Secret
- Configure upload presets (recommended: use signed uploads)
- Set up folder structure (e.g., `pictograms/` folder)
- Configure CORS settings if needed
- **Security**: Store Cloudinary credentials securely (use environment variables, not in client code for API secret)

### 11. Security
- All admin operations must verify `isAdmin: true` in Firestore
- Use Firebase Security Rules (already configured in `firestore.rules`)
- Validate file types and sizes on upload (max 5MB, only images)
- Sanitize user inputs
- **Cloudinary**: Use signed uploads or server-side uploads for security (don't expose API secret in client)

### 12. File Structure (Recommended)
```
admin-panel/
├── src/
│   ├── components/
│   │   ├── Dashboard/
│   │   ├── UserManagement/
│   │   ├── CategoryManagement/  (NEW)
│   │   ├── PictogramManagement/
│   │   ├── RequestManagement/
│   │   └── common/
│   ├── services/
│   │   ├── firebase.js
│   │   ├── cloudinary.js  (NEW)
│   │   ├── authService.js
│   │   ├── userService.js
│   │   ├── categoryService.js  (NEW)
│   │   ├── pictogramService.js
│   │   └── requestService.js
│   ├── utils/
│   ├── App.js
│   └── index.js
├── public/
├── package.json
└── README.md
```

### 13. Implementation Steps
1. Set up React/Vue project with Firebase and Cloudinary
2. Create authentication flow (login page)
3. Build dashboard with statistics
4. **Implement category management page** (create, edit, delete categories)
5. Implement user management page
6. Implement pictogram upload functionality (with Cloudinary)
7. Implement pictogram list/management
8. Implement pictogram request management
9. Add search, filter, pagination to all pages
10. Style and polish UI
11. Test all functionality
12. Deploy to Firebase Hosting or similar

### 14. Important Notes
- **Pictogram IDs**: Use auto-generated document IDs from Firestore. The Flutter app uses negative IDs for custom pictograms (e.g., `-int.parse(doc.id)`).
- **Image URLs**: Store the Cloudinary secure URL in the `imageUrl` field of the document.
- **Category IDs**: Always store the category document ID (e.g., "abc123") in the `category` field, not the category name or key. Display category names by looking up from `categories` collection.
- **Empty Categories**: The app only shows categories that have at least one active pictogram. When displaying categories in the admin panel, you can show all categories, but be aware that empty categories won't appear in the app.
- **Category Deletion**: Only allow deletion if category has no pictograms. Show warning if attempting to delete a category with pictograms.
- **Real-time updates**: Consider using Firestore real-time listeners for live updates.
- **Error handling**: Always handle Firebase and Cloudinary errors gracefully and show user-friendly messages.

### 15. Testing Checklist
- [ ] Admin can log in
- [ ] Non-admin users cannot access
- [ ] Dashboard shows correct statistics
- [ ] **Can create new category**
- [ ] **Can edit category (name, description)**
- [ ] **Can delete category (only if empty)**
- [ ] **Cannot delete category with pictograms**
- [ ] **Category list displays correctly**
- [ ] User list displays all registered users
- [ ] Can upload pictogram with Cloudinary
- [ ] Uploaded pictogram appears in list
- [ ] Pictogram category shows correct category name (not ID)
- [ ] Can edit pictogram (keyword, category, description)
- [ ] Can deactivate/activate pictogram
- [ ] Can delete pictogram (removes from Firestore and Cloudinary)
- [ ] Search and filter work correctly
- [ ] Images display correctly from Cloudinary
- [ ] Responsive design works
- [ ] Picto requests page displays all requests
- [ ] Can filter requests by status and category
- [ ] Can approve/reject/complete requests
- [ ] Can add admin notes to requests
- [ ] User information displays correctly for each request

## Getting Started
1. Initialize a new React or Vue project
2. Install Firebase SDK: `npm install firebase`
3. Install Cloudinary SDK: `npm install cloudinary`
4. Install UI library: `npm install @mui/material @emotion/react @emotion/styled` (for MUI) or `npm install tailwindcss` (for Tailwind)
5. Set up Firebase configuration
6. Set up Cloudinary configuration (get credentials from Cloudinary dashboard)
7. Create the folder structure
8. Start building components one by one

## Firebase Project Details
- Project ID: `caregiver-cba18` (from firebase.json)
- Make sure to use the same Firebase project as the Flutter app

## Cloudinary Setup
1. Create a Cloudinary account at https://cloudinary.com
2. Get your Cloud Name, API Key, and API Secret from the dashboard
3. Set up an upload preset (recommended: signed uploads)
4. Configure folder structure (e.g., create `pictograms` folder)
5. Store credentials securely (use environment variables)

Good luck building the admin panel! 🚀
