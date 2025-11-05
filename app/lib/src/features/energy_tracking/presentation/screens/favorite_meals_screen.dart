/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/models/favorite_meal.dart';

/// Screen for managing favorite meals
class FavoriteMealsScreen extends ConsumerWidget {
  const FavoriteMealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Replace with actual provider
    // final mealsAsync = ref.watch(favoriteMealsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Meals'),
      ),
      body: _buildMockMealList(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMealDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Meal'),
      ),
    );
  }

  Widget _buildMockMealList(BuildContext context) {
    // Mock data for demonstration
    final mockMeals = [
      FavoriteMeal(
        id: '1',
        userId: 'user1',
        mealName: 'Cereal with Milk',
        energyLevel: 1,
        typicalTimeOfDay: 'morning',
        frequencyScore: 5,
        notes: 'Quick and easy',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      FavoriteMeal(
        id: '2',
        userId: 'user1',
        mealName: 'Scrambled Eggs',
        energyLevel: 2,
        typicalTimeOfDay: 'morning',
        frequencyScore: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    if (mockMeals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No favorite meals yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add meals you enjoy to get recommendations',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddMealDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Meal'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockMeals.length,
      itemBuilder: (context, index) {
        final meal = mockMeals[index];
        return _FavoriteMealCard(
          meal: meal,
          onEdit: () => _showEditMealDialog(context, meal),
          onDelete: () => _confirmDelete(context, meal),
        );
      },
    );
  }

  void _showAddMealDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddFavoriteMealDialog(),
    );
  }

  void _showEditMealDialog(BuildContext context, FavoriteMeal meal) {
    showDialog(
      context: context,
      builder: (context) => AddFavoriteMealDialog(meal: meal),
    );
  }

  Future<void> _confirmDelete(BuildContext context, FavoriteMeal meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Text('Are you sure you want to delete "${meal.mealName}"?'),
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
      // TODO: Delete meal via repository
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "${meal.mealName}"')),
      );
    }
  }
}

class _FavoriteMealCard extends StatelessWidget {
  final FavoriteMeal meal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FavoriteMealCard({
    required this.meal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getEnergyColor(meal.energyLevel),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(
              Icons.restaurant,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(meal.mealName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (meal.energyLevel != null)
              Text('Energy: ${_getEnergyLabel(meal.energyLevel!)}'),
            if (meal.typicalTimeOfDay != null)
              Text('Time: ${meal.typicalTimeOfDay}'),
            if (meal.frequencyScore > 0) Text('Eaten ${meal.frequencyScore} times'),
          ],
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
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
        ),
      ),
    );
  }

  Color _getEnergyColor(int? level) {
    if (level == null) return Colors.grey;
    if (level <= 2) return Colors.red;
    if (level == 3) return Colors.orange;
    return Colors.green;
  }

  String _getEnergyLabel(int level) {
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
        return 'Unknown';
    }
  }
}

/// Dialog for adding/editing favorite meals
class AddFavoriteMealDialog extends StatefulWidget {
  final FavoriteMeal? meal;

  const AddFavoriteMealDialog({this.meal, super.key});

  @override
  State<AddFavoriteMealDialog> createState() => _AddFavoriteMealDialogState();
}

class _AddFavoriteMealDialogState extends State<AddFavoriteMealDialog> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  int? _selectedEnergy;
  String? _selectedTimeOfDay;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meal?.mealName ?? '');
    _notesController = TextEditingController(text: widget.meal?.notes ?? '');
    _selectedEnergy = widget.meal?.energyLevel;
    _selectedTimeOfDay = widget.meal?.typicalTimeOfDay;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.meal == null ? 'Add Favorite Meal' : 'Edit Meal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Meal Name',
                hintText: 'e.g., Cereal, Pasta, Eggs',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Energy Level Required',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(5, (index) {
                final level = index + 1;
                return FilterChip(
                  label: Text('$level'),
                  selected: _selectedEnergy == level,
                  onSelected: (selected) {
                    setState(() {
                      _selectedEnergy = selected ? level : null;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              'Typical Time of Day',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['morning', 'afternoon', 'evening', 'night'].map((time) {
                return FilterChip(
                  label: Text(time[0].toUpperCase() + time.substring(1)),
                  selected: _selectedTimeOfDay == time,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTimeOfDay = selected ? time : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Any notes about this meal',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveMeal,
          child: Text(widget.meal == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  void _saveMeal() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meal name')),
      );
      return;
    }

    final request = SaveFavoriteMealRequest(
      mealName: _nameController.text,
      energyLevel: _selectedEnergy,
      typicalTimeOfDay: _selectedTimeOfDay,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    // TODO: Save via repository
    Navigator.pop(context, request);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meal saved')),
    );
  }
}
