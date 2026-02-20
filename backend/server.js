const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb+srv://tom:3VcA5JmnEEwwGAFh@cluster0.4g3zvom.mongodb.net/applock?appName=Cluster0';
mongoose.connect(MONGODB_URI)
  .then(() => console.log('MongoDB connected to applock database'))
  .catch(err => console.error('MongoDB connection error:', err));

// Schemas
const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  isApproved: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

const lockedAppSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  packageName: { type: String, required: true },
  appName: { type: String, required: true },
  iconPath: String,
  iconBase64: String,
  lockType: { type: String, required: true },
  password: String,
  pin: String,
  pattern: String,
  isLocked: { type: Boolean, default: true },
  isHidden: { type: Boolean, default: false },
  isBlocked: { type: Boolean, default: false },
  lockScheduleStart: Date,
  lockScheduleEnd: Date,
  createdAt: { type: Date, default: Date.now }
});

const User = mongoose.model('User', userSchema);
const LockedApp = mongoose.model('LockedApp', lockedAppSchema);

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// Auth Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ success: false, message: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

// Routes

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'AppLock API is running' });
});

// Register
app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required' });
    }

    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ success: false, message: 'User already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user (isApproved defaults to false)
    const user = new User({
      email,
      password: hashedPassword,
      isApproved: false
    });

    await user.save();

    res.status(201).json({
      success: true,
      userId: user._id.toString(),
      message: 'User registered successfully. Please wait for admin approval before logging in.'
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required' });
    }

    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    // Check if user is approved
    if (!user.isApproved) {
      return res.status(403).json({ 
        success: false, 
        message: 'Your account is pending approval. Please wait for admin approval before logging in.' 
      });
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    // Generate token
    const token = jwt.sign({ userId: user._id, email: user.email }, JWT_SECRET, { expiresIn: '30d' });

    res.json({
      success: true,
      token,
      userId: user._id.toString(),
      message: 'Login successful'
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Get locked apps
app.get('/api/users/:userId/locked-apps', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;

    if (req.user.userId !== userId) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    const lockedApps = await LockedApp.find({ userId });
    res.json(lockedApps);
  } catch (error) {
    console.error('Get locked apps error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Add locked app
app.post('/api/users/:userId/locked-apps', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;

    if (req.user.userId !== userId) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    const lockedApp = new LockedApp({
      ...req.body,
      userId
    });

    await lockedApp.save();
    res.status(201).json({ success: true, lockedApp });
  } catch (error) {
    console.error('Add locked app error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Update locked app
app.put('/api/users/:userId/locked-apps/:packageName', authenticateToken, async (req, res) => {
  try {
    const { userId, packageName } = req.params;

    if (req.user.userId !== userId) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    const lockedApp = await LockedApp.findOneAndUpdate(
      { userId, packageName },
      req.body,
      { new: true }
    );

    if (!lockedApp) {
      return res.status(404).json({ success: false, message: 'Locked app not found' });
    }

    res.json({ success: true, lockedApp });
  } catch (error) {
    console.error('Update locked app error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Remove locked app
app.delete('/api/users/:userId/locked-apps/:packageName', authenticateToken, async (req, res) => {
  try {
    const { userId, packageName } = req.params;

    if (req.user.userId !== userId) {
      return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    const lockedApp = await LockedApp.findOneAndDelete({ userId, packageName });

    if (!lockedApp) {
      return res.status(404).json({ success: false, message: 'Locked app not found' });
    }

    res.json({ success: true, message: 'Locked app removed' });
  } catch (error) {
    console.error('Remove locked app error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Admin: Approve user (for admin use - update user.isApproved to true in database)
// You can use MongoDB directly: db.users.updateOne({email: "user@example.com"}, {$set: {isApproved: true}})
app.put('/api/admin/users/:userId/approve', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Note: In production, add admin role check here
    const user = await User.findByIdAndUpdate(
      userId,
      { isApproved: true },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ success: true, message: 'User approved successfully', user });
  } catch (error) {
    console.error('Approve user error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`AppLock API server running on port ${PORT}`);
});
