/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/ai_models.dart';
import '../../data/models/recipe.dart';
import '../providers/ai_provider.dart';
import '../providers/recipe_provider.dart';

class AiRecipeSuggestScreen extends HookConsumerWidget {
  const AiRecipeSuggestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientsController = useTextEditingController();
    final cuisineController = useTextEditingController();
    final servingsController = useTextEditingController(text: '4');
    final maxPrepTimeController = useTextEditingController();

    final selectedDietaryRestrictions = useState<List<String>>([]);
    final isLoading = useState(false);
    final suggestedRecipes = useState<List<Recipe>?>(null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Recipe Suggestions'),
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
                    'Get AI-powered recipe suggestions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ingredientsController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredients *',
                      hintText: 'e.g., chicken, tomatoes, basil',
                      helperText: 'Separate with commas',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: cuisineController,
                    decoration: const InputDecoration(
                      labelText: 'Cuisine',
                      hintText: 'e.g., Italian, Mexican, Chinese',
                    ),
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
                          controller: maxPrepTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Max Prep Time (min)',
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading.value
                          ? null
                          : () async {
                              if (ingredientsController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter ingredients'),
                                  ),
                                );
                                return;
                              }

                              isLoading.value = true;
                              suggestedRecipes.value = null;

                              final ingredients = ingredientsController.text
                                  .split(',')
                                  .map((i) => i.trim())
                                  .where((i) => i.isNotEmpty)
                                  .toList();

                              final request = RecipeSuggestionRequest(
                                ingredients: ingredients,
                                cuisine: cuisineController.text.isEmpty
                                    ? null
                                    : cuisineController.text,
                                servings: int.tryParse(servingsController.text),
                                maxPrepTime:
                                    int.tryParse(maxPrepTimeController.text),
                                dietaryRestrictions:
                                    selectedDietaryRestrictions.value.isEmpty
                                        ? null
                                        : selectedDietaryRestrictions.value,
                              );

                              final repository = ref.read(aiRepositoryProvider);
                              final result = await repository.suggestRecipes(request);

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
                                  suggestedRecipes.value = response.suggestions;
                                  if (response.suggestions.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('No suggestions found'),
                                      ),
                                    );
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
                          : 'Get Suggestions'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (suggestedRecipes.value != null) ...[
            const SizedBox(height: 24),
            Text(
              'Suggestions (${suggestedRecipes.value!.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...suggestedRecipes.value!.map((recipe) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    recipe.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipe.description),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.prepTime + recipe.cookTime} min',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.people, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.servings} servings',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      // Save the suggested recipe
                      final repository = ref.read(recipeRepositoryProvider);
                      final recipeCreate = RecipeCreate(
                        title: recipe.title,
                        description: recipe.description,
                        instructions: recipe.instructions,
                        prepTime: recipe.prepTime,
                        cookTime: recipe.cookTime,
                        servings: recipe.servings,
                        difficulty: recipe.difficulty,
                        categories: recipe.categories,
                        tags: recipe.tags,
                        ingredients: recipe.ingredients
                            .asMap()
                            .entries
                            .map((entry) => IngredientCreate(
                                  name: entry.value.name,
                                  quantity: entry.value.quantity,
                                  unit: entry.value.unit,
                                  notes: entry.value.notes,
                                  optional: entry.value.optional,
                                  order: entry.key,
                                ))
                            .toList(),
                      );

                      final result = await repository.createRecipe(recipeCreate);

                      result.fold(
                        (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error saving: $error'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        (saved) {
                          if (context.mounted) {
                            ref.invalidate(recipesProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Recipe saved!'),
                              ),
                            );
                            context.go('/recipes/${saved.id}');
                          }
                        },
                      );
                    },
                    child: const Text('Save'),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
