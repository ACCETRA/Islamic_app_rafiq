// server/models/Surah.js
const mongoose = require('mongoose');

const surahSchema = new mongoose.Schema({
  number: { type: Number, required: true, unique: true },
  name: { type: String, required: true },
  nameArabic: { type: String, required: true },
  verses: { type: Number, required: true },
  type: { type: String, enum: ['Makki', 'Madani'], required: true },
  revelationOrder: { type: Number, required: true }
});

module.exports = mongoose.model('Surah', surahSchema);
