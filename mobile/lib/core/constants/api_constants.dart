class ApiConstants {
  ApiConstants._();

  // Environment Configuration
  // Set this based on build variant or use --dart-define
  static const bool _isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );

  // Base URLs for different environments
  static const String _devBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/api', // Android emulator -> host machine
  );
  static const String _prodBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.cleardues.com/api', // Production URL
  );

  // Active base URL based on environment
  static String get baseUrl => _isProduction ? _prodBaseUrl : _devBaseUrl;

  // Alternative URLs for development:
  // - Android Emulator: http://10.0.2.2:3000/api
  // - iOS Simulator:    http://localhost:3000/api
  // - Physical Device:  http://<your-ip>:3000/api

  // Auth endpoints
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String me = '/auth/me';
  static const String updatePassword = '/auth/password';

  // User endpoints
  static const String userProfile = '/users/profile';
  static const String searchUsers = '/users/search';

  // Group endpoints
  static const String groups = '/groups';
  static String groupById(String id) => '/groups/$id';
  static String joinGroup(String code) => '/groups/join/$code';
  static String groupMembers(String id) => '/groups/$id/members';
  static String removeMember(String groupId, String userId) =>
      '/groups/$groupId/members/$userId';
  static String groupInvite(String id) => '/groups/$id/invite';

  // Expense endpoints
  static const String expenses = '/expenses';
  static String expenseById(String id) => '/expenses/$id';
  static String groupExpenses(String groupId) => '/expenses/group/$groupId';

  // Settlement endpoints
  static const String settlements = '/settlements';
  static const String dashboard = '/settlements/dashboard';
  static String groupBalances(String groupId) => '/settlements/balances/$groupId';
  static String suggestSettlements(String groupId) => '/settlements/suggest/$groupId';
  static String groupSettlements(String groupId) => '/settlements/group/$groupId';
  static String upiLink(String id) => '/settlements/$id/upi-link';
  static String markPaid(String id) => '/settlements/$id/pay';
  static String confirmSettlement(String id) => '/settlements/$id/confirm';
  static String rejectSettlement(String id) => '/settlements/$id/reject';
  static const String myPendingSettlements = '/settlements/my/pending';
  static const String settlementsToConfirm = '/settlements/my/to-confirm';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
