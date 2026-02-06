const { Settlement, Group, User } = require('../models');
const { asyncHandler, AppError } = require('../middleware');
const balanceService = require('../services/balanceService');
const settlementService = require('../services/settlementService');

// @desc    Get balances for a group
// @route   GET /api/settlements/balances/:groupId
// @access  Private (group member only)
const getGroupBalances = asyncHandler(async (req, res) => {
  const { groupId } = req.params;

  const group = await Group.findById(groupId).populate('members', 'name avatar');
  if (!group) {
    throw new AppError('Group not found', 404);
  }

  if (!group.isMember(req.userId)) {
    throw new AppError('You are not a member of this group', 403);
  }

  // Get user's balance in this group
  const userBalance = await balanceService.getUserGroupBalance(groupId, req.userId.toString());

  // Get all group balances
  const allBalances = await balanceService.calculateGroupBalances(groupId);

  // Map balances to member info
  const memberBalances = group.members.map((member) => ({
    user: member,
    balance: Math.round((allBalances[member._id.toString()] || 0) * 100) / 100,
  }));

  res.status(200).json({
    success: true,
    data: {
      userBalance,
      memberBalances,
    },
  });
});

// @desc    Get suggested settlements (minimized)
// @route   GET /api/settlements/suggest/:groupId
// @access  Private (group member only)
const getSuggestedSettlements = asyncHandler(async (req, res) => {
  const { groupId } = req.params;

  const group = await Group.findById(groupId);
  if (!group) {
    throw new AppError('Group not found', 404);
  }

  if (!group.isMember(req.userId)) {
    throw new AppError('You are not a member of this group', 403);
  }

  const settlements = await balanceService.calculateMinimizedSettlements(groupId);

  // Populate user details
  const populatedSettlements = await Promise.all(
    settlements.map(async (s) => {
      const fromUser = await User.findById(s.from).select('name avatar');
      const toUser = await User.findById(s.to).select('name avatar upiId');

      return {
        from: fromUser,
        to: toUser,
        amount: s.amount,
        hasUpi: !!toUser.upiId,
      };
    })
  );

  res.status(200).json({
    success: true,
    data: {
      settlements: populatedSettlements,
      count: populatedSettlements.length,
    },
  });
});

// @desc    Create a settlement (initiate payment)
// @route   POST /api/settlements
// @access  Private
const createSettlement = asyncHandler(async (req, res) => {
  const { groupId, toUserId, amount } = req.body;

  const group = await Group.findById(groupId);
  if (!group) {
    throw new AppError('Group not found', 404);
  }

  if (!group.isMember(req.userId)) {
    throw new AppError('You are not a member of this group', 403);
  }

  if (!group.isMember(toUserId)) {
    throw new AppError('Recipient is not a member of this group', 400);
  }

  if (req.userId.toString() === toUserId) {
    throw new AppError('Cannot create settlement to yourself', 400);
  }

  const settlement = await Settlement.create({
    group: groupId,
    from: req.userId,
    to: toUserId,
    amount,
    status: 'pending',
  });

  await settlement.populate([
    { path: 'from', select: 'name avatar' },
    { path: 'to', select: 'name avatar upiId' },
    { path: 'group', select: 'name' },
  ]);

  res.status(201).json({
    success: true,
    message: 'Settlement created',
    data: { settlement },
  });
});

// @desc    Get UPI deep link for a settlement
// @route   GET /api/settlements/:id/upi-link
// @access  Private (from user only)
const getUpiLink = asyncHandler(async (req, res) => {
  const settlement = await Settlement.findById(req.params.id);

  if (!settlement) {
    throw new AppError('Settlement not found', 404);
  }

  if (settlement.from.toString() !== req.userId.toString()) {
    throw new AppError('Only the payer can get the UPI link', 403);
  }

  if (settlement.status === 'confirmed') {
    throw new AppError('Settlement already confirmed', 400);
  }

  const upiData = await settlementService.generateUpiDeepLink(
    settlement.to,
    settlement.amount,
    `ClearDues: Settlement`
  );

  res.status(200).json({
    success: true,
    data: upiData,
  });
});

// @desc    Mark settlement as paid
// @route   PUT /api/settlements/:id/pay
// @access  Private (from user only)
const markAsPaid = asyncHandler(async (req, res) => {
  const { transactionId } = req.body;

  const settlement = await Settlement.findById(req.params.id);

  if (!settlement) {
    throw new AppError('Settlement not found', 404);
  }

  if (settlement.from.toString() !== req.userId.toString()) {
    throw new AppError('Only the payer can mark as paid', 403);
  }

  if (settlement.status === 'confirmed') {
    throw new AppError('Settlement already confirmed', 400);
  }

  await settlement.markAsPaid(transactionId);

  await settlement.populate([
    { path: 'from', select: 'name avatar' },
    { path: 'to', select: 'name avatar' },
  ]);

  res.status(200).json({
    success: true,
    message: 'Settlement marked as paid. Waiting for confirmation.',
    data: { settlement },
  });
});

