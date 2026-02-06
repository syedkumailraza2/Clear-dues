class ApiConstants {
  ApiConstants._();

  // Base URL - Production by default
  // Use --dart-define=API_URL=http://10.0.2.2:3000/api for local development
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://clear-dues-chi.vercel.app/api',
  );

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
