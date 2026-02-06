import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/providers.dart';
import '../../widgets/common_widgets.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(groupsProvider.notifier).fetchGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupsState = ref.watch(groupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(groupsProvider.notifier).fetchGroups(),
        child: groupsState.isLoading && groupsState.groups.isEmpty
            ? const LoadingIndicator(message: 'Loading groups...')
            : groupsState.error != null && groupsState.groups.isEmpty
                ? ErrorDisplay(
                    message: groupsState.error!,
                    onRetry: () => ref.read(groupsProvider.notifier).fetchGroups(),
                  )
                : groupsState.groups.isEmpty
                    ? const EmptyState(
                        icon: Icons.group_off,
                        title: 'No groups yet',
                        subtitle: 'Create a group or join one using an invite code',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groupsState.groups.length,
                        itemBuilder: (context, index) {
                          final group = groupsState.groups[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundColor: AppTheme.primaryLight,
                                child: Text(
                                  Formatters.getInitials(group.name),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                group.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('${group.memberCount} members'),
                                  if (group.description != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      group.description!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textHint,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/groups/${group.id}'),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/groups/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