// @desc    Confirm settlement (by receiver)
// @route   PUT /api/settlements/:id/confirm
// @access  Private (to user only)
const confirmSettlement = asyncHandler(async (req, res) => {
  const settlement = await Settlement.findById(req.params.id);

  if (!settlement) {
    throw new AppError('Settlement not found', 404);
  }

  if (settlement.to.toString() !== req.userId.toString()) {
    throw new AppError('Only the receiver can confirm', 403);
  }

  if (settlement.status !== 'paid') {
    throw new AppError('Settlement must be marked as paid first', 400);
  }

  await settlement.confirm();

  await settlement.populate([
    { path: 'from', select: 'name avatar' },
    { path: 'to', select: 'name avatar' },
  ]);

  res.status(200).json({
    success: true,
    message: 'Settlement confirmed',
    data: { settlement },
  });
});

// @desc    Reject settlement (by receiver)
// @route   PUT /api/settlements/:id/reject
// @access  Private (to user only)
const rejectSettlement = asyncHandler(async (req, res) => {
  const settlement = await Settlement.findById(req.params.id);

  if (!settlement) {
    throw new AppError('Settlement not found', 404);
  }

  if (settlement.to.toString() !== req.userId.toString()) {
    throw new AppError('Only the receiver can reject', 403);
  }

  if (settlement.status === 'confirmed') {
    throw new AppError('Cannot reject confirmed settlement', 400);
  }

  await settlement.reject();

  res.status(200).json({
    success: true,
    message: 'Settlement rejected',
  });
});

// @desc    Get my pending settlements
// @route   GET /api/settlements/my/pending
// @access  Private
const getMyPendingSettlements = asyncHandler(async (req, res) => {
  const settlements = await settlementService.getPendingSettlements(req.userId);

  res.status(200).json({
    success: true,
    data: { settlements },
  });
});

// @desc    Get settlements I need to confirm
// @route   GET /api/settlements/my/to-confirm
// @access  Private
const getSettlementsToConfirm = asyncHandler(async (req, res) => {
  const settlements = await settlementService.getSettlementsToConfirm(req.userId);

  res.status(200).json({
    success: true,
    data: { settlements },
  });
});

// @desc    Get all settlements for a group
// @route   GET /api/settlements/group/:groupId
// @access  Private (group member only)
const getGroupSettlements = asyncHandler(async (req, res) => {
  const { groupId } = req.params;
  const { status } = req.query;

  const group = await Group.findById(groupId);
  if (!group) {
    throw new AppError('Group not found', 404);
  }

  if (!group.isMember(req.userId)) {
    throw new AppError('You are not a member of this group', 403);
  }

  const query = { group: groupId };
  if (status) {
    query.status = status;
  }

  const settlements = await Settlement.find(query)
    .populate('from', 'name avatar')
    .populate('to', 'name avatar')
    .sort({ createdAt: -1 });

  res.status(200).json({
    success: true,
    data: { settlements },
  });
});

// @desc    Get dashboard summary for user
// @route   GET /api/settlements/dashboard
// @access  Private
const getDashboard = asyncHandler(async (req, res) => {
  const groups = await Group.find({
    members: req.userId,
    isActive: true,
  }).populate('members', 'name avatar');

  // Calculate overall balance
  const overallBalance = await balanceService.getUserOverallBalance(
    req.userId.toString(),
    groups
  );

  // Get pending settlements count
  const pendingCount = await Settlement.countDocuments({
    from: req.userId,
    status: 'pending',
  });

  const toConfirmCount = await Settlement.countDocuments({
    to: req.userId,
    status: 'paid',
  });

  // Get group-wise balances
  const groupBalances = await Promise.all(
    groups.map(async (group) => {
      const balance = await balanceService.getUserGroupBalance(
        group._id,
        req.userId.toString()
      );
      return {
        group: {
          _id: group._id,
          name: group.name,
          memberCount: group.members.length,
        },
        ...balance,
      };
    })
  );

  res.status(200).json({
    success: true,
    data: {
      overview: {
        youOwe: overallBalance.totalOwed,
        youAreOwed: overallBalance.totalOwedBy,
        netBalance: overallBalance.netBalance,
      },
      pendingSettlements: pendingCount,
      settlementsToConfirm: toConfirmCount,
      groupBalances,
    },
  });
});

module.exports = {
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
};
