const express = require('express');
const router = express.Router();
const { updateProfile, searchUsers, getUserById } = require('../controllers/userController');
const { auth } = require('../middleware');

// All routes require authentication
router.use(auth);

router.put('/profile', updateProfile);
router.get('/search', searchUsers);
router.get('/:id', getUserById);

module.exports = router;
