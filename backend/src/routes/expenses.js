const express = require('express');
const router = express.Router();
const {
  createExpense,
  getGroupExpenses,
  getExpense,
  updateExpense,
  deleteExpense,
} = require('../controllers/expenseController');
const { auth } = require('../middleware');

// All routes require authentication
router.use(auth);

// Create expense
router.post('/', createExpense);

// Get expenses for a group
router.get('/group/:groupId', getGroupExpenses);

// Single expense operations
router.route('/:id')
  .get(getExpense)
  .put(updateExpense)
  .delete(deleteExpense);

module.exports = router;
