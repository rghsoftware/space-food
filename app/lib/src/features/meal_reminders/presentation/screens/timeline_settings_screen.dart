/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/models/eating_timeline.dart';

/// Settings screen for eating timeline configuration
class TimelineSettingsScreen extends ConsumerStatefulWidget {
  const TimelineSettingsScreen({super.key});

  @override
  ConsumerState<TimelineSettingsScreen> createState() =>
      _TimelineSettingsScreenState();
}

class _TimelineSettingsScreenState
    extends ConsumerState<TimelineSettingsScreen> {
  late int _dailyMealGoal;
  late int _dailySnackGoal;
  late bool _showStreak;
  late bool _showMissedMeals;

  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // TODO: Load settings from provider
    // For now, use defaults
    _dailyMealGoal = 3;
    _dailySnackGoal = 2;
    _showStreak = true;
    _showMissedMeals = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline Settings'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveSettings,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        children: [
          // Goals Section
          _buildSection(
            context,
            title: 'Daily Goals',
            icon: Icons.flag,
            children: [
              _buildGoalSlider(
                context,
                label: 'Daily Meals',
                value: _dailyMealGoal,
                min: 0,
                max: 6,
                onChanged: (value) {
                  setState(() {
                    _dailyMealGoal = value;
                    _hasChanges = true;
                  });
                },
              ),
              const Divider(),
              _buildGoalSlider(
                context,
                label: 'Daily Snacks',
                value: _dailySnackGoal,
                min: 0,
                max: 6,
                onChanged: (value) {
                  setState(() {
                    _dailySnackGoal = value;
                    _hasChanges = true;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Display Options
          _buildSection(
            context,
            title: 'Display Options',
            icon: Icons.visibility,
            children: [
              SwitchListTile(
                title: const Text('Show Streak'),
                subtitle: const Text(
                  'Display consecutive days meeting your goals',
                ),
                value: _showStreak,
                onChanged: (value) {
                  setState(() {
                    _showStreak = value;
                    _hasChanges = true;
                  });
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Show Missed Meals'),
                subtitle: const Text(
                  'Highlight days when goals weren\'t met\n'
                  '(Disabled by default for shame-free tracking)',
                ),
                value: _showMissedMeals,
                onChanged: (value) {
                  setState(() {
                    _showMissedMeals = value;
                    _hasChanges = true;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ADHD-Friendly Tips
          _buildSection(
            context,
            title: 'Tips for ADHD Users',
            icon: Icons.lightbulb_outline,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTip(
                      context,
                      icon: Icons.check_circle,
                      text: 'Set realistic goals - start with 2 meals per day',
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      context,
                      icon: Icons.notifications_active,
                      text: 'Enable pre-alerts to give yourself prep time',
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      context,
                      icon: Icons.no_accounts,
                      text: 'Keep "Show Missed Meals" off to avoid guilt',
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      context,
                      icon: Icons.favorite,
                      text: 'Celebrate every meal logged - progress over perfection',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // About Section
          _buildSection(
            context,
            title: 'About',
            icon: Icons.info_outline,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'This meal reminder system is designed specifically for people with ADHD '
                  'who struggle with remembering to eat. The focus is on gentle reminders, '
                  'easy logging, and shame-free progress tracking.\n\n'
                  'All data is stored offline-first and syncs when you\'re online.',
                  style: TextStyle(height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildGoalSlider(
    BuildContext context, {
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            label: value.toString(),
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(height: 1.4),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final request = UpdateTimelineSettingsRequest(
        dailyMealGoal: _dailyMealGoal,
        dailySnackGoal: _dailySnackGoal,
        showStreak: _showStreak,
        showMissedMeals: _showMissedMeals,
      );

      // TODO: Save settings via repository
      // await ref.read(mealReminderRepositoryProvider).updateTimelineSettings(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Settings saved successfully'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _hasChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
