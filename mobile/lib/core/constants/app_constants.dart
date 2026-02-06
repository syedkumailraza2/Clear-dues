class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Clear Dues';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Expense Categories
  static const List<String> expenseCategories = [
    'food',
    'transport',
    'shopping',
    'entertainment',
    'utilities',
    'rent',
    'travel',
    'other',
  ];

  // Category Icons
  static const Map<String, int> categoryIcons = {
    'food': 0xe57a, // Icons.restaurant
    'transport': 0xe1d7, // Icons.directions_car
    'shopping': 0xe8cc, // Icons.shopping_bag
    'entertainment': 0xe40f, // Icons.movie
    'utilities': 0xe30b, // Icons.lightbulb
    'rent': 0xe88a, // Icons.home
    'travel': 0xe539, // Icons.flight
    'other': 0xe8b8, // Icons.category
  };

  // Split Types
  static const String splitEqual = 'equal';
  static const String splitUnequal = 'unequal';
  static const String splitPercentage = 'percentage';

  // Settlement Status
  static const String statusPending = 'pending';
  static const String statusPaid = 'paid';
  static const String statusConfirmed = 'confirmed';
  static const String statusRejected = 'rejected';

  // Validation
  static const int minPasswordLength = 6;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // Pagination
  static const int defaultPageSize = 20;
}
