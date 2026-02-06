import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(expensesProvider(widget.groupId).notifier).fetchExpenses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));
    final expensesState = ref.watch(expensesProvider(widget.groupId));

    return groupAsync.when(
      loading: () => const Scaffold(
        body: LoadingIndicator(message: 'Loading group...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.invalidate(groupDetailProvider(widget.groupId)),
        ),
      ),
      data: (group) => Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _showInviteDialog(context),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'settings':
                    // TODO: Navigate to group settings
                    break;
                  case 'leave':
                    _confirmLeaveGroup(context, group);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'settings',
                  child: Text('Group Settings'),
                ),
                const PopupMenuItem(
                  value: 'leave',
                  child: Text('Leave Group'),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Expenses'),
              Tab(text: 'Balances'),
              Tab(text: 'Members'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _ExpensesTab(
              groupId: widget.groupId,
              expenses: expensesState.expenses,
              isLoading: expensesState.isLoading,
            ),
            _BalancesTab(groupId: widget.groupId),
            _MembersTab(members: group.members),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/groups/${widget.groupId}/add-expense'),
          icon: const Icon(Icons.add),
          label: const Text('Add Expense'),
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext _) async {
    final inviteCode = await ref.read(groupInviteCodeProvider(widget.groupId).future);

    if (!mounted) return;

    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Invite Members'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share this code with friends to join:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      inviteCode,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copied!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _confirmLeaveGroup(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave Group'),
          content: Text('Are you sure you want to leave "${group.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              onPressed: () async {
                Navigator.pop(context);
                final user = ref.read(currentUserProvider);
                if (user != null) {
                  final success = await ref
                      .read(groupsProvider.notifier)
                      .leaveGroup(group.id, user.id);
                  if (success && mounted) {
                    this.context.pop();
                  }
                }
              },
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }
}

class _ExpensesTab extends StatelessWidget {
  final String groupId;
  final List<Expense> expenses;
  final bool isLoading;

  const _ExpensesTab({
    required this.groupId,
    required this.expenses,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && expenses.isEmpty) {
      return const LoadingIndicator();
    }

    if (expenses.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long,
        title: 'No expenses yet',
        subtitle: 'Add your first expense to start tracking',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.2),
              child: Icon(
                _getCategoryIcon(expense.category),
                color: AppTheme.primaryColor,
              ),
            ),
            title: Text(expense.description),
            subtitle: Text(
              '${expense.paidBy.name} paid • ${Formatters.formatRelativeDate(expense.createdAt)}',
            ),
            trailing: Text(
              Formatters.formatCurrency(expense.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onTap: () => context.push('/expenses/${expense.id}'),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.lightbulb;
      case 'rent':
        return Icons.home;
      case 'travel':
        return Icons.flight;
      default:
        return Icons.category;
    }
  }
}

class _BalancesTab extends ConsumerWidget {
  final String groupId;

  const _BalancesTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(groupBalancesProvider(groupId));

    return balancesAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorDisplay(
        message: error.toString(),
        onRetry: () => ref.invalidate(groupBalancesProvider(groupId)),
      ),
      data: (data) {
        final userBalance = data['userBalance'] as UserBalance;
        final memberBalances = data['memberBalances'] as List<MemberBalance>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Your balance summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Balance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: BalanceCard(
                              title: 'You owe',
                              amount: userBalance.totalOwed,
                              isPositive: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: BalanceCard(
                              title: 'You get back',
                              amount: userBalance.totalOwedBy,
                              isPositive: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Member balances
              const Text(
                'Member Balances',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...memberBalances.map((mb) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: UserAvatar(name: mb.user.name),
                      title: Text(mb.user.name),
                      trailing: Text(
                        Formatters.formatCurrencyWithSign(mb.balance),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: mb.balance >= 0
                              ? AppTheme.positiveBalance
                              : AppTheme.negativeBalance,
                        ),
                      ),
                    ),
                  )),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/groups/$groupId/settle'),
                  icon: const Icon(Icons.handshake),
                  label: const Text('Settle Up'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MembersTab extends StatelessWidget {
  final List<User> members;

  const _MembersTab({required this.members});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: UserAvatar(name: member.name),
            title: Text(member.name),
            subtitle: Text(member.email),
            trailing: member.upiId != null
                ? const Chip(
                    label: Text('UPI'),
                    backgroundColor: AppTheme.secondaryColor,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                    padding: EdgeInsets.zero,
                  )
                : null,
          ),
        );
      },
    );
  }
}
