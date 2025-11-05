/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';

/// Energy filter chip widget for selecting energy level
class EnergyFilterChip extends StatelessWidget {
  final int? selectedEnergy;
  final Function(int?) onChanged;

  const EnergyFilterChip({
    required this.selectedEnergy,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(context, null, 'All'),
          const SizedBox(width: 8),
          ...List.generate(5, (index) {
            final level = index + 1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(context, level, _getLabelForLevel(level)),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, int? level, String label) {
    final isSelected = selectedEnergy == level;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (level != null) ...[
            Icon(
              _getIconForLevel(level),
              size: 16,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : _getColorForLevel(level),
            ),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      onSelected: (_) => onChanged(level),
      backgroundColor: level != null
          ? _getColorForLevel(level).withOpacity(0.1)
          : null,
      selectedColor: level != null
          ? _getColorForLevel(level)
          : Theme.of(context).colorScheme.primary,
    );
  }

  String _getLabelForLevel(int level) {
    switch (level) {
      case 1:
        return 'Exhausted';
      case 2:
        return 'Low';
      case 3:
        return 'Moderate';
      case 4:
        return 'Good';
      case 5:
        return 'High';
      default:
        return '';
    }
  }

  IconData _getIconForLevel(int level) {
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

  Color _getColorForLevel(int level) {
    if (level <= 2) return Colors.red;
    if (level == 3) return Colors.orange;
    return Colors.green;
  }
}

/// Quick energy recording widget (floating button)
class QuickEnergyRecorder extends StatelessWidget {
  final Function(int) onEnergySelected;

  const QuickEnergyRecorder({
    required this.onEnergySelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showEnergySelector(context),
      icon: const Icon(Icons.bolt),
      label: const Text('Energy Check'),
      tooltip: 'Record your current energy level',
    );
  }

  Future<void> _showEnergySelector(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...List.generate(5, (index) {
              final level = index + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EnergyLevelButton(
                  level: level,
                  onTap: () {
                    Navigator.pop(context);
                    onEnergySelected(level);
                  },
                ),
              );
            }),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnergyLevelButton extends StatelessWidget {
  final int level;
  final VoidCallback onTap;

  const _EnergyLevelButton({
    required this.level,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: _getColorForLevel(level),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              _getIconForLevel(level),
              size: 32,
              color: _getColorForLevel(level),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getLabelForLevel(level),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    _getDescriptionForLevel(level),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLabelForLevel(int level) {
    switch (level) {
      case 1:
        return 'Exhausted';
      case 2:
        return 'Low Energy';
      case 3:
        return 'Moderate';
      case 4:
        return 'Good Energy';
      case 5:
        return 'Energized';
      default:
        return '';
    }
  }

  String _getDescriptionForLevel(int level) {
    switch (level) {
      case 1:
        return 'Zero-prep meals only';
      case 2:
        return 'Minimal effort, under 5 min';
      case 3:
        return 'Simple cooking, 10-15 min';
      case 4:
        return 'Can follow recipes';
      case 5:
        return 'Complex meals, multiple steps';
      default:
        return '';
    }
  }

  IconData _getIconForLevel(int level) {
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

  Color _getColorForLevel(int level) {
    if (level <= 2) return Colors.red;
    if (level == 3) return Colors.orange;
    return Colors.green;
  }
}
