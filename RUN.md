# How to Run AppLock

## Backend Setup

1. Navigate to backend folder:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Run the server:
```bash
npm run dev
```

The backend will start on `http://localhost:3000`

## Flutter App Setup

1. Navigate to app folder:
```bash
cd app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Update API URL (if needed):
   - Edit `lib/services/api_service.dart`
   - For Android emulator: `http://10.0.2.2:3000/api`
   - For physical device: Use your computer's IP address

4. Run the app:
```bash
flutter run
```

## First Time Setup

1. **Register**: Create a new account in the app
2. **Wait for Approval**: Admin needs to approve your account
3. **Approve User**: In MongoDB, run:
   ```javascript
   db.users.updateOne({email: "your@email.com"}, {$set: {isApproved: true}})
   ```
4. **Login**: After approval, you can login
5. **Enable Permissions**: 
   - Enable Device Administrator
   - Enable Accessibility Service
6. **Lock Apps**: Browse apps and lock them with passwords/PINs

## Features

✅ User Registration & Login (with approval system)
✅ Email/Password, PIN, and Biometric authentication
✅ Lock any installed app
✅ Multiple lock types (Password, PIN, Pattern, Biometric)
✅ Device Administrator protection
✅ Accessibility Service for app detection
✅ Persistent locking (syncs to backend)
✅ Settings screen
✅ Modern UI with custom logo
