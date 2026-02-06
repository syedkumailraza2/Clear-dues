const { User } = require('../models');
const { asyncHandler, AppError } = require('../middleware');

// @desc    Update user profile
// @route   PUT /api/users/profile
// @access  Private
const updateProfile = asyncHandler(async (req, res) => {
  const { name, upiId, avatar } = req.body;

  const updateFields = {};
  if (name) updateFields.name = name;
  if (upiId !== undefined) updateFields.upiId = upiId;
  if (avatar !== undefined) updateFields.avatar = avatar;

  const user = await User.findByIdAndUpdate(
    req.userId,
    { $set: updateFields },
    { new: true, runValidators: true }
  );

  res.status(200).json({
    success: true,
    message: 'Profile updated successfully',
    data: { user },
  });
});

// @desc    Search users by email or phone
// @route   GET /api/users/search
// @access  Private
const searchUsers = asyncHandler(async (req, res) => {
  const { query } = req.query;

  if (!query || query.length < 3) {
    throw new AppError('Search query must be at least 3 characters', 400);
  }

  const users = await User.find({
    _id: { $ne: req.userId },
    $or: [
      { email: { $regex: query, $options: 'i' } },
      { phone: { $regex: query, $options: 'i' } },
      { name: { $regex: query, $options: 'i' } },
    ],
  })
    .select('name email phone avatar')
    .limit(10);

  res.status(200).json({
    success: true,
    data: { users },
  });
});

// @desc    Get user by ID
// @route   GET /api/users/:id
// @access  Private
const getUserById = asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.id).select('name email avatar');

  if (!user) {
    throw new AppError('User not found', 404);
  }

  res.status(200).json({
    success: true,
    data: { user },
  });
});

module.exports = {
  updateProfile,
  searchUsers,
  getUserById,
};
