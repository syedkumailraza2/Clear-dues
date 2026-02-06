const express = require('express');
const router = express.Router();
const {
  createGroup,
  getMyGroups,
  getGroup,
  updateGroup,
  deleteGroup,
  joinGroup,
  addMember,
  removeMember,
  getInviteLink,
} = require('../controllers/groupController');
const { auth } = require('../middleware');

// All routes require authentication
router.use(auth);

// Group CRUD
router.route('/')
  .get(getMyGroups)
  .post(createGroup);

router.route('/:id')
  .get(getGroup)
  .put(updateGroup)
  .delete(deleteGroup);

// Join via invite code
router.post('/join/:inviteCode', joinGroup);

// Member management
router.post('/:id/members', addMember);
router.delete('/:id/members/:userId', removeMember);

// Invite link
router.get('/:id/invite', getInviteLink);

module.exports = router;
