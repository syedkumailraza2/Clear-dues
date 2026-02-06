import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/providers.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/groups/groups_screen.dart';
import '../../presentation/screens/groups/group_detail_screen.dart';
import '../../presentation/screens/groups/create_group_screen.dart';
import '../../presentation/screens/expenses/add_expense_screen.dart';
import '../../presentation/screens/settlements/settlements_screen.dart';
import '../../presentation/screens/settlements/settle_up_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      // If not authenticated and not on login/signup, redirect to login
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // If authenticated and on login/signup, redirect to dashboard
      if (isAuthenticated && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // Dashboard
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // Groups
      GoRoute(
        path: '/groups',
        name: 'groups',
        builder: (context, state) => const GroupsScreen(),
      ),
      GoRoute(
        path: '/groups/create',
        name: 'createGroup',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/groups/:id',
        name: 'groupDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GroupDetailScreen(groupId: id);
        },
      ),
      GoRoute(
        path: '/groups/:id/add-expense',
        name: 'addExpense',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddExpenseScreen(groupId: id);
        },
      ),
      GoRoute(
        path: '/groups/:id/settle',
        name: 'settleUp',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SettleUpScreen(groupId: id);
        },
      ),

      // Settlements
      GoRoute(
        path: '/settlements',
        name: 'settlements',
        builder: (context, state) => const SettlementsScreen(),
      ),

      // Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
