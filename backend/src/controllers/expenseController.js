const { Expense, Group } = require('../models');
const { asyncHandler, AppError } = require('../middleware');

// @desc    Create expense
// @route   POST /api/expenses
// @access  Private (group member only)
const createExpense = asyncHandler(async (req, res) => {
  const {
    groupId,
    description,
    amount,
    paidBy,
    splitType = 'equal',
    splits,
    notes,
    category,
  } = req.body;

  // Validate group exists and user is member
  const group = await Group.findById(groupId);
  if (!group) {
    throw new AppError('Group not found', 404);
  }

  if (!group.isMember(req.userId)) {
    throw new AppError('You are not a member of this group', 403);
  }

  // Validate paidBy is a group member
  if (!group.isMember(paidBy)) {
    throw new AppError('Payer must be a group member', 400);
  }

  // Calculate splits based on split type
  let calculatedSplits;

  if (splitType === 'equal') {
    // Equal split among all group members
    const splitUsers = splits?.map((s) => s.user) || group.members;
    calculatedSplits = Expense.calculateEqualSplits(amount, splitUsers);
  } else if (splitType === 'percentage') {
    // Percentage based split
    if (!splits || splits.length === 0) {
      throw new AppError('Splits required for percentage split type', 400);
    }

    const totalPercentage = splits.reduce((sum, s) => sum + (s.percentage || 0), 0);
    if (Math.abs(totalPercentage - 100) > 0.01) {
      throw new AppError('Percentages must add up to 100', 400);
    }

    calculatedSplits = Expense.calculatePercentageSplits(amount, splits);
  } else if (splitType === 'unequal') {
    // Custom amounts
    if (!splits || splits.length === 0) {
      throw new AppError('Splits required for unequal split type', 400);
    }

    const totalSplit = splits.reduce((sum, s) => sum + s.amount, 0);
    if (Math.abs(totalSplit - amount) > 0.01) {
      throw new AppError('Split amounts must equal total amount', 400);
    }

    calculatedSplits = splits.map((s) => ({
      user: s.user,
      amount: s.amount,
    }));
  } else {
    throw new AppError('Invalid split type', 400);
  }

  // Validate all split users are group members
  for (const split of calculatedSplits) {
    if (!group.isMember(split.user)) {
      throw new AppError('All split users must be group members', 400);
    }
  }

  const expense = await Expense.create({
    group: groupId,
    description,
    amount,
    paidBy,
    splitType,
    splits: calculatedSplits,
    notes,
    category,
    createdBy: req.userId,
  });

  await expense.populate([
    { path: 'paidBy', select: 'name avatar' },
    { path: 'splits.user', select: 'name avatar' },
    { path: 'createdBy', select: 'name' },
  ]);

  res.status(201).json({
    success: true,
    message: 'Expense added successfully',
    data: { expense },
  });
});

// @desc    Get all expenses for a group
// @route   GET /api/expenses/group/:groupId
// @access  Private (group member only)
const getGroupExpenses = asyncHandler(async (req, res) => {
  const { groupId } = req.params;
  const { page = 1, limit = 20 } = req.query;

  const group = await Group.findById(groupId);
  if (!group) {
    throw new AppError('Group not found', 404);
  }

  if (!group.isMember(req.userId)) {
    throw new AppError('You are not a member of this group', 403);
  }

  const expenses = await Expense.find({
    group: groupId,
    isDeleted: false,
  })
    .populate('paidBy', 'name avatar')
    .populate('splits.user', 'name avatar')
    .populate('createdBy', 'name')
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(parseInt(limit));

  const total = await Expense.countDocuments({
    group: groupId,
    isDeleted: false,
  });

  res.status(200).json({
    success: true,
    data: {
      expenses,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit),
      },
    },
  });
});

// @desc    Get single expense
// @route   GET /api/expenses/:id
// @access  Private (group member only)
const getExpense = asyncHandler(async (req, res) => {
  const expense = await Expense.findById(req.params.id)
    .populate('paidBy', 'name avatar')
    .populate('splits.user', 'name avatar')
    .populate('createdBy', 'name')
    .populate('group', 'name');

  if (!expense || expense.isDeleted) {
    throw new AppError('Expense not found', 404);
  }

  const group = await Group.findById(expense.group);
  if (!group.isMember(req.userId)) {
    throw new AppError('You are not a member of this group', 403);
  }

  res.status(200).json({
    success: true,
    data: { expense },
  });
});

// @desc    Update expense
// @route   PUT /api/expenses/:id
// @access  Private (creator only)
const updateExpense = asyncHandler(async (req, res) => {
  const { description, notes, category } = req.body;

  let expense = await Expense.findById(req.params.id);

  if (!expense || expense.isDeleted) {
    throw new AppError('Expense not found', 404);
  }

  if (expense.createdBy.toString() !== req.userId.toString()) {
    throw new AppError('Only the creator can update this expense', 403);
  }

  // Only allow updating description, notes, category (not amounts/splits)
  expense = await Expense.findByIdAndUpdate(
    req.params.id,
    { description, notes, category },
    { new: true, runValidators: true }
  )
    .populate('paidBy', 'name avatar')
    .populate('splits.user', 'name avatar');

  res.status(200).json({
    success: true,
    message: 'Expense updated successfully',
    data: { expense },
  });
});

// @desc    Delete expense (soft delete)
// @route   DELETE /api/expenses/:id
// @access  Private (creator or group admin)
const deleteExpense = asyncHandler(async (req, res) => {
  const expense = await Expense.findById(req.params.id);

  if (!expense || expense.isDeleted) {
    throw new AppError('Expense not found', 404);
  }

  const group = await Group.findById(expense.group);
  const isCreator = expense.createdBy.toString() === req.userId.toString();
  const isAdmin = group.isAdmin(req.userId);

  if (!isCreator && !isAdmin) {
    throw new AppError('Not authorized to delete this expense', 403);
  }

  expense.isDeleted = true;
  await expense.save();

  res.status(200).json({
    success: true,
    message: 'Expense deleted successfully',
  });
});

module.exports = {
  createExpense,
  getGroupExpenses,
  getExpense,
  updateExpense,
  deleteExpense,
};
