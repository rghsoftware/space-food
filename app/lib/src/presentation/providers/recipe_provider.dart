/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/recipe_api.dart';
import '../../data/models/recipe.dart';
import '../../data/repositories/recipe_repository.dart';
import 'auth_provider.dart';

// Recipe API provider
final recipeApiProvider = Provider<RecipeApi>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return RecipeApi(dioClient.dio);
});

// Recipe repository provider
final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  final recipeApi = ref.watch(recipeApiProvider);
  return RecipeRepository(recipeApi);
});

// Recipes list provider
final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repository = ref.watch(recipeRepositoryProvider);
  final result = await repository.getRecipes();

  return result.fold(
    (error) => throw Exception(error.toString()),
    (recipes) => recipes,
  );
});

// Single recipe provider
final recipeProvider = FutureProvider.family<Recipe, String>((ref, id) async {
  final repository = ref.watch(recipeRepositoryProvider);
  final result = await repository.getRecipe(id);

  return result.fold(
    (error) => throw Exception(error.toString()),
    (recipe) => recipe,
  );
});

// Search results provider
final recipeSearchProvider = FutureProvider.family<List<Recipe>, String>(
  (ref, query) async {
    if (query.isEmpty) return [];

    final repository = ref.watch(recipeRepositoryProvider);
    final result = await repository.searchRecipes(query);

    return result.fold(
      (error) => throw Exception(error.toString()),
      (recipes) => recipes,
    );
  },
);
