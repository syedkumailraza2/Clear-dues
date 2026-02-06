const mongoose = require('mongoose');

const splitSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    amount: {
      type: Number,
      required: true,
      min: [0, 'Split amount cannot be negative'],
    },
    percentage: {
      type: Number,
      min: [0, 'Percentage cannot be negative'],
      max: [100, 'Percentage cannot exceed 100'],
    },
  },
  { _id: false }
);

const expenseSchema = new mongoose.Schema(
  {
    group: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Group',
      required: [true, 'Group is required'],
    },
    description: {
      type: String,
      required: [true, 'Expense description is required'],
      trim: true,
      maxlength: [100, 'Description cannot exceed 100 characters'],
    },
    amount: {
      type: Number,
      required: [true, 'Amount is required'],
      min: [0.01, 'Amount must be at least 0.01'],
    },
    paidBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Payer is required'],
    },
    splitType: {
      type: String,
      enum: ['equal', 'unequal', 'percentage'],
      default: 'equal',
    },
    splits: [splitSchema],
    notes: {
      type: String,
      trim: true,
      maxlength: [500, 'Notes cannot exceed 500 characters'],
    },
    category: {
      type: String,
      enum: [
        'food',
        'transport',
        'shopping',
        'entertainment',
        'utilities',
        'rent',
        'travel',
        'other',
      ],
      default: 'other',
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    isDeleted: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for faster queries
expenseSchema.index({ group: 1, createdAt: -1 });
expenseSchema.index({ paidBy: 1 });
expenseSchema.index({ 'splits.user': 1 });

// Validate splits sum equals total amount
expenseSchema.pre('save', function (next) {
  if (this.splits && this.splits.length > 0) {
    const splitsTotal = this.splits.reduce((sum, split) => sum + split.amount, 0);

    // Allow small floating point differences (up to 1 paisa)
    if (Math.abs(splitsTotal - this.amount) > 0.01) {
      return next(new Error('Splits total must equal the expense amount'));
    }
  }
  next();
});

// Static method to calculate equal splits
expenseSchema.statics.calculateEqualSplits = function (amount, userIds) {
  const splitAmount = Math.round((amount / userIds.length) * 100) / 100;
  const remainder = Math.round((amount - splitAmount * userIds.length) * 100) / 100;

  return userIds.map((userId, index) => ({
    user: userId,
    amount: index === 0 ? splitAmount + remainder : splitAmount,
  }));
};

// Static method to calculate percentage splits
expenseSchema.statics.calculatePercentageSplits = function (amount, percentages) {
  return percentages.map(({ userId, percentage }) => ({
    user: userId,
    amount: Math.round((amount * percentage / 100) * 100) / 100,
    percentage,
  }));
};

module.exports = mongoose.model('Expense', expenseSchema);
