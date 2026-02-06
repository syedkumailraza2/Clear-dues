import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/upi_service.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class SettleUpScreen extends ConsumerStatefulWidget {
  final String groupId;

  const SettleUpScreen({super.key, required this.groupId});

  @override
  ConsumerState<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends ConsumerState<SettleUpScreen> {
  @override
  Widget build(BuildContext context) {
    final suggestedAsync = ref.watch(suggestedSettlementsProvider(widget.groupId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settle Up'),
      ),
      body: suggestedAsync.when(
        loading: () => const LoadingIndicator(message: 'Calculating settlements...'),
        error: (error, _) => ErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.invalidate(suggestedSettlementsProvider(widget.groupId)),
        ),
        data: (settlements) {
          if (settlements.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle,
              title: 'All Settled!',
              subtitle: 'Everyone in this group is settled up',
            );
          }

          // Filter settlements relevant to current user
          final mySettlements = settlements.where((s) =>
              s.from.id == currentUser?.id || s.to.id == currentUser?.id).toList();

          final otherSettlements = settlements.where((s) =>
              s.from.id != currentUser?.id && s.to.id != currentUser?.id).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info card
                Card(
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryColor),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'These are optimized settlements to minimize the number of transactions.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Your settlements
                if (mySettlements.isNotEmpty) ...[
                  const Text(
                    'Your Settlements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...mySettlements.map((settlement) => _SuggestedSettlementCard(
                        settlement: settlement,
                        groupId: widget.groupId,
                        isCurrentUser: true,
                        currentUserId: currentUser?.id,
                      )),
                  const SizedBox(height: 24),
                ],

                // Other settlements
                if (otherSettlements.isNotEmpty) ...[
                  const Text(
                    'Other Settlements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Between other group members',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...otherSettlements.map((settlement) => _SuggestedSettlementCard(
                        settlement: settlement,
                        groupId: widget.groupId,
                        isCurrentUser: false,
                        currentUserId: currentUser?.id,
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SuggestedSettlementCard extends ConsumerStatefulWidget {
  final SuggestedSettlement settlement;
  final String groupId;
  final bool isCurrentUser;
  final String? currentUserId;

  const _SuggestedSettlementCard({
    required this.settlement,
    required this.groupId,
    required this.isCurrentUser,
    required this.currentUserId,
  });

  @override
  ConsumerState<_SuggestedSettlementCard> createState() =>
      _SuggestedSettlementCardState();
}

class _SuggestedSettlementCardState extends ConsumerState<_SuggestedSettlementCard> {
  bool _isProcessing = false;

  bool get _userOwes => widget.settlement.from.id == widget.currentUserId;

  @override
  Widget build(BuildContext context) {
    final settlement = widget.settlement;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // From -> To visualization
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      UserAvatar(name: settlement.from.name, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        settlement.from.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_userOwes)
                        const Text(
                          '(You)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.arrow_forward,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatCurrency(settlement.amount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      UserAvatar(name: settlement.to.name, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        settlement.to.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!_userOwes && widget.isCurrentUser)
                        const Text(
                          '(You)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Actions for current user
            if (widget.isCurrentUser && _userOwes) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (settlement.hasUpi)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _initiatePayment,
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
                        label: const Text('Pay Now'),
                      ),
                    )
                  else
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _recordPayment,
                        icon: const Icon(Icons.edit),
                        label: const Text('Record Payment'),
                      ),
                    ),
                ],
              ),
              if (!settlement.hasUpi)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Payee has not set up UPI ID',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _initiatePayment() async {
    setState(() => _isProcessing = true);

    try {
      // First create the settlement record
      final createdSettlement = await ref
          .read(settlementActionsProvider.notifier)
          .createSettlement(
            groupId: widget.groupId,
            toUserId: widget.settlement.to.id,
            amount: widget.settlement.amount,
          );

      if (createdSettlement == null) {
        _showError('Failed to create settlement');
        return;
      }

      // Get UPI link
      final upiData = await ref
          .read(settlementActionsProvider.notifier)
          .getUpiLink(createdSettlement.id);

      if (upiData == null) {
        _showError('Failed to get UPI link');
        return;
      }

      // Launch UPI app
      final result = await UpiService.launchFromDeepLink(upiData.deepLink);

      if (!result.success) {
        _showError(result.message);
        return;
      }

      // Show confirmation dialog
      if (mounted) {
        _showPaymentConfirmationDialog(createdSettlement.id);
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showPaymentConfirmationDialog(String settlementId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Payment Status'),
          content: const Text('Did you complete the payment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _markAsPaid(settlementId);
              },
              child: const Text('Yes, Paid'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markAsPaid(String settlementId) async {
    final success = await ref
        .read(settlementActionsProvider.notifier)
        .markAsPaid(settlementId);

    if (success && mounted) {
      ref.invalidate(suggestedSettlementsProvider(widget.groupId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment recorded. Waiting for confirmation.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.pop();
    }
  }

  Future<void> _recordPayment() async {
    setState(() => _isProcessing = true);

    try {
      // Create settlement record
      final settlement = await ref
          .read(settlementActionsProvider.notifier)
          .createSettlement(
            groupId: widget.groupId,
            toUserId: widget.settlement.to.id,
            amount: widget.settlement.amount,
          );

      if (settlement == null) {
        _showError('Failed to create settlement');
        return;
      }

      // Mark as paid immediately
      final success = await ref
          .read(settlementActionsProvider.notifier)
          .markAsPaid(settlement.id);

      if (success && mounted) {
        ref.invalidate(suggestedSettlementsProvider(widget.groupId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded. Waiting for confirmation.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop();
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
