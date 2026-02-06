const express = require('express');
const router = express.Router();
const { signup, login, getMe, updatePassword } = require('../controllers/authController');
const { auth } = require('../middleware');

// Public routes
router.post('/signup', signup);
router.post('/login', login);

// Protected routes
router.get('/me', auth, getMe);
router.put('/password', auth, updatePassword);

module.exports = router;
