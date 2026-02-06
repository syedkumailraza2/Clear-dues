import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;

  const AddExpenseScreen({super.key, required this.groupId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCategory = 'other';
  String _splitType = 'equal';
  String? _paidBy;
  List<User> _selectedMembers = [];
  final Map<String, double> _customSplits = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));
    final currentUser = ref.watch(currentUserProvider);

    return groupAsync.when(
      loading: () => const Scaffold(
        body: LoadingIndicator(),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Add Expense')),
        body: ErrorDisplay(message: error.toString()),
      ),
      data: (group) {
        // Initialize paidBy with current user if not set
        _paidBy ??= currentUser?.id;
        if (_selectedMembers.isEmpty) {
          _selectedMembers = List.from(group.members);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Add Expense'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  AppTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'What was this expense for?',
                    validator: Validators.validateDescription,
                  ),
                  const SizedBox(height: 20),

                  // Amount
                  AppTextField(
                    controller: _amountController,
                    label: 'Amount',
                    hint: 'Enter amount',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: const Icon(Icons.currency_rupee),
                    validator: Validators.validateAmount,
                  ),
                  const SizedBox(height: 20),

                  // Category
                  _buildCategorySelector(),
                  const SizedBox(height: 20),

                  // Paid by
                  _buildPaidBySelector(group.members),
                  const SizedBox(height: 20),

                  // Split type
                  _buildSplitTypeSelector(),
                  const SizedBox(height: 20),

                  // Split among
                  _buildSplitAmongSelector(group.members),
                  const SizedBox(height: 20),

                  // Notes (optional)
                  AppTextField(
                    controller: _notesController,
                    label: 'Notes (Optional)',
                    hint: 'Add any additional notes',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  PrimaryButton(
                    text: 'Add Expense',
                    isLoading: _isLoading,
                    onPressed: () => _handleSubmit(group),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.expenseCategories.map((category) {
            final isSelected = _selectedCategory == category;
            return ChoiceChip(
              label: Text(category.toUpperCase()),
              selected: isSelected,
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontSize: 12,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaidBySelector(List<User> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paid By',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _paidBy,
          decoration: const InputDecoration(
            hintText: 'Select who paid',
          ),
          items: members.map((member) {
            return DropdownMenuItem(
              value: member.id,
              child: Text(member.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _paidBy = value);
          },
          validator: (value) {
            if (value == null) return 'Please select who paid';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSplitTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Split Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'equal', label: Text('Equal')),
            ButtonSegment(value: 'unequal', label: Text('Unequal')),
            ButtonSegment(value: 'percentage', label: Text('Percent')),
          ],
          selected: {_splitType},
          onSelectionChanged: (selection) {
            setState(() {
              _splitType = selection.first;
              _customSplits.clear();
            });
          },
        ),
      ],
    );
  }

  Widget _buildSplitAmongSelector(List<User> members) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Split Among',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...members.map((member) {
          final isSelected = _selectedMembers.any((m) => m.id == member.id);
          return CheckboxListTile(
            value: isSelected,
            title: Text(member.name),
            subtitle: _splitType != 'equal' && isSelected
                ? _buildCustomSplitInput(member)
                : null,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedMembers.add(member);
                } else {
                  _selectedMembers.removeWhere((m) => m.id == member.id);
                  _customSplits.remove(member.id);
                }
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildCustomSplitInput(User member) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          isDense: true,
          hintText: _splitType == 'percentage' ? 'Enter %' : 'Enter amount',
          suffixText: _splitType == 'percentage' ? '%' : '₹',
        ),
        onChanged: (value) {
          final parsed = double.tryParse(value);
          if (parsed != null) {
            _customSplits[member.id] = parsed;
          }
        },
      ),
    );
  }

  Future<void> _handleSubmit(Group group) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one person to split with')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      List<Map<String, dynamic>>? splits;

      if (_splitType != 'equal') {
        splits = _selectedMembers.map((member) {
          final value = _customSplits[member.id] ?? 0;
          return {
            'user': member.id,
            if (_splitType == 'unequal') 'amount': value,
            if (_splitType == 'percentage') 'percentage': value,
          };
        }).toList();
      }

      final request = CreateExpenseRequest(
        groupId: widget.groupId,
        description: _descriptionController.text.trim(),
        amount: amount,
        paidBy: _paidBy!,
        splitType: _splitType,
        splits: splits,
        notes: _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
        category: _selectedCategory,
      );

      final expense = await ref
          .read(expensesProvider(widget.groupId).notifier)
          .createExpense(request);

      if (expense != null && mounted) {
        // Refresh dashboard data
        ref.invalidate(dashboardProvider);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
