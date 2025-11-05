/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/models/meal_reminder.dart';

/// Screen for managing meal reminders
class MealRemindersScreen extends ConsumerWidget {
  const MealRemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Get reminders from provider
    // final remindersAsync = ref.watch(mealRemindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Reminders'),
        actions: [
          IconButton(
            onPressed: () => _showReminderDialog(context),
            icon: const Icon(Icons.add),
            tooltip: 'Add Reminder',
          ),
        ],
      ),
      body: _buildRemindersList(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReminderDialog(context),
        icon: const Icon(Icons.add_alarm),
        label: const Text('Add Reminder'),
      ),
    );
  }

  Widget _buildRemindersList(BuildContext context) {
    // TODO: Replace with actual data from provider
    final mockReminders = _generateMockReminders();

    if (mockReminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.alarm_off,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No reminders yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create your first meal reminder',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: mockReminders.length,
      itemBuilder: (context, index) {
        final reminder = mockReminders[index];
        return MealReminderCard(
          reminder: reminder,
          onTap: () => _showReminderDialog(context, reminder: reminder),
          onToggle: () {
            // TODO: Toggle reminder enabled state
          },
          onDelete: () {
            // TODO: Delete reminder
          },
        );
      },
    );
  }

  void _showReminderDialog(BuildContext context, {MealReminder? reminder}) {
    showDialog(
      context: context,
      builder: (context) => MealReminderDialog(reminder: reminder),
    );
  }

  List<MealReminder> _generateMockReminders() {
    final now = DateTime.now();
    return [
      MealReminder(
        id: '1',
        userId: 'user1',
        name: 'Breakfast',
        scheduledTime: '08:00:00',
        preAlertMinutes: 15,
        enabled: true,
        daysOfWeek: const [1, 2, 3, 4, 5], // Weekdays
        createdAt: now,
        updatedAt: now,
      ),
      MealReminder(
        id: '2',
        userId: 'user1',
        name: 'Lunch',
        scheduledTime: '12:30:00',
        preAlertMinutes: 15,
        enabled: true,
        daysOfWeek: const [0, 1, 2, 3, 4, 5, 6], // Every day
        createdAt: now,
        updatedAt: now,
      ),
      MealReminder(
        id: '3',
        userId: 'user1',
        name: 'Dinner',
        scheduledTime: '19:00:00',
        preAlertMinutes: 30,
        enabled: false,
        daysOfWeek: const [0, 1, 2, 3, 4, 5, 6],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}

/// Card displaying a meal reminder
class MealReminderCard extends StatelessWidget {
  final MealReminder reminder;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const MealReminderCard({
    super.key,
    required this.reminder,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: reminder.enabled
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.withOpacity(0.3),
          child: Icon(
            Icons.restaurant_menu,
            color: reminder.enabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
        ),
        title: Text(
          reminder.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: reminder.enabled ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: reminder.enabled
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(_formatTime(reminder.scheduledTime)),
                if (reminder.preAlertMinutes > 0) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.notifications_active,
                    size: 16,
                    color: reminder.enabled
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text('${reminder.preAlertMinutes}m before'),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(_formatDaysOfWeek(reminder.daysOfWeek)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: reminder.enabled,
              onChanged: (_) => onToggle(),
            ),
            PopupMenuButton(
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
                if (value == 'edit') {
                  onTap();
                } else if (value == 'delete') {
                  _confirmDelete(context);
                }
              },
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDaysOfWeek(List<int> days) {
    if (days.length == 7) return 'Every day';
    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Weekdays';
    }
    if (days.length == 2 && days.contains(0) && days.contains(6)) {
      return 'Weekends';
    }

    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days.map((d) => dayNames[d]).join(', ');
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.name}"?'),
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
      onDelete();
    }
  }
}

/// Dialog for creating/editing meal reminders
class MealReminderDialog extends StatefulWidget {
  final MealReminder? reminder;

  const MealReminderDialog({super.key, this.reminder});

  @override
  State<MealReminderDialog> createState() => _MealReminderDialogState();
}

class _MealReminderDialogState extends State<MealReminderDialog> {
  late TextEditingController _nameController;
  late TimeOfDay _selectedTime;
  late int _preAlertMinutes;
  late Set<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.reminder?.name ?? '');

    if (widget.reminder != null) {
      final timeParts = widget.reminder!.scheduledTime.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
      _preAlertMinutes = widget.reminder!.preAlertMinutes;
      _selectedDays = widget.reminder!.daysOfWeek.toSet();
    } else {
      _selectedTime = const TimeOfDay(hour: 12, minute: 0);
      _preAlertMinutes = 15;
      _selectedDays = {0, 1, 2, 3, 4, 5, 6}; // All days by default
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.reminder == null ? 'Add Reminder' : 'Edit Reminder'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Reminder Name',
                hintText: 'e.g., Breakfast, Lunch, Dinner',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // Time picker
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Time'),
              subtitle: Text(_formatTime(_selectedTime)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() {
                    _selectedTime = time;
                  });
                }
              },
            ),

            // Pre-alert slider
            const SizedBox(height: 8),
            Text(
              'Pre-alert: $_preAlertMinutes minutes before',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _preAlertMinutes.toDouble(),
              min: 0,
              max: 60,
              divisions: 12,
              label: '$_preAlertMinutes min',
              onChanged: (value) {
                setState(() {
                  _preAlertMinutes = value.toInt();
                });
              },
            ),

            // Days of week
            const SizedBox(height: 8),
            Text(
              'Repeat on',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildDaysSelector(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveReminder,
          child: Text(widget.reminder == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  Widget _buildDaysSelector() {
    const dayNames = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Wrap(
      spacing: 8,
      children: List.generate(7, (index) {
        final isSelected = _selectedDays.contains(index);
        return FilterChip(
          label: Text(dayNames[index]),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(index);
              } else {
                _selectedDays.remove(index);
              }
            });
          },
        );
      }),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _saveReminder() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reminder name')),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    // Format time as HH:MM:SS
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:'
        '${_selectedTime.minute.toString().padLeft(2, '0')}:00';

    final request = widget.reminder == null
        ? CreateMealReminderRequest(
            name: _nameController.text,
            scheduledTime: timeStr,
            preAlertMinutes: _preAlertMinutes,
            enabled: true,
            daysOfWeek: _selectedDays.toList()..sort(),
          )
        : UpdateMealReminderRequest(
            name: _nameController.text,
            scheduledTime: timeStr,
            preAlertMinutes: _preAlertMinutes,
            enabled: widget.reminder!.enabled,
            daysOfWeek: _selectedDays.toList()..sort(),
          );

    // TODO: Save reminder via repository
    Navigator.pop(context, request);
  }
}
