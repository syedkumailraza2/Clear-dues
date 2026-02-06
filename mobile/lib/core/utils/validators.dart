class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final _phoneRegex = RegExp(r'^[6-9]\d{9}$');
  static final _upiRegex = RegExp(r'^[\w.-]+@[\w]+$');

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validate phone number (Indian)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!_phoneRegex.hasMatch(value)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Name cannot exceed 50 characters';
    }
    return null;
  }

  /// Validate UPI ID
  static String? validateUpiId(String? value) {
    if (value == null || value.isEmpty) {
      return null; // UPI is optional
    }
    if (!_upiRegex.hasMatch(value)) {
      return 'Please enter a valid UPI ID (e.g., name@upi)';
    }
    return null;
  }

  /// Validate amount
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    return null;
  }

  /// Validate group name
  static String? validateGroupName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Group name is required';
    }
    if (value.length < 2) {
      return 'Group name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Group name cannot exceed 50 characters';
    }
    return null;
  }

  /// Validate description
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    if (value.length > 100) {
      return 'Description cannot exceed 100 characters';
    }
    return null;
  }

  /// Validate invite code
  static String? validateInviteCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Invite code is required';
    }
    if (value.length != 8) {
      return 'Invite code must be 8 characters';
    }
    return null;
  }
}
