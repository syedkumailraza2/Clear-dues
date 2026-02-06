const { Expense, Settlement } = require('../models');

/**
 * Calculate net balances for all members in a group
 * Positive balance = user is owed money
 * Negative balance = user owes money
 */
const calculateGroupBalances = async (groupId) => {
  // Get all non-deleted expenses for the group
  const expenses = await Expense.find({
    group: groupId,
    isDeleted: false,
  });

  // Get confirmed settlements
  const settlements = await Settlement.find({
    group: groupId,
    status: 'confirmed',
  });

  // Calculate net balance for each user
  const balances = {};

  // Process expenses
  for (const expense of expenses) {
    const payerId = expense.paidBy.toString();

    // Payer paid the full amount (credit)
    balances[payerId] = (balances[payerId] || 0) + expense.amount;

    // Each person in splits owes their share (debit)
    for (const split of expense.splits) {
      const userId = split.user.toString();
      balances[userId] = (balances[userId] || 0) - split.amount;
    }
  }

  // Process confirmed settlements
  for (const settlement of settlements) {
    const fromId = settlement.from.toString();
    const toId = settlement.to.toString();

    // From user paid, so their debt decreases (credit)
    balances[fromId] = (balances[fromId] || 0) + settlement.amount;
    // To user received, so their credit decreases (debit)
    balances[toId] = (balances[toId] || 0) - settlement.amount;
  }

  return balances;
};

/**
 * Calculate who owes whom between two specific users in a group
 */
const calculatePairwiseBalance = async (groupId, user1Id, user2Id) => {
  const balances = await calculateGroupBalances(groupId);

  const user1Balance = balances[user1Id] || 0;
  const user2Balance = balances[user2Id] || 0;

  // This gives us the net flow, but for pairwise we need detailed tracking
  // For simplicity, we return net balances
  return {
    [user1Id]: user1Balance,
    [user2Id]: user2Balance,
  };
};

/**
 * Get detailed balance breakdown for a user in a group
 */
const getUserGroupBalance = async (groupId, userId) => {
  const expenses = await Expense.find({
    group: groupId,
    isDeleted: false,
  }).populate('paidBy splits.user', 'name');

  const settlements = await Settlement.find({
    group: groupId,
    status: 'confirmed',
  });

  // Track what this user owes to each person and what each person owes them
  const owes = {}; // userId -> amount this user owes them
  const owedBy = {}; // userId -> amount they owe this user

  for (const expense of expenses) {
    const payerId = expense.paidBy._id.toString();
    const payerName = expense.paidBy.name;

    for (const split of expense.splits) {
      const splitUserId = split.user._id.toString();

      if (payerId === userId && splitUserId !== userId) {
        // This user paid, someone else owes them
        if (!owedBy[splitUserId]) {
          owedBy[splitUserId] = { amount: 0, name: split.user.name };
        }
        owedBy[splitUserId].amount += split.amount;
      } else if (splitUserId === userId && payerId !== userId) {
        // This user owes the payer
        if (!owes[payerId]) {
          owes[payerId] = { amount: 0, name: payerName };
        }
        owes[payerId].amount += split.amount;
      }
    }
  }

  // Apply settlements
  for (const settlement of settlements) {
    const fromId = settlement.from.toString();
    const toId = settlement.to.toString();

    if (fromId === userId && owes[toId]) {
      owes[toId].amount -= settlement.amount;
    } else if (toId === userId && owedBy[fromId]) {
      owedBy[fromId].amount -= settlement.amount;
    }
  }

  // Filter out zero or negative balances
  const filteredOwes = Object.entries(owes)
    .filter(([_, data]) => data.amount > 0.01)
    .map(([id, data]) => ({ userId: id, name: data.name, amount: Math.round(data.amount * 100) / 100 }));

  const filteredOwedBy = Object.entries(owedBy)
    .filter(([_, data]) => data.amount > 0.01)
    .map(([id, data]) => ({ userId: id, name: data.name, amount: Math.round(data.amount * 100) / 100 }));

  const totalOwed = filteredOwes.reduce((sum, item) => sum + item.amount, 0);
  const totalOwedBy = filteredOwedBy.reduce((sum, item) => sum + item.amount, 0);

  return {
    owes: filteredOwes,
    owedBy: filteredOwedBy,
    totalOwed: Math.round(totalOwed * 100) / 100,
    totalOwedBy: Math.round(totalOwedBy * 100) / 100,
    netBalance: Math.round((totalOwedBy - totalOwed) * 100) / 100,
  };
};

/**
 * Settlement Minimization Algorithm
 * Uses greedy approach to minimize number of transactions
 *
 * Algorithm:
 * 1. Calculate net balance for each person
 * 2. Separate into creditors (positive balance) and debtors (negative balance)
 * 3. Match largest debtor with largest creditor
 * 4. Transfer min(debt, credit) between them
 * 5. Repeat until all settled
 */
const calculateMinimizedSettlements = async (groupId) => {
  const balances = await calculateGroupBalances(groupId);

  // Separate into creditors and debtors
  const creditors = []; // People who are owed money
  const debtors = []; // People who owe money

  for (const [userId, balance] of Object.entries(balances)) {
    const roundedBalance = Math.round(balance * 100) / 100;

    if (roundedBalance > 0.01) {
      creditors.push({ userId, amount: roundedBalance });
    } else if (roundedBalance < -0.01) {
      debtors.push({ userId, amount: Math.abs(roundedBalance) });
    }
  }

  // Sort by amount (descending)
  creditors.sort((a, b) => b.amount - a.amount);
  debtors.sort((a, b) => b.amount - a.amount);

  const settlements = [];

  // Greedy matching
  while (creditors.length > 0 && debtors.length > 0) {
    const creditor = creditors[0];
    const debtor = debtors[0];

    const settleAmount = Math.min(creditor.amount, debtor.amount);
    const roundedAmount = Math.round(settleAmount * 100) / 100;

    if (roundedAmount > 0) {
      settlements.push({
        from: debtor.userId,
        to: creditor.userId,
        amount: roundedAmount,
      });
    }

    creditor.amount -= settleAmount;
    debtor.amount -= settleAmount;

    // Remove if settled
    if (creditor.amount < 0.01) creditors.shift();
    if (debtor.amount < 0.01) debtors.shift();
  }

  return settlements;
};

/**
 * Get overall balance summary for a user across all their groups
 */
const getUserOverallBalance = async (userId, groups) => {
  let totalOwed = 0;
  let totalOwedBy = 0;

  for (const group of groups) {
    const balance = await getUserGroupBalance(group._id, userId);
    totalOwed += balance.totalOwed;
    totalOwedBy += balance.totalOwedBy;
  }

  return {
    totalOwed: Math.round(totalOwed * 100) / 100,
    totalOwedBy: Math.round(totalOwedBy * 100) / 100,
    netBalance: Math.round((totalOwedBy - totalOwed) * 100) / 100,
  };
};

module.exports = {
  calculateGroupBalances,
  calculatePairwiseBalance,
  getUserGroupBalance,
  calculateMinimizedSettlements,
  getUserOverallBalance,
};
