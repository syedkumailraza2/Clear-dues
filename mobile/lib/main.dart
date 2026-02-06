import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ClearDuesApp(),
    ),
  );
}

class ClearDuesApp extends ConsumerStatefulWidget {
  const ClearDuesApp({super.key});

  @override
  ConsumerState<ClearDuesApp> createState() => _ClearDuesAppState();
}

class _ClearDuesAppState extends ConsumerState<ClearDuesApp> {
  @override
  void initState() {
    super.initState();
    // Check auth status on app start
    Future.microtask(() {
      ref.read(authProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Clear Dues',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
