import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/api_client.dart';
import '../../data/datasources/datasources.dart';

// Core providers
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Datasource providers
final authDatasourceProvider = Provider<AuthDatasource>((ref) {
  return AuthDatasource(ref.watch(apiClientProvider));
});

final userDatasourceProvider = Provider<UserDatasource>((ref) {
  return UserDatasource(ref.watch(apiClientProvider));
});

final groupDatasourceProvider = Provider<GroupDatasource>((ref) {
  return GroupDatasource(ref.watch(apiClientProvider));
});

final expenseDatasourceProvider = Provider<ExpenseDatasource>((ref) {
  return ExpenseDatasource(ref.watch(apiClientProvider));
});

final settlementDatasourceProvider = Provider<SettlementDatasource>((ref) {
  return SettlementDatasource(ref.watch(apiClientProvider));
});
