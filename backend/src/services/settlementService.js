const { Settlement, User } = require('../models');

/**
 * Generate UPI deep link for payment
 * UPI URL format: upi://pay?pa=<UPI_ID>&pn=<NAME>&am=<AMOUNT>&cu=INR&tn=<NOTE>
 */
const generateUpiDeepLink = async (payeeId, amount, note = 'ClearDues Settlement') => {
  const payee = await User.findById(payeeId);

  if (!payee) {
    throw new Error('Payee not found');
  }

  if (!payee.upiId) {
    throw new Error('Payee has not set up UPI ID');
  }

  const params = new URLSearchParams({
    pa: payee.upiId,
    pn: payee.name,
    am: amount.toFixed(2),
    cu: 'INR',
    tn: note,
  });

  return {
    deepLink: `upi://pay?${params.toString()}`,
    payee: {
      id: payee._id,
      name: payee.name,
      upiId: payee.upiId,
    },
    amount,
  };
};

/**
 * Create settlement records from minimized settlements
 */
const createSettlementRecords = async (groupId, settlements) => {
  const records = [];

  for (const settlement of settlements) {
    const record = await Settlement.create({
      group: groupId,
      from: settlement.from,
      to: settlement.to,
      amount: settlement.amount,
      status: 'pending',
    });

    records.push(record);
  }

  return records;
};

/**
 * Get pending settlements for a user (where they need to pay)
 */
const getPendingSettlements = async (userId) => {
  return Settlement.find({
    from: userId,
    status: { $in: ['pending', 'paid'] },
  })
    .populate('to', 'name upiId avatar')
    .populate('group', 'name')
    .sort({ createdAt: -1 });
};

/**
 * Get settlements where user needs to confirm receipt
 */
const getSettlementsToConfirm = async (userId) => {
  return Settlement.find({
    to: userId,
    status: 'paid',
  })
    .populate('from', 'name avatar')
    .populate('group', 'name')
    .sort({ paidAt: -1 });
};

module.exports = {
  generateUpiDeepLink,
  createSettlementRecords,
  getPendingSettlements,
  getSettlementsToConfirm,
};
