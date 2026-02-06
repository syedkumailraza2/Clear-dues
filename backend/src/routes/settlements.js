const express = require('express');
const router = express.Router();
const {
  getGroupBalances,
  getSuggestedSettlements,
  createSettlement,
  getUpiLink,
  markAsPaid,
  confirmSettlement,
  rejectSettlement,
  getMyPendingSettlements,
  getSettlementsToConfirm,
  getGroupSettlements,
  getDashboard,
} = require('../controllers/settlementController');
const { auth } = require('../middleware');

// All routes require authentication
router.use(auth);

// Dashboard
router.get('/dashboard', getDashboard);

// My settlements
router.get('/my/pending', getMyPendingSettlements);
router.get('/my/to-confirm', getSettlementsToConfirm);

// Group balances and settlements
router.get('/balances/:groupId', getGroupBalances);
router.get('/suggest/:groupId', getSuggestedSettlements);
router.get('/group/:groupId', getGroupSettlements);

// Settlement CRUD
router.post('/', createSettlement);

// Settlement actions
router.get('/:id/upi-link', getUpiLink);
router.put('/:id/pay', markAsPaid);
router.put('/:id/confirm', confirmSettlement);
router.put('/:id/reject', rejectSettlement);

module.exports = router;
