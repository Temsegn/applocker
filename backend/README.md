# AppLock Backend

## Quick Start

1. Install dependencies:
```bash
npm install
```

2. The `.env` file is already configured with MongoDB connection.

3. Run the server:
```bash
npm run dev
```

The server will start on port 3000.

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user (requires admin approval)
- `POST /api/auth/login` - Login user (only approved users can login)

### Locked Apps (requires authentication)
- `GET /api/users/:userId/locked-apps` - Get all locked apps
- `POST /api/users/:userId/locked-apps` - Add locked app
- `PUT /api/users/:userId/locked-apps/:packageName` - Update locked app
- `DELETE /api/users/:userId/locked-apps/:packageName` - Remove locked app

### Admin
- `PUT /api/admin/users/:userId/approve` - Approve user (requires authentication)

## User Approval

New users are created with `isApproved: false` by default. To approve a user:

1. Via MongoDB:
```javascript
db.users.updateOne({email: "user@example.com"}, {$set: {isApproved: true}})
```

2. Via API:
```bash
PUT /api/admin/users/:userId/approve
```

## Database

MongoDB Atlas connection is configured. Database name: `applock`
