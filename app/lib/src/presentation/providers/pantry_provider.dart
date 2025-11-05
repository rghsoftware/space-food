/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/pantry_api.dart';
import '../../data/models/pantry.dart';
import '../../data/repositories/pantry_repository.dart';
import 'auth_provider.dart';

// Pantry API provider
final pantryApiProvider = Provider<PantryApi>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return PantryApi(dioClient.dio);
});

// Pantry repository provider
final pantryRepositoryProvider = Provider<PantryRepository>((ref) {
  final pantryApi = ref.watch(pantryApiProvider);
  return PantryRepository(pantryApi);
});

// Pantry items list provider
final pantryItemsProvider = FutureProvider<List<PantryItem>>((ref) async {
  final repository = ref.watch(pantryRepositoryProvider);
  final result = await repository.getPantryItems();

  return result.fold(
    (error) => throw Exception(error.toString()),
    (items) => items,
  );
});

// Pantry items by category provider
final pantryItemsByCategoryProvider =
    FutureProvider.family<List<PantryItem>, String?>((ref, category) async {
  final repository = ref.watch(pantryRepositoryProvider);
  final result = await repository.getPantryItems(category: category);

  return result.fold(
    (error) => throw Exception(error.toString()),
    (items) => items,
  );
});

// Single pantry item provider
final pantryItemProvider =
    FutureProvider.family<PantryItem, String>((ref, id) async {
  final repository = ref.watch(pantryRepositoryProvider);
  final result = await repository.getPantryItem(id);

  return result.fold(
    (error) => throw Exception(error.toString()),
    (item) => item,
  );
});
