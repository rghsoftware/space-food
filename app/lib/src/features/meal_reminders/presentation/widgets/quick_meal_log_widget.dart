/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/models/meal_log.dart';

/// Quick meal log widget for one-tap logging
/// Shows as a FAB or can be triggered from notifications
class QuickMealLogButton extends ConsumerWidget {
  final String? reminderId;
  final VoidCallback? onLogged;

  const QuickMealLogButton({
    super.key,
    this.reminderId,
    this.onLogged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickLogDialog(context, ref),
      icon: const Icon(Icons.restaurant),
      label: const Text('Log Meal'),
      tooltip: 'Quickly log a meal',
    );
  }

  Future<void> _showQuickLogDialog(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => QuickMealLogSheet(
        reminderId: reminderId,
        onLogged: onLogged,
      ),
    );
  }
}

/// Bottom sheet for quick meal logging
class QuickMealLogSheet extends ConsumerStatefulWidget {
  final String? reminderId;
  final VoidCallback? onLogged;

  const QuickMealLogSheet({
    super.key,
    this.reminderId,
    this.onLogged,
  });

  @override
  ConsumerState<QuickMealLogSheet> createState() => _QuickMealLogSheetState();
}

class _QuickMealLogSheetState extends ConsumerState<QuickMealLogSheet> {
  int? _selectedEnergyLevel;
  final _notesController = TextEditingController();
  bool _isLogging = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Log a Meal',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // One-tap log button (primary action)
          FilledButton.icon(
            onPressed: _isLogging ? null : () => _logMeal(context),
            icon: _isLogging
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle),
            label: Text(_isLogging ? 'Logging...' : 'Log Now'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          const SizedBox(height: 24),

          // Optional: Energy level (ADHD-friendly tracking)
          Text(
            'How are you feeling? (Optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildEnergyLevelSelector(),

          const SizedBox(height: 24),

          // Optional: Notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'How was the meal?',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEnergyLevelSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        final level = index + 1;
        final isSelected = _selectedEnergyLevel == level;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedEnergyLevel = level;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _getEnergyIcon(level),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  size: 32,
                ),
                const SizedBox(height: 4),
                Text(
                  level.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  IconData _getEnergyIcon(int level) {
    switch (level) {
      case 1:
        return Icons.battery_0_bar;
      case 2:
        return Icons.battery_2_bar;
      case 3:
        return Icons.battery_4_bar;
      case 4:
        return Icons.battery_6_bar;
      case 5:
        return Icons.battery_full;
      default:
        return Icons.battery_unknown;
    }
  }

  Future<void> _logMeal(BuildContext context) async {
    setState(() {
      _isLogging = true;
    });

    try {
      // Create log request
      final request = LogMealRequest(
        reminderId: widget.reminderId,
        loggedAt: DateTime.now(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        energyLevel: _selectedEnergyLevel,
      );

      // TODO: Call repository to log meal
      // await ref.read(mealReminderRepositoryProvider).logMeal(request);

      // Show success feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Meal logged successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
        widget.onLogged?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log meal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLogging = false;
        });
      }
    }
  }
}

/// Compact quick log button for app bar or notification actions
class CompactQuickLogButton extends ConsumerWidget {
  final String? reminderId;

  const CompactQuickLogButton({
    super.key,
    this.reminderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => _showQuickLogDialog(context),
      icon: const Icon(Icons.add_circle),
      tooltip: 'Quick log meal',
    );
  }

  Future<void> _showQuickLogDialog(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => QuickMealLogSheet(reminderId: reminderId),
    );
  }
}

/// Simple one-tap log button (minimal friction for ADHD users)
class OneTapLogButton extends ConsumerStatefulWidget {
  final String? reminderId;
  final VoidCallback? onLogged;

  const OneTapLogButton({
    super.key,
    this.reminderId,
    this.onLogged,
  });

  @override
  ConsumerState<OneTapLogButton> createState() => _OneTapLogButtonState();
}

class _OneTapLogButtonState extends ConsumerState<OneTapLogButton> {
  bool _isLogging = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLogging ? null : _logMealNow,
      icon: _isLogging
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.restaurant_menu),
      label: Text(_isLogging ? 'Logging...' : 'Ate!'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _logMealNow() async {
    setState(() {
      _isLogging = true;
    });

    try {
      // Log with minimal data (one-tap logging)
      final request = LogMealRequest(
        reminderId: widget.reminderId,
        loggedAt: DateTime.now(),
      );

      // TODO: Call repository to log meal
      // await ref.read(mealReminderRepositoryProvider).logMeal(request);

      if (mounted) {
        // Show quick feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✓ Logged!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            width: 200,
          ),
        );

        widget.onLogged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLogging = false;
        });
      }
    }
  }
}
