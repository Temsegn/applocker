const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// MongoDB Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb+srv://tom:3VcA5JmnEEwwGAFh@cluster0.4g3zvom.mongodb.net/applock?appName=Cluster0';

// User Schema (same as in server.js)
const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  isApproved: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

const User = mongoose.model('User', userSchema);

async function createTestUser() {
  try {
    // Connect to MongoDB
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    const email = 'tommr2323@gmail.com';
    const password = '123456';

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    
    if (existingUser) {
      // Update existing user: hash password and set isApproved to true
      const hashedPassword = await bcrypt.hash(password, 10);
      existingUser.password = hashedPassword;
      existingUser.isApproved = true;
      await existingUser.save();
      console.log(`✅ User updated successfully!`);
      console.log(`   Email: ${email}`);
      console.log(`   Password: ${password}`);
      console.log(`   isApproved: ${existingUser.isApproved}`);
      console.log(`   User ID: ${existingUser._id}`);
    } else {
      // Create new user
      const hashedPassword = await bcrypt.hash(password, 10);
      const user = new User({
        email,
        password: hashedPassword,
        isApproved: true
      });

      await user.save();
      console.log(`✅ Test user created successfully!`);
      console.log(`   Email: ${email}`);
      console.log(`   Password: ${password}`);
      console.log(`   isApproved: ${user.isApproved}`);
      console.log(`   User ID: ${user._id}`);
    }

    // Close connection
    await mongoose.connection.close();
    console.log('\n✅ Done! User is ready for testing.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.code === 11000) {
      console.error('   User already exists (duplicate key error)');
    }
    await mongoose.connection.close();
    process.exit(1);
  }
}

createTestUser();
