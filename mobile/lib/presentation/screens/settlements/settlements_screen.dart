import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/upi_service.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class SettlementsScreen extends ConsumerStatefulWidget {
  const SettlementsScreen({super.key});

  @override
  ConsumerState<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends ConsumerState<SettlementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlements'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'To Pay'),
            Tab(text: 'To Confirm'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ToPayTab(),
          _ToConfirmTab(),
        ],
      ),
    );
  }
}

/// Tab showing settlements the user needs to pay
class _ToPayTab extends ConsumerWidget {
  const _ToPayTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementsAsync = ref.watch(pendingSettlementsProvider);

    return settlementsAsync.when(
      loading: () => const LoadingIndicator(message: 'Loading settlements...'),
      error: (error, _) => ErrorDisplay(
        message: error.toString(),
        onRetry: () => ref.invalidate(pendingSettlementsProvider),
      ),
      data: (settlements) {
        if (settlements.isEmpty) {
          return const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'All caught up!',
            subtitle: 'You have no pending payments',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingSettlementsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: settlements.length,
            itemBuilder: (context, index) {
              final settlement = settlements[index];
              return _SettlementPayCard(settlement: settlement);
            },
          ),
        );
      },
    );
  }
}

/// Tab showing settlements the user needs to confirm
class _ToConfirmTab extends ConsumerWidget {
  const _ToConfirmTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementsAsync = ref.watch(settlementsToConfirmProvider);

    return settlementsAsync.when(
      loading: () => const LoadingIndicator(message: 'Loading...'),
      error: (error, _) => ErrorDisplay(
        message: error.toString(),
        onRetry: () => ref.invalidate(settlementsToConfirmProvider),
      ),
      data: (settlements) {
        if (settlements.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'No pending confirmations',
            subtitle: 'Payments you receive will appear here',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(settlementsToConfirmProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: settlements.length,
            itemBuilder: (context, index) {
              final settlement = settlements[index];
              return _SettlementConfirmCard(settlement: settlement);
            },
          ),
        );
      },
    );
  }
}

/// Card for settlements user needs to pay
class _SettlementPayCard extends ConsumerStatefulWidget {
  final Settlement settlement;

  const _SettlementPayCard({required this.settlement});

  @override
  ConsumerState<_SettlementPayCard> createState() => _SettlementPayCardState();
}

class _SettlementPayCardState extends ConsumerState<_SettlementPayCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final settlement = widget.settlement;
    final isPaid = settlement.isPaid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                UserAvatar(name: settlement.to.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pay ${settlement.to.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (settlement.group != null)
                        Text(
                          settlement.group!.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatCurrency(settlement.amount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.negativeBalance,
                      ),
                    ),
                    _buildStatusChip(settlement.status),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Actions
            if (isPaid)
              const Center(
                child: Text(
                  'Waiting for confirmation from payee',
                  style: TextStyle(
                    color: AppTheme.warningColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _showManualPaymentDialog(context),
                      icon: const Icon(Icons.edit),
                      label: const Text('Mark Paid'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _payWithUpi(),
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.payment),
                      label: const Text('Pay via UPI'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = AppTheme.warningColor;
        label = 'Pending';
        break;
      case 'paid':
        color = AppTheme.secondaryColor;
        label = 'Paid';
        break;
      case 'confirmed':
        color = AppTheme.successColor;
        label = 'Confirmed';
        break;
      default:
        color = AppTheme.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _payWithUpi() async {
    setState(() => _isProcessing = true);

    try {
      // Get UPI link from backend
      final upiData = await ref
          .read(settlementActionsProvider.notifier)
          .getUpiLink(widget.settlement.id);

      if (upiData == null) {
        _showError('Could not get payment link. Payee may not have UPI ID set up.');
        return;
      }

      // Launch UPI app
      final result = await UpiService.launchFromDeepLink(upiData.deepLink);

      if (!result.success) {
        _showError(result.message);
        return;
      }

      // Show confirmation dialog after returning from UPI app
      if (mounted) {
        _showPaymentConfirmationDialog();
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showPaymentConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Payment Status'),
          content: const Text(
            'Did you complete the payment successfully?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Payment was cancelled or failed
              },
              child: const Text('No, Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _markAsPaid();
              },
              child: const Text('Yes, Paid'),
            ),
          ],
        );
      },
    );
  }

  void _showManualPaymentDialog(BuildContext context) {
    final transactionIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mark as Paid'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'If you paid outside the app, enter the transaction ID (optional):',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: transactionIdController,
                decoration: const InputDecoration(
                  labelText: 'Transaction ID (Optional)',
                  hintText: 'e.g., UPI123456789',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _markAsPaid(transactionId: transactionIdController.text);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markAsPaid({String? transactionId}) async {
    setState(() => _isProcessing = true);

    try {
      final success = await ref
          .read(settlementActionsProvider.notifier)
          .markAsPaid(
            widget.settlement.id,
            transactionId: transactionId?.isNotEmpty == true ? transactionId : null,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment marked as paid. Waiting for confirmation.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

/// Card for settlements user needs to confirm
class _SettlementConfirmCard extends ConsumerStatefulWidget {
  final Settlement settlement;

  const _SettlementConfirmCard({required this.settlement});

  @override
  ConsumerState<_SettlementConfirmCard> createState() =>
      _SettlementConfirmCardState();
}

class _SettlementConfirmCardState extends ConsumerState<_SettlementConfirmCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final settlement = widget.settlement;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                UserAvatar(name: settlement.from.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${settlement.from.name} paid you',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (settlement.group != null)
                        Text(
                          settlement.group!.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      if (settlement.paidAt != null)
                        Text(
                          'Paid on ${Formatters.formatDateTime(settlement.paidAt!)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textHint,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  Formatters.formatCurrency(settlement.amount),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.positiveBalance,
                  ),
                ),
              ],
            ),

            if (settlement.upiTransactionId != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Transaction ID: ${settlement.upiTransactionId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : () => _rejectPayment(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _confirmPayment(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                    ),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPayment() async {
    setState(() => _isProcessing = true);

    try {
      final success = await ref
          .read(settlementActionsProvider.notifier)
          .confirmSettlement(widget.settlement.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment confirmed!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectPayment() async {
    // Confirm rejection
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Payment?'),
          content: const Text(
            'Are you sure you want to reject this payment? '
            'The payer will be notified.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final success = await ref
          .read(settlementActionsProvider.notifier)
          .rejectSettlement(widget.settlement.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment rejected'),
          ),
        );
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
