/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/ai_models.dart';
import '../providers/ai_provider.dart';
import '../providers/meal_plan_provider.dart';

class AiMealPlanGenerateScreen extends HookConsumerWidget {
  const AiMealPlanGenerateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servingsController = useTextEditingController(text: '4');
    final calorieTargetController = useTextEditingController();

    final startDate = useState(DateTime.now());
    final endDate = useState(DateTime.now().add(const Duration(days: 7)));
    final selectedDietaryRestrictions = useState<List<String>>([]);
    final selectedPreferences = useState<List<String>>([]);
    final isLoading = useState(false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Meal Plan Generator'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate AI-powered meal plan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start Date'),
                    subtitle: Text(_formatDate(startDate.value)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate.value,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        startDate.value = date;
                        if (endDate.value.isBefore(date)) {
                          endDate.value = date.add(const Duration(days: 7));
                        }
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End Date'),
                    subtitle: Text(_formatDate(endDate.value)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate.value,
                        firstDate: startDate.value,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        endDate.value = date;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: servingsController,
                          decoration: const InputDecoration(
                            labelText: 'Servings',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: calorieTargetController,
                          decoration: const InputDecoration(
                            labelText: 'Daily Calorie Target',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dietary Restrictions',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      'vegetarian',
                      'vegan',
                      'gluten-free',
                      'dairy-free',
                      'keto',
                      'paleo',
                    ].map((restriction) {
                      final isSelected =
                          selectedDietaryRestrictions.value.contains(restriction);
                      return FilterChip(
                        label: Text(restriction),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            selectedDietaryRestrictions.value = [
                              ...selectedDietaryRestrictions.value,
                              restriction
                            ];
                          } else {
                            selectedDietaryRestrictions.value =
                                selectedDietaryRestrictions.value
                                    .where((r) => r != restriction)
                                    .toList();
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Preferences',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      'quick-meals',
                      'budget-friendly',
                      'high-protein',
                      'low-carb',
                      'family-friendly',
                      'gourmet',
                    ].map((pref) {
                      final isSelected = selectedPreferences.value.contains(pref);
                      return FilterChip(
                        label: Text(pref),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            selectedPreferences.value = [
                              ...selectedPreferences.value,
                              pref
                            ];
                          } else {
                            selectedPreferences.value = selectedPreferences.value
                                .where((p) => p != pref)
                                .toList();
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading.value
                          ? null
                          : () async {
                              isLoading.value = true;

                              final request = MealPlanGenerationRequest(
                                startDate: startDate.value,
                                endDate: endDate.value,
                                servings: int.tryParse(servingsController.text),
                                calorieTarget:
                                    int.tryParse(calorieTargetController.text),
                                dietaryRestrictions:
                                    selectedDietaryRestrictions.value.isEmpty
                                        ? null
                                        : selectedDietaryRestrictions.value,
                                preferences: selectedPreferences.value.isEmpty
                                    ? null
                                    : selectedPreferences.value,
                              );

                              final repository = ref.read(aiRepositoryProvider);
                              final result =
                                  await repository.generateMealPlan(request);

                              isLoading.value = false;

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
                                (response) {
                                  if (context.mounted) {
                                    ref.invalidate(mealPlansProvider);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Meal plan generated!'),
                                      ),
                                    );
                                    context.go(
                                        '/meal-plans/${response.mealPlan.id}');
                                  }
                                },
                              );
                            },
                      icon: isLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(isLoading.value
                          ? 'Generating...'
                          : 'Generate Meal Plan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'How it works',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI will create a personalized meal plan based on your preferences, '
                    'dietary restrictions, and calorie targets. The plan will include '
                    'breakfast, lunch, dinner, and snacks for each day.',
                    style: TextStyle(color: Colors.blue[900]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
