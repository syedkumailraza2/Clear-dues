const mongoose = require('mongoose');

const settlementSchema = new mongoose.Schema(
  {
    group: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Group',
      required: [true, 'Group is required'],
    },
    from: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Payer (from) is required'],
    },
    to: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Payee (to) is required'],
    },
    amount: {
      type: Number,
      required: [true, 'Amount is required'],
      min: [0.01, 'Amount must be at least 0.01'],
    },
    status: {
      type: String,
      enum: ['pending', 'paid', 'confirmed', 'rejected'],
      default: 'pending',
    },
    upiTransactionId: {
      type: String,
      trim: true,
    },
    paidAt: {
      type: Date,
    },
    confirmedAt: {
      type: Date,
    },
    notes: {
      type: String,
      trim: true,
      maxlength: [200, 'Notes cannot exceed 200 characters'],
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for faster queries
settlementSchema.index({ group: 1, status: 1 });
settlementSchema.index({ from: 1, status: 1 });
settlementSchema.index({ to: 1, status: 1 });
settlementSchema.index({ createdAt: -1 });

// Ensure from and to are different users
settlementSchema.pre('save', function (next) {
  if (this.from.toString() === this.to.toString()) {
    return next(new Error('Payer and payee cannot be the same user'));
  }
  next();
});

// Mark as paid
settlementSchema.methods.markAsPaid = function (transactionId = null) {
  this.status = 'paid';
  this.paidAt = new Date();
  if (transactionId) {
    this.upiTransactionId = transactionId;
  }
  return this.save();
};

// Confirm settlement (by payee)
settlementSchema.methods.confirm = function () {
  this.status = 'confirmed';
  this.confirmedAt = new Date();
  return this.save();
};

// Reject settlement
settlementSchema.methods.reject = function () {
  this.status = 'rejected';
  this.paidAt = null;
  this.upiTransactionId = null;
  return this.save();
};

// Generate UPI deep link
settlementSchema.methods.generateUpiLink = async function () {
  await this.populate('to', 'upiId name');

  if (!this.to.upiId) {
    throw new Error('Payee has not set up UPI ID');
  }

  const params = new URLSearchParams({
    pa: this.to.upiId,
    pn: this.to.name,
    am: this.amount.toFixed(2),
    cu: 'INR',
    tn: `ClearDues Settlement`,
  });

  return `upi://pay?${params.toString()}`;
};

module.exports = mongoose.model('Settlement', settlementSchema);
