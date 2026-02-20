# AppLock - Quick Start Guide

## ✅ Everything is Ready!

Both backend and Flutter app are configured and ready to run.

## 🚀 Backend Setup (Already Done!)

All dependencies are installed. Just run:

```bash
cd backend
npm run dev
```

The server will start on `http://localhost:3000`

**Database:** MongoDB Atlas (already configured)
- Connection: `mongodb+srv://tom:3VcA5JmnEEwwGAFh@cluster0.4g3zvom.mongodb.net/applock?appName=Cluster0`
- Database name: `applock`

## 📱 Flutter App Setup (Already Done!)

All dependencies are installed. Just run:

```bash
cd app
flutter run
```

**Logo:** Custom logo image is set up at `app/assets/images/app_logo.png`

## 🔐 User Approval System

1. **Register** a new user in the app
2. **Admin Approval Required**: User cannot login until approved
3. **Approve User** via MongoDB:
   ```javascript
   db.users.updateOne({email: "user@example.com"}, {$set: {isApproved: true}})
   ```
4. **Login** after approval

## ✨ Features Implemented

✅ User Registration & Login (with approval system)
✅ Email/Password, PIN, and Biometric authentication  
✅ Lock any installed app
✅ Multiple lock types (Password, PIN, Pattern, Biometric)
✅ Device Administrator protection
✅ Accessibility Service for app detection
✅ Persistent locking (syncs to backend)
✅ Settings screen
✅ Modern UI with custom logo
✅ Error handling and user feedback

## 📋 API Endpoints

### Authentication
- `POST /api/auth/register` - Register (requires approval)
- `POST /api/auth/login` - Login (only approved users)

### Locked Apps (requires auth)
- `GET /api/users/:userId/locked-apps`
- `POST /api/users/:userId/locked-apps`
- `PUT /api/users/:userId/locked-apps/:packageName`
- `DELETE /api/users/:userId/locked-apps/:packageName`

### Admin
- `PUT /api/admin/users/:userId/approve`

## 🎯 Next Steps

1. Start backend: `cd backend && npm run dev`
2. Start Flutter app: `cd app && flutter run`
3. Register a user
4. Approve the user in MongoDB
5. Login and start locking apps!

## 📝 Notes

- For Android emulator, API URL is already set to `http://localhost:3000/api`
- For physical device, update `app/lib/services/api_service.dart` with your computer's IP
- Enable Device Administrator and Accessibility Service after first launch
- Logo is displayed on splash screen and login screen
