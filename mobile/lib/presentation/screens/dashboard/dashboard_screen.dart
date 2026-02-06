import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).fetchDashboard();
      ref.read(groupsProvider.notifier).fetchGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Clear Dues'),
            if (user != null)
              Text(
                'Hi, ${user.name.split(' ').first}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).fetchDashboard();
          await ref.read(groupsProvider.notifier).fetchGroups();
        },
        child: dashboardState.isLoading && dashboardState.data == null
            ? const LoadingIndicator(message: 'Loading dashboard...')
            : dashboardState.error != null && dashboardState.data == null
                ? ErrorDisplay(
                    message: dashboardState.error!,
                    onRetry: () => ref.read(dashboardProvider.notifier).fetchDashboard(),
                  )
                : _buildContent(dashboardState),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break; // Already on dashboard
            case 1:
              context.push('/groups');
              break;
            case 2:
              context.push('/settlements');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Settle',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DashboardState state) {
    final data = state.data;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance overview
          _buildBalanceOverview(data),
          const SizedBox(height: 24),

          // Pending actions
          if ((data?.pendingSettlements ?? 0) > 0 ||
              (data?.settlementsToConfirm ?? 0) > 0)
            _buildPendingActions(data),

          // Group balances
          const Text(
            'Group Balances',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildGroupBalances(data),
        ],
      ),
    );
  }

  Widget _buildBalanceOverview(data) {
    final youOwe = data?.youOwe ?? 0.0;
    final youAreOwed = data?.youAreOwed ?? 0.0;
    final netBalance = data?.netBalance ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: BalanceCard(
                    title: 'You owe',
                    amount: youOwe,
                    isPositive: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BalanceCard(
                    title: 'You are owed',
                    amount: youAreOwed,
                    isPositive: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Net Balance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  Formatters.formatCurrencyWithSign(netBalance),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: netBalance >= 0
                        ? AppTheme.positiveBalance
                        : AppTheme.negativeBalance,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingActions(data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if ((data?.pendingSettlements ?? 0) > 0)
            _buildActionCard(
              icon: Icons.payment,
              title: 'Pending Payments',
              subtitle: '${data?.pendingSettlements} payment(s) to make',
              color: AppTheme.warningColor,
              onTap: () => context.push('/settlements'),
            ),
          if ((data?.settlementsToConfirm ?? 0) > 0)
            _buildActionCard(
              icon: Icons.check_circle,
              title: 'Confirm Payments',
              subtitle: '${data?.settlementsToConfirm} payment(s) to confirm',
              color: AppTheme.secondaryColor,
              onTap: () => context.push('/settlements'),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildGroupBalances(data) {
    final groupBalances = data?.groupBalances ?? [];

    if (groupBalances.isEmpty) {
      return const EmptyState(
        icon: Icons.group_add,
        title: 'No groups yet',
        subtitle: 'Create or join a group to start splitting expenses',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupBalances.length,
      itemBuilder: (context, index) {
        final group = groupBalances[index];
        final netBalance = group.netBalance;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryLight,
              child: Text(
                Formatters.getInitials(group.groupName),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(group.groupName),
            subtitle: Text('${group.memberCount} members'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrencyWithSign(netBalance),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: netBalance >= 0
                        ? AppTheme.positiveBalance
                        : AppTheme.negativeBalance,
                  ),
                ),
                Text(
                  netBalance >= 0 ? 'you get back' : 'you owe',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            onTap: () => context.push('/groups/${group.groupId}'),
          ),
        );
      },
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primaryLight,
                    child: Icon(Icons.group_add, color: Colors.white),
                  ),
                  title: const Text('Create Group'),
                  subtitle: const Text('Start a new expense group'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/groups/create');
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.secondaryColor,
                    child: Icon(Icons.link, color: Colors.white),
                  ),
                  title: const Text('Join Group'),
                  subtitle: const Text('Join using invite code'),
                  onTap: () {
                    Navigator.pop(context);
                    _showJoinGroupDialog(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showJoinGroupDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Join Group'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Invite Code',
              hintText: 'Enter 8-character code',
            ),
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.length == 8) {
                  Navigator.pop(context);
                  final group = await ref
                      .read(groupsProvider.notifier)
                      .joinGroup(controller.text);
                  if (group != null && mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Joined ${group.name}')),
                    );
                  }
                }
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
  }
}
