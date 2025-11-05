/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/shopping_list_api.dart';
import '../../data/models/shopping_list.dart';
import '../../data/repositories/shopping_list_repository.dart';
import 'auth_provider.dart';

// Shopping List API provider
final shoppingListApiProvider = Provider<ShoppingListApi>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ShoppingListApi(dioClient.dio);
});

// Shopping List repository provider
final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  final shoppingListApi = ref.watch(shoppingListApiProvider);
  return ShoppingListRepository(shoppingListApi);
});

// Shopping list items provider
final shoppingListItemsProvider =
    FutureProvider<List<ShoppingListItem>>((ref) async {
  final repository = ref.watch(shoppingListRepositoryProvider);
  final result = await repository.getShoppingListItems();

  return result.fold(
    (error) => throw Exception(error.toString()),
    (items) => items,
  );
});

// Single shopping list item provider
final shoppingListItemProvider =
    FutureProvider.family<ShoppingListItem, String>((ref, id) async {
  final repository = ref.watch(shoppingListRepositoryProvider);
  final result = await repository.getShoppingListItem(id);

  return result.fold(
    (error) => throw Exception(error.toString()),
    (item) => item,
  );
});
