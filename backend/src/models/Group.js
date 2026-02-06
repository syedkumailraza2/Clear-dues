const mongoose = require('mongoose');

const groupSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Group name is required'],
      trim: true,
      minlength: [2, 'Group name must be at least 2 characters'],
      maxlength: [50, 'Group name cannot exceed 50 characters'],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [200, 'Description cannot exceed 200 characters'],
    },
    icon: {
      type: String,
      default: 'group',
    },
    members: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
      },
    ],
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Group creator is required'],
    },
    inviteCode: {
      type: String,
      unique: true,
      sparse: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for faster queries
groupSchema.index({ members: 1 });
groupSchema.index({ createdBy: 1 });
groupSchema.index({ inviteCode: 1 });

// Generate unique invite code
groupSchema.pre('save', async function (next) {
  if (!this.inviteCode) {
    this.inviteCode = generateInviteCode();
  }
  next();
});

function generateInviteCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

// Virtual for member count
groupSchema.virtual('memberCount').get(function () {
  return this.members.length;
});

// Ensure virtuals are included in JSON
groupSchema.set('toJSON', { virtuals: true });
groupSchema.set('toObject', { virtuals: true });

// Check if user is a member
groupSchema.methods.isMember = function (userId) {
  return this.members.some((member) => member.toString() === userId.toString());
};

// Check if user is admin (creator)
groupSchema.methods.isAdmin = function (userId) {
  return this.createdBy.toString() === userId.toString();
};

module.exports = mongoose.model('Group', groupSchema);
