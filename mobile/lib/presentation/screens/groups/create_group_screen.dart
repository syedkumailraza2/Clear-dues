import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  final List<String> _groupIcons = [
    'group',
    'home',
    'flight',
    'restaurant',
    'shopping_cart',
    'sports_bar',
    'movie',
    'celebration',
  ];
  String _selectedIcon = 'group';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group icon selector
              const Text(
                'Group Icon',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _groupIcons.map((iconName) {
                  final isSelected = _selectedIcon == iconName;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = iconName),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textHint,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        _getIconData(iconName),
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        size: 28,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Group name
              AppTextField(
                controller: _nameController,
                label: 'Group Name',
                hint: 'e.g., Roommates, Trip to Goa',
                validator: Validators.validateGroupName,
              ),
              const SizedBox(height: 20),

              // Description
              AppTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                hint: 'What is this group for?',
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Create button
              PrimaryButton(
                text: 'Create Group',
                isLoading: _isLoading,
                onPressed: _handleCreate,
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // Join group section
              const Text(
                'Or join an existing group',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _showJoinDialog,
                icon: const Icon(Icons.link),
                label: const Text('Join with Invite Code'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'home':
        return Icons.home;
      case 'flight':
        return Icons.flight;
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'sports_bar':
        return Icons.sports_bar;
      case 'movie':
        return Icons.movie;
      case 'celebration':
        return Icons.celebration;
      default:
        return Icons.group;
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final group = await ref.read(groupsProvider.notifier).createGroup(
            name: _nameController.text.trim(),
            description: _descriptionController.text.isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            icon: _selectedIcon,
          );

      if (group != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group "${group.name}" created!')),
        );
        context.pop();
        context.push('/groups/${group.id}');
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

  void _showJoinDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Join Group'),
          content: TextField(
            controller: codeController,
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
                if (codeController.text.length == 8) {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);

                  final group = await ref
                      .read(groupsProvider.notifier)
                      .joinGroup(codeController.text);

                  setState(() => _isLoading = false);

                  if (group != null && mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Joined "${group.name}"!')),
                    );
                    this.context.pop();
                    this.context.push('/groups/${group.id}');
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
