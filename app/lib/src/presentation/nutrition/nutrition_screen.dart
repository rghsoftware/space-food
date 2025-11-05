/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/nutrition_log.dart';
import '../../data/models/recipe.dart';
import '../providers/nutrition_log_provider.dart';

class NutritionScreen extends HookConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = useState(DateTime.now());

    final startOfDay = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final logsAsync = ref.watch(
      nutritionLogsByDateRangeProvider((start: startOfDay, end: endOfDay)),
    );

    final summaryAsync = ref.watch(
      nutritionSummaryProvider((start: startOfDay, end: endOfDay)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Tracking'),
      ),
      body: Column(
        children: [
          // Date selector
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      selectedDate.value = selectedDate.value
                          .subtract(const Duration(days: 1));
                    },
                  ),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate.value,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        selectedDate.value = date;
                      }
                    },
                    child: Text(
                      _formatDate(selectedDate.value),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: selectedDate.value.isBefore(
                      DateTime.now().subtract(const Duration(days: 1)),
                    )
                        ? () {
                            selectedDate.value = selectedDate.value
                                .add(const Duration(days: 1));
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),

          // Daily summary
          summaryAsync.when(
            data: (summary) => _buildSummaryCard(context, summary),
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Meal logs
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No meals logged',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to log a meal',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                // Group by meal type
                final breakfast =
                    logs.where((l) => l.mealType == 'breakfast').toList();
                final lunch = logs.where((l) => l.mealType == 'lunch').toList();
                final dinner = logs.where((l) => l.mealType == 'dinner').toList();
                final snack = logs.where((l) => l.mealType == 'snack').toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (breakfast.isNotEmpty)
                      _buildMealSection(
                        context,
                        ref,
                        'Breakfast',
                        Icons.wb_sunny,
                        breakfast,
                      ),
                    if (lunch.isNotEmpty)
                      _buildMealSection(
                        context,
                        ref,
                        'Lunch',
                        Icons.wb_cloudy,
                        lunch,
                      ),
                    if (dinner.isNotEmpty)
                      _buildMealSection(
                        context,
                        ref,
                        'Dinner',
                        Icons.nights_stay,
                        dinner,
                      ),
                    if (snack.isNotEmpty)
                      _buildMealSection(
                        context,
                        ref,
                        'Snacks',
                        Icons.coffee,
                        snack,
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading logs',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(nutritionLogsByDateRangeProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLogDialog(context, ref, selectedDate.value),
        icon: const Icon(Icons.add),
        label: const Text('Log Meal'),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    Map<String, dynamic> summary,
  ) {
    final totalCalories = (summary['total_calories'] ?? 0).toDouble();
    final totalProtein = (summary['total_protein'] ?? 0).toDouble();
    final totalCarbs = (summary['total_carbohydrates'] ?? 0).toDouble();
    final totalFat = (summary['total_fat'] ?? 0).toDouble();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientColumn(
                  context,
                  'Calories',
                  totalCalories.toStringAsFixed(0),
                  'kcal',
                  Colors.orange,
                ),
                _buildNutrientColumn(
                  context,
                  'Protein',
                  totalProtein.toStringAsFixed(1),
                  'g',
                  Colors.red,
                ),
                _buildNutrientColumn(
                  context,
                  'Carbs',
                  totalCarbs.toStringAsFixed(1),
                  'g',
                  Colors.blue,
                ),
                _buildNutrientColumn(
                  context,
                  'Fat',
                  totalFat.toStringAsFixed(1),
                  'g',
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientColumn(
    BuildContext context,
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          unit,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildMealSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    IconData icon,
    List<NutritionLog> logs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...logs.map((log) => _NutritionLogCard(
              log: log,
              onDelete: () => _deleteLog(context, ref, log.id),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _deleteLog(
    BuildContext context,
    WidgetRef ref,
    String logId,
  ) async {
    final repository = ref.read(nutritionLogRepositoryProvider);
    final result = await repository.deleteNutritionLog(logId);

    result.fold(
      (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (_) {
        if (context.mounted) {
          ref.invalidate(nutritionLogsByDateRangeProvider);
          ref.invalidate(nutritionSummaryProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log deleted')),
          );
        }
      },
    );
  }

  void _showAddLogDialog(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
  ) {
    final foodNameController = TextEditingController();
    final servingsController = TextEditingController(text: '1');
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    String selectedMealType = 'breakfast';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Log Meal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: foodNameController,
                  decoration: const InputDecoration(
                    labelText: 'Food Name *',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMealType,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
                    DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                    DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                    DropdownMenuItem(value: 'snack', child: Text('Snack')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedMealType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: servingsController,
                  decoration: const InputDecoration(
                    labelText: 'Servings',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text('Nutrition Information',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: caloriesController,
                  decoration: const InputDecoration(
                    labelText: 'Calories (kcal)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: proteinController,
                  decoration: const InputDecoration(
                    labelText: 'Protein (g)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: carbsController,
                  decoration: const InputDecoration(
                    labelText: 'Carbohydrates (g)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fatController,
                  decoration: const InputDecoration(
                    labelText: 'Fat (g)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (foodNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Food name is required')),
                  );
                  return;
                }

                Navigator.pop(context);

                final log = NutritionLogCreate(
                  date: date,
                  mealType: selectedMealType,
                  foodName: foodNameController.text,
                  servings: double.tryParse(servingsController.text) ?? 1,
                  nutritionInfo: NutritionInfo(
                    calories: double.tryParse(caloriesController.text) ?? 0,
                    protein: double.tryParse(proteinController.text) ?? 0,
                    carbohydrates: double.tryParse(carbsController.text) ?? 0,
                    fat: double.tryParse(fatController.text) ?? 0,
                    fiber: 0,
                    sugar: 0,
                    sodium: 0,
                  ),
                  notes: '',
                );

                final repository = ref.read(nutritionLogRepositoryProvider);
                final result = await repository.createNutritionLog(log);

                result.fold(
                  (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  (_) {
                    if (context.mounted) {
                      ref.invalidate(nutritionLogsByDateRangeProvider);
                      ref.invalidate(nutritionSummaryProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Meal logged')),
                      );
                    }
                  },
                );
              },
              child: const Text('Log'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';

    return '${date.day}/${date.month}/${date.year}';
  }
}

class _NutritionLogCard extends StatelessWidget {
  final NutritionLog log;
  final VoidCallback onDelete;

  const _NutritionLogCard({
    required this.log,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          log.foodName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${log.servings} serving(s)'),
            const SizedBox(height: 4),
            Text(
              '${log.nutritionInfo.calories.toStringAsFixed(0)} kcal • '
              '${log.nutritionInfo.protein.toStringAsFixed(1)}g protein • '
              '${log.nutritionInfo.carbohydrates.toStringAsFixed(1)}g carbs • '
              '${log.nutritionInfo.fat.toStringAsFixed(1)}g fat',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Log'),
                content: Text('Delete "${log.foodName}"?'),
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

            if (confirm == true) {
              onDelete();
            }
          },
        ),
      ),
    );
  }
}
