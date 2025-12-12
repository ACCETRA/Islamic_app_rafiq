const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
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

module.exports = mongoose.model('User', userSchema);
