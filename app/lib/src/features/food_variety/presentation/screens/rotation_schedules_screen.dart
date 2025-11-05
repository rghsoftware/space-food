// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/food_variety_providers.dart';
import '../../data/models/rotation_schedule.dart';

class RotationSchedulesScreen extends ConsumerWidget {
  const RotationSchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Get actual user ID
    const userId = 'current-user-id';

    final schedulesAsync = ref.watch(rotationSchedulesProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rotation Schedules'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(rotationSchedulesProvider(userId));
        },
        child: schedulesAsync.when(
          data: (schedules) {
            if (schedules.isEmpty) {
              return _EmptyState(onCreatePressed: () {
                _showCreateDialog(context, ref);
              });
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _InfoCard();
                }

                final schedule = schedules[index - 1];
                return _ScheduleCard(
                  schedule: schedule,
                  onEdit: () => _showEditDialog(context, ref, schedule),
                  onDelete: () => _confirmDelete(context, ref, schedule.id),
                  onToggleActive: () =>
                      _toggleActive(ref, schedule.id, schedule),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Schedule'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    // TODO: Implement create dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create dialog not yet implemented')),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, FoodRotationSchedule schedule) {
    // TODO: Implement edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit dialog not yet implemented')),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String scheduleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content:
            const Text('Are you sure you want to delete this rotation schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(rotationScheduleDeleterProvider.notifier)
            .deleteSchedule(scheduleId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting schedule: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleActive(
      WidgetRef ref, String scheduleId, FoodRotationSchedule schedule) async {
    try {
      await ref.read(rotationScheduleUpdaterProvider.notifier).updateSchedule(
            scheduleId: scheduleId,
            isActive: !schedule.isActive,
          );
    } catch (e) {
      // Error handling
    }
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[50],
      margin: const EdgeInsets.only(bottom: 16),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'About Rotation Schedules',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Rotation schedules help you plan meals in advance with a repeating '
              'cycle. Great if you prefer routine and structure!',
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreatePressed;

  const _EmptyState({required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Rotation Schedules',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first rotation schedule to get started',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreatePressed,
              icon: const Icon(Icons.add),
              label: const Text('Create Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final FoodRotationSchedule schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _ScheduleCard({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.calendar_month,
              color: schedule.isActive ? Colors.blue : Colors.grey,
            ),
            title: Text(
              schedule.scheduleName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: schedule.isActive ? null : Colors.grey,
              ),
            ),
            subtitle: Text(
              '${schedule.rotationDays} days • ${schedule.foods.length} foods',
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(schedule.isActive ? Icons.pause : Icons.play_arrow),
                      const SizedBox(width: 8),
                      Text(schedule.isActive ? 'Deactivate' : 'Activate'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'toggle':
                    onToggleActive();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
            ),
          ),
          if (schedule.isActive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Foods in rotation:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...schedule.foods.take(3).map((food) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                food.foodName +
                                    (food.portionSize != null
                                        ? ' (${food.portionSize})'
                                        : ''),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (schedule.foods.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(left: 14, top: 2),
                      child: Text(
                        '+ ${schedule.foods.length - 3} more',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
