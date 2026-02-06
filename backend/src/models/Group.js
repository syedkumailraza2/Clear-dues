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

// Check if user is a member (handles both populated and non-populated)
groupSchema.methods.isMember = function (userId) {
  return this.members.some((member) => {
    // Handle populated member (object with _id) or unpopulated (just ObjectId)
    const memberId = member._id ? member._id.toString() : member.toString();
    return memberId === userId.toString();
  });
};

// Check if user is admin (creator) - handles both populated and non-populated
groupSchema.methods.isAdmin = function (userId) {
  const creatorId = this.createdBy._id ? this.createdBy._id.toString() : this.createdBy.toString();
  return creatorId === userId.toString();
};

module.exports = mongoose.model('Group', groupSchema);
