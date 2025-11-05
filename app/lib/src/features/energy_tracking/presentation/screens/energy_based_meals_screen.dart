/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../data/models/favorite_meal.dart';
import '../widgets/energy_filter_chip.dart';

/// Screen for energy-based meal recommendations
class EnergyBasedMealsScreen extends ConsumerStatefulWidget {
  const EnergyBasedMealsScreen({super.key});

  @override
  ConsumerState<EnergyBasedMealsScreen> createState() =>
      _EnergyBasedMealsScreenState();
}

class _EnergyBasedMealsScreenState
    extends ConsumerState<EnergyBasedMealsScreen> {
  int? _selectedEnergy;

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual provider
    // final recommendationsAsync = ref.watch(
    //   energyRecommendationsProvider(_selectedEnergy),
    // );

    return Scaffold(
      appBar: AppBar(
        title: const Text('What to Eat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showEnergyInfo,
            tooltip: 'Energy level guide',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Navigate to energy history
            },
            tooltip: 'Energy history',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          EnergyFilterChip(
            selectedEnergy: _selectedEnergy,
            onChanged: (level) => setState(() => _selectedEnergy = level),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildMockMealList(),
            // TODO: Replace with actual data
            // child: recommendationsAsync.when(
            //   loading: () => const Center(child: CircularProgressIndicator()),
            //   error: (err, stack) => Center(child: Text('Error: $err')),
            //   data: (recommendations) => _buildMealList(recommendations),
            // ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _showAddFavoriteMeal,
            icon: const Icon(Icons.add),
            label: const Text('Add Favorite'),
            heroTag: 'add_favorite',
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: _showQuickEnergyRecorder,
            icon: const Icon(Icons.bolt),
            label: const Text('Energy Check'),
            heroTag: 'energy_check',
          ),
        ],
      ),
    );
  }

  Widget _buildMockMealList() {
    // TODO: Replace with actual data from provider
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
      FavoriteMeal(
        id: '3',
        userId: 'user1',
        mealName: 'Pasta with Sauce',
        energyLevel: 3,
        typicalTimeOfDay: 'dinner',
        frequencyScore: 8,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockMeals.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Showing meals appropriate for your ${_selectedEnergy != null ? _getEnergyDescription(_selectedEnergy!) : "current"} energy level.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          );
        }

        final meal = mockMeals[index - 1];
        return MealCard(
          meal: meal,
          onTap: () => _showMealDetails(meal),
          onMarkEaten: () => _markMealEaten(meal),
        );
      },
    );
  }

  String _getEnergyDescription(int level) {
    if (level <= 2) return 'low';
    if (level == 3) return 'moderate';
    return 'good';
  }

  void _showEnergyInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Energy Levels'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose the energy level that matches how you feel right now. '
                'This helps us recommend meals that fit your current capacity.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 16),
              _buildEnergyDescription(1, 'Exhausted', 'Zero-prep meals only',
                  'Cereal, yogurt, fruit, protein bar'),
              _buildEnergyDescription(2, 'Low', 'Minimal effort, under 5 min',
                  'Toast, instant oatmeal, smoothie'),
              _buildEnergyDescription(
                  3, 'Moderate', 'Simple cooking, 10-15 min', 'Pasta, eggs, stir-fry'),
              _buildEnergyDescription(
                  4, 'Good', 'Can follow recipes', 'Most standard recipes'),
              _buildEnergyDescription(5, 'High', 'Complex meals, multiple steps',
                  'Elaborate recipes, meal prep'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyDescription(
      int level, String label, String description, String examples) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getIconForLevel(level),
            size: 24,
            color: _getColorForLevel(level),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Examples: $examples',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFavoriteMeal() {
    // TODO: Navigate to add favorite meal screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add favorite meal - Coming soon')),
    );
  }

  void _showQuickEnergyRecorder() {
    // TODO: Show energy recording dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Energy check - Coming soon')),
    );
  }

  void _showMealDetails(FavoriteMeal meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(meal.mealName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (meal.energyLevel != null)
              Row(
                children: [
                  Icon(
                    _getIconForLevel(meal.energyLevel!),
                    color: _getColorForLevel(meal.energyLevel!),
                  ),
                  const SizedBox(width: 8),
                  Text('Energy: ${_getEnergyLabel(meal.energyLevel!)}'),
                ],
              ),
            if (meal.typicalTimeOfDay != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Usually eaten: ${meal.typicalTimeOfDay}'),
              ),
            if (meal.frequencyScore > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Eaten ${meal.frequencyScore} times'),
              ),
            if (meal.notes != null && meal.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(meal.notes!),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _markMealEaten(meal);
            },
            child: const Text('Mark as Eaten'),
          ),
        ],
      ),
    );
  }

  void _markMealEaten(FavoriteMeal meal) {
    // TODO: Call repository to mark meal as eaten
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Marked "${meal.mealName}" as eaten')),
    );
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

/// Meal card widget
class MealCard extends StatelessWidget {
  final FavoriteMeal meal;
  final VoidCallback onTap;
  final VoidCallback onMarkEaten;

  const MealCard({
    required this.meal,
    required this.onTap,
    required this.onMarkEaten,
    super.key,
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
            if (meal.typicalTimeOfDay != null)
              Text('Usually eaten: ${meal.typicalTimeOfDay}'),
            if (meal.notes != null && meal.notes!.isNotEmpty)
              Text(
                meal.notes!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline),
          onPressed: onMarkEaten,
          tooltip: 'Mark as eaten',
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getEnergyColor(int? level) {
    if (level == null) return Colors.grey;
    if (level <= 2) return Colors.red;
    if (level == 3) return Colors.orange;
    return Colors.green;
  }
}
