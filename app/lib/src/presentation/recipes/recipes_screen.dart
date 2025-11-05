/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/recipe_provider.dart';
import '../../data/models/recipe.dart';
import '../../core/constants/offline_capabilities.dart';
import '../widgets/swipeable_recipe_card.dart';
import '../widgets/pull_to_refresh_wrapper.dart';
import '../widgets/offline_banner.dart';
import '../widgets/offline_aware_button.dart';

class RecipesScreen extends HookConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final searchQuery = useState('');

    final recipesAsync = searchQuery.value.isEmpty
        ? ref.watch(recipesProvider)
        : ref.watch(recipeSearchProvider(searchQuery.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        actions: [
          const OfflineIndicator(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/recipes/create');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          searchQuery.value = '';
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (searchController.text == value) {
                    searchQuery.value = value;
                  }
                });
              },
            ),
          ),

          // Recipe list
          Expanded(
            child: recipesAsync.when(
              data: (recipes) {
                if (recipes.isEmpty) {
                  return OfflineAwarePullToRefresh(
                    onRefresh: () async {
                      ref.invalidate(recipesProvider);
                      await ref.read(recipesProvider.future);
                    },
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
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
                                  searchQuery.value.isEmpty
                                      ? 'No recipes yet'
                                      : 'No recipes found',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  searchQuery.value.isEmpty
                                      ? 'Tap + to create your first recipe'
                                      : 'Try a different search',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return OfflineAwarePullToRefresh(
                  onRefresh: () async {
                    ref.invalidate(recipesProvider);
                    await ref.read(recipesProvider.future);
                  },
                  child: ListView.builder(
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return SwipeableRecipeCard(
                        recipe: recipe,
                        onTap: () => context.push('/recipes/${recipe.id}'),
                        onEdit: () => context.push('/recipes/${recipe.id}/edit'),
                        onDelete: () async {
                          final repository = ref.read(recipeRepositoryProvider);
                          final result = await repository.deleteRecipe(recipe.id);

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
                              ref.invalidate(recipesProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Recipe deleted'),
                                  ),
                                );
                              }
                            },
                          );
                        },
                        onAddToMealPlan: () {
                          // TODO: Implement add to meal plan
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Add to meal plan coming soon!'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading recipes',
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
                        ref.invalidate(recipesProvider);
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
        onPressed: () {
          // Show options: Create or Import
          showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Create Recipe'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/recipes/create');
                    },
                  ),
                  OfflineAwareButton(
                    offlineCapability: FeatureOfflineCapabilities.importRecipe,
                    offlineMessage: 'Recipe import requires internet connection',
                    elevated: false,
                    onPressed: () {
                      Navigator.pop(context);
                      _showImportDialog(context, ref);
                    },
                    child: const ListTile(
                      leading: Icon(Icons.link),
                      title: Text('Import from URL'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Recipe'),
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Recipe'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Recipe URL',
            hintText: 'https://example.com/recipe',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OfflineAwareButton(
            offlineCapability: FeatureOfflineCapabilities.importRecipe,
            offlineMessage: 'Recipe import requires internet connection',
            onPressed: () async {
              if (controller.text.isEmpty) return;

              Navigator.pop(context);

              final repository = ref.read(recipeRepositoryProvider);
              final result = await repository.importRecipe(controller.text);

              result.fold(
                (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to import: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                (recipe) {
                  if (context.mounted) {
                    ref.invalidate(recipesProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recipe imported successfully!'),
                      ),
                    );
                    context.push('/recipes/${recipe.id}');
                  }
                },
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}

