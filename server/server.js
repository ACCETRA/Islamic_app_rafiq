require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const app = express();

// Configuration
const PORT = process.env.PORT || 3000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/rafiq';

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
    console.error('❌ JWT_SECRET is not set. Add it to server/.env before starting the server.');
    process.exit(1);
}

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection
mongoose.connect(MONGODB_URI)
    .then(() => console.log('✅ Connected to MongoDB'))
    .catch(err => console.error('❌ MongoDB connection error:', err));

// User Schema
const userSchema = new mongoose.Schema({
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    password: { type: String, required: true },
    location: {
        latitude: Number,
        longitude: Number,
        city: String,
        country: String
    },
    preferences: {
        prayerMethod: { type: String, default: 'MWL' },
        language: { type: String, default: 'en' },
        notifications: { type: Boolean, default: true }
    },
    bookmarks: [{
        surah: Number,
        verse: Number,
        note: String,
        createdAt: { type: Date, default: Date.now }
    }],
    progress: {
        lastReadSurah: Number,
        lastReadVerse: Number,
        dailyStreak: { type: Number, default: 0 },
        totalReadings: { type: Number, default: 0 }
    }
}, { timestamps: true });

// Hash password before saving
userSchema.pre('save', async function (next) {
    if (!this.isModified('password')) return next();
    this.password = await bcrypt.hash(this.password, 12);
    next();
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
    return bcrypt.compare(candidatePassword, this.password);
};

const User = mongoose.model('User', userSchema);

// Auth Middleware
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Access token required' });
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid or expired token' });
        }
        req.user = user;
        next();
    });
};

// Generate JWT Token
const generateToken = (user) => {
    return jwt.sign(
        { id: user._id, email: user.email, name: user.name },
        JWT_SECRET,
        { expiresIn: '7d' }
    );
};

// ==================== AUTH ROUTES ====================

// Signup
app.post('/api/auth/signup', async (req, res) => {
    try {
        const { name, email, password } = req.body;

        // Validation
        if (!name || !email || !password) {
            return res.status(400).json({ error: 'Name, email and password are required' });
        }

        if (password.length < 6) {
            return res.status(400).json({ error: 'Password must be at least 6 characters' });
        }

        // Check if user exists
        const existingUser = await User.findOne({ email: email.toLowerCase() });
        if (existingUser) {
            return res.status(400).json({ error: 'Email already registered' });
        }

        // Create user
        const user = new User({ name, email, password });
        await user.save();

        // Generate token
        const token = generateToken(user);

        res.status(201).json({
            message: 'Account created successfully',
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                preferences: user.preferences
            }
        });
    } catch (error) {
        console.error('Signup error:', error);
        res.status(500).json({ error: 'Server error during signup' });
    }
});

// Login
app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Validation
        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required' });
        }

        // Find user
        const user = await User.findOne({ email: email.toLowerCase() });
        if (!user) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        // Check password
        const isMatch = await user.comparePassword(password);
        if (!isMatch) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        // Generate token
        const token = generateToken(user);

        res.json({
            message: 'Login successful',
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                preferences: user.preferences,
                progress: user.progress
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: 'Server error during login' });
    }
});

// Get Current User (Protected)
app.get('/api/auth/me', authenticateToken, async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('-password');
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.json({ user });
    } catch (error) {
        console.error('Get user error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Verify Token
app.get('/api/auth/verify', authenticateToken, (req, res) => {
    res.json({ valid: true, user: req.user });
});

// Update User Preferences
app.put('/api/auth/preferences', authenticateToken, async (req, res) => {
    try {
        const { preferences } = req.body;
        const user = await User.findByIdAndUpdate(
            req.user.id,
            { preferences },
            { new: true }
        ).select('-password');

        res.json({ user });
    } catch (error) {
        console.error('Update preferences error:', error);
        res.status(500).json({ error: 'Server error' });
    }
});

// Root endpoint for API overview
app.get('/', (req, res) => {
    res.json({
        status: 'ok',
        message: 'Rafiq backend API is running',
        endpoints: {
            health: '/api/health',
            signup: 'POST /api/auth/signup',
            login: 'POST /api/auth/login',
            me: 'GET /api/auth/me',
            verify: 'GET /api/auth/verify'
        }
    });
});

// Health Check
app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Start Server
app.listen(PORT, () => {
    console.log(`🚀 Rafiq Backend Server running on http://localhost:${PORT}`);
    console.log(`📚 API Endpoints:`);
    console.log(`   POST /api/auth/signup - Create account`);
    console.log(`   POST /api/auth/login  - Login`);
    console.log(`   GET  /api/auth/me     - Get current user`);
    console.log(`   GET  /api/auth/verify - Verify token`);
});
