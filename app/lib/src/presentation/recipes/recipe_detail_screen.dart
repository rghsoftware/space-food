/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../providers/kitchen_mode_provider.dart';
import '../kitchen/kitchen_recipe_view.dart';

class RecipeDetailScreen extends HookConsumerWidget {
  final String recipeId;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeProvider(recipeId));

    return Scaffold(
      body: recipeAsync.when(
        data: (recipe) => _buildRecipeDetail(context, ref, recipe),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load recipe',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(recipeProvider(recipeId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeDetail(
    BuildContext context,
    WidgetRef ref,
    Recipe recipe,
  ) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              recipe.title,
              style: const TextStyle(
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
            background: recipe.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: recipe.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant, size: 100),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.restaurant, size: 100),
                  ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.kitchen),
              tooltip: 'Kitchen Mode',
              onPressed: () async {
                // Enable kitchen mode and navigate to kitchen view
                final kitchenModeNotifier =
                    ref.read(kitchenModeStateProvider.notifier);
                await kitchenModeNotifier.enableKitchenMode();

                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => KitchenRecipeView(recipe: recipe),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/recipes/$recipeId/edit');
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Recipe'),
                      content: const Text(
                        'Are you sure you want to delete this recipe?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    final repository = ref.read(recipeRepositoryProvider);
                    final result = await repository.deleteRecipe(recipeId);

                    result.fold(
                      (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to delete: $error'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      (_) {
                        if (context.mounted) {
                          ref.invalidate(recipesProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Recipe deleted'),
                            ),
                          );
                          context.go('/recipes');
                        }
                      },
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildMetadataRow(context, recipe),
              const SizedBox(height: 16),
              _buildDescription(context, recipe),
              const SizedBox(height: 24),
              _buildIngredientsSection(context, recipe),
              const SizedBox(height: 24),
              _buildInstructionsSection(context, recipe),
              if (recipe.nutritionInfo != null) ...[
                const SizedBox(height: 24),
                _buildNutritionSection(context, recipe.nutritionInfo!),
              ],
              const SizedBox(height: 24),
              _buildTagsSection(context, recipe),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(BuildContext context, Recipe recipe) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetadataItem(
          context,
          icon: Icons.timer,
          label: 'Prep',
          value: '${recipe.prepTime} min',
        ),
        _buildMetadataItem(
          context,
          icon: Icons.microwave,
          label: 'Cook',
          value: '${recipe.cookTime} min',
        ),
        _buildMetadataItem(
          context,
          icon: Icons.people,
          label: 'Servings',
          value: '${recipe.servings}',
        ),
        _buildMetadataItem(
          context,
          icon: Icons.speed,
          label: 'Difficulty',
          value: recipe.difficulty,
        ),
      ],
    );
  }

  Widget _buildMetadataItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context, Recipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.star,
              color: Colors.amber,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              recipe.rating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          recipe.description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildIngredientsSection(BuildContext context, Recipe recipe) {
    // Sort ingredients by order
    final sortedIngredients = [...recipe.ingredients]
      ..sort((a, b) => a.order.compareTo(b.order));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingredients',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...sortedIngredients.map((ingredient) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: ingredient.optional
                              ? Colors.grey
                              : Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyLarge,
                            children: [
                              TextSpan(
                                text:
                                    '${ingredient.quantity} ${ingredient.unit} ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: ingredient.name),
                              if (ingredient.optional)
                                TextSpan(
                                  text: ' (optional)',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              if (ingredient.notes != null)
                                TextSpan(
                                  text: ' - ${ingredient.notes}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsSection(BuildContext context, Recipe recipe) {
    // Split instructions by newlines and filter empty lines
    final steps = recipe.instructions
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instructions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step.trim(),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionSection(
    BuildContext context,
    NutritionInfo nutrition,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Information (per serving)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildNutritionRow(
              context,
              'Calories',
              '${nutrition.calories.toStringAsFixed(0)} kcal',
            ),
            _buildNutritionRow(
              context,
              'Protein',
              '${nutrition.protein.toStringAsFixed(1)}g',
            ),
            _buildNutritionRow(
              context,
              'Carbohydrates',
              '${nutrition.carbohydrates.toStringAsFixed(1)}g',
            ),
            _buildNutritionRow(
              context,
              'Fat',
              '${nutrition.fat.toStringAsFixed(1)}g',
            ),
            _buildNutritionRow(
              context,
              'Fiber',
              '${nutrition.fiber.toStringAsFixed(1)}g',
            ),
            _buildNutritionRow(
              context,
              'Sugar',
              '${nutrition.sugar.toStringAsFixed(1)}g',
            ),
            _buildNutritionRow(
              context,
              'Sodium',
              '${nutrition.sodium.toStringAsFixed(0)}mg',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context, Recipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recipe.categories.isNotEmpty) ...[
          Text(
            'Categories',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recipe.categories.map((category) {
              return Chip(
                label: Text(category),
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.5),
              );
            }).toList(),
          ),
        ],
        if (recipe.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Tags',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recipe.tags.map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: Colors.grey[200],
              );
            }).toList(),
          ),
        ],
        if (recipe.source != null || recipe.sourceUrl != null) ...[
          const SizedBox(height: 16),
          Text(
            'Source',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          if (recipe.source != null)
            Text(
              recipe.source!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (recipe.sourceUrl != null)
            Text(
              recipe.sourceUrl!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
            ),
        ],
      ],
    );
  }
}
