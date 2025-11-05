/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/meal_plan_api.dart';
import '../../data/models/meal_plan.dart';
import '../../data/repositories/meal_plan_repository.dart';
import 'auth_provider.dart';

// Meal Plan API provider
final mealPlanApiProvider = Provider<MealPlanApi>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return MealPlanApi(dioClient.dio);
});

// Meal Plan repository provider
final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  final mealPlanApi = ref.watch(mealPlanApiProvider);
  return MealPlanRepository(mealPlanApi);
});

// Meal Plans list provider
final mealPlansProvider = FutureProvider<List<MealPlan>>((ref) async {
  final repository = ref.watch(mealPlanRepositoryProvider);
  final result = await repository.getMealPlans();

  return result.fold(
    (error) => throw Exception(error.toString()),
    (mealPlans) => mealPlans,
  );
});

// Meal Plans by date range provider
final mealPlansByDateRangeProvider = FutureProvider.family<
    List<MealPlan>, ({DateTime start, DateTime end})>((ref, dates) async {
  final repository = ref.watch(mealPlanRepositoryProvider);
  final result = await repository.getMealPlans(
    startDate: dates.start,
    endDate: dates.end,
  );

  return result.fold(
    (error) => throw Exception(error.toString()),
    (mealPlans) => mealPlans,
  );
});

// Single meal plan provider
final mealPlanProvider =
    FutureProvider.family<MealPlan, String>((ref, id) async {
  final repository = ref.watch(mealPlanRepositoryProvider);
  final result = await repository.getMealPlan(id);

  return result.fold(
    (error) => throw Exception(error.toString()),
    (mealPlan) => mealPlan,
  );
});
