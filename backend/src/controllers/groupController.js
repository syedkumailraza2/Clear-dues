const { Group, User } = require('../models');
const { asyncHandler, AppError } = require('../middleware');

// @desc    Create a new group
// @route   POST /api/groups
// @access  Private
const createGroup = asyncHandler(async (req, res) => {
  const { name, description, icon, memberIds } = req.body;

  // Start with creator as member
  const members = [req.userId];

  // Add other members if provided
  if (memberIds && memberIds.length > 0) {
    // Validate member IDs exist
    const validMembers = await User.find({ _id: { $in: memberIds } }).select('_id');
    const validMemberIds = validMembers.map((m) => m._id.toString());

    memberIds.forEach((id) => {
      if (validMemberIds.includes(id) && id !== req.userId.toString()) {
        members.push(id);
      }
    });
  }

  const group = await Group.create({
    name,
    description,
    icon,
    members,
    createdBy: req.userId,
  });

  await group.populate('members', 'name email avatar');

  res.status(201).json({
    success: true,
    message: 'Group created successfully',
    data: { group },
  });
});

// @desc    Get all groups for current user
// @route   GET /api/groups
// @access  Private
const getMyGroups = asyncHandler(async (req, res) => {
  const groups = await Group.find({
    members: req.userId,
    isActive: true,
  })
    .populate('members', 'name email avatar')
    .populate('createdBy', 'name')
    .sort({ updatedAt: -1 });

  res.status(200).json({
    success: true,
    data: { groups },
  });
});

// @desc    Get single group by ID
// @route   GET /api/groups/:id
// @access  Private (member only)
const getGroup = asyncHandler(async (req, res) => {
  const group = await Group.findById(req.params.id)
    .populate('members', 'name email phone avatar upiId')
    .populate('createdBy', 'name');

  if (!group) {
    throw new AppError('Group not found', 404);
  }

  if (!group.isMember(req.userId)) {
    throw new AppError('You are not a member of this group', 403);
  }

  res.status(200).json({
    success: true,
    data: { group },
  });
});

// @desc    Update group
// @route   PUT /api/groups/:id
// @access  Private (admin only)
const updateGroup = asyncHandler(async (req, res) => {
  const { name, description, icon } = req.body;

  let group = await Group.findById(req.params.id);

  if (!group) {
    throw new AppError('Group not found', 404);
  }

  if (!group.isAdmin(req.userId)) {
    throw new AppError('Only group admin can update the group', 403);
  }

  group = await Group.findByIdAndUpdate(
    req.params.id,
    { name, description, icon },
    { new: true, runValidators: true }
  ).populate('members', 'name email avatar');

  res.status(200).json({
    success: true,
    message: 'Group updated successfully',
    data: { group },
  });
});

// @desc    Delete group (soft delete)
// @route   DELETE /api/groups/:id
// @access  Private (admin only)
const deleteGroup = asyncHandler(async (req, res) => {
  const group = await Group.findById(req.params.id);

  if (!group) {
    throw new AppError('Group not found', 404);
  }

  if (!group.isAdmin(req.userId)) {
    throw new AppError('Only group admin can delete the group', 403);
  }

  group.isActive = false;
  await group.save();

  res.status(200).json({
    success: true,
    message: 'Group deleted successfully',
  });
});

// @desc    Join group via invite code
// @route   POST /api/groups/join/:inviteCode
// @access  Private
const joinGroup = asyncHandler(async (req, res) => {
  const group = await Group.findOne({
    inviteCode: req.params.inviteCode,
    isActive: true,
  });

  if (!group) {
    throw new AppError('Invalid invite code', 404);
  }

  if (group.isMember(req.userId)) {
    throw new AppError('You are already a member of this group', 400);
  }

  group.members.push(req.userId);
  await group.save();

  await group.populate('members', 'name email avatar');

  res.status(200).json({
    success: true,
    message: 'Successfully joined the group',
    data: { group },
  });
});

// @desc    Add member to group
// @route   POST /api/groups/:id/members
// @access  Private (admin only)
const addMember = asyncHandler(async (req, res) => {
  const { userId } = req.body;

  const group = await Group.findById(req.params.id);

  if (!group) {
    throw new AppError('Group not found', 404);
  }

  if (!group.isAdmin(req.userId)) {
    throw new AppError('Only group admin can add members', 403);
  }

  // Validate user exists
  const user = await User.findById(userId);
  if (!user) {
    throw new AppError('User not found', 404);
  }

  if (group.isMember(userId)) {
    throw new AppError('User is already a member', 400);
  }

  group.members.push(userId);
  await group.save();

  await group.populate('members', 'name email avatar');

  res.status(200).json({
    success: true,
    message: 'Member added successfully',
    data: { group },
  });
});

// @desc    Remove member from group
// @route   DELETE /api/groups/:id/members/:userId
// @access  Private (admin only, or self)
const removeMember = asyncHandler(async (req, res) => {
  const group = await Group.findById(req.params.id);
  const targetUserId = req.params.userId;

  if (!group) {
    throw new AppError('Group not found', 404);
  }

  const isAdmin = group.isAdmin(req.userId);
  const isSelf = req.userId.toString() === targetUserId;

  if (!isAdmin && !isSelf) {
    throw new AppError('Not authorized to remove this member', 403);
  }

  // Cannot remove the admin
  if (group.isAdmin(targetUserId)) {
    throw new AppError('Cannot remove group admin', 400);
  }

  if (!group.isMember(targetUserId)) {
    throw new AppError('User is not a member of this group', 400);
  }

  group.members = group.members.filter(
    (member) => member.toString() !== targetUserId
  );
  await group.save();

  await group.populate('members', 'name email avatar');

  res.status(200).json({
    success: true,
    message: 'Member removed successfully',
    data: { group },
  });
});

// @desc    Get group invite link
// @route   GET /api/groups/:id/invite
// @access  Private (member only)
const getInviteLink = asyncHandler(async (req, res) => {
  const group = await Group.findById(req.params.id);

  if (!group) {
    throw new AppError('Group not found', 404);
  }

  if (!group.isMember(req.userId)) {
    throw new AppError('You are not a member of this group', 403);
  }

  res.status(200).json({
    success: true,
    data: {
      inviteCode: group.inviteCode,
    },
  });
});

module.exports = {
  createGroup,
  getMyGroups,
  getGroup,
  updateGroup,
  deleteGroup,
  joinGroup,
  addMember,
  removeMember,
  getInviteLink,
};
