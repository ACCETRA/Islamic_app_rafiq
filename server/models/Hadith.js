// server/models/Hadith.js
const mongoose = require('mongoose');

const hadithSchema = new mongoose.Schema({
  book: { type: String, required: true },
  bookArabic: { type: String, required: true },
  chapter: String,
  chapterArabic: String,
  number: { type: Number, required: true },
  text: { type: String, required: true },
  textArabic: { type: String, required: true },
  narrator: String,
  grade: String,
  topic: [String]
});

module.exports = mongoose.model('Hadith', hadithSchema);
