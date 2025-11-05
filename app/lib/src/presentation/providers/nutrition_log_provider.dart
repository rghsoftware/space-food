/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/nutrition_log_api.dart';
import '../../data/models/nutrition_log.dart';
import '../../data/repositories/nutrition_log_repository.dart';
import 'auth_provider.dart';

// Nutrition Log API provider
final nutritionLogApiProvider = Provider<NutritionLogApi>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return NutritionLogApi(dioClient.dio);
});

// Nutrition Log repository provider
final nutritionLogRepositoryProvider = Provider<NutritionLogRepository>((ref) {
  final nutritionLogApi = ref.watch(nutritionLogApiProvider);
  return NutritionLogRepository(nutritionLogApi);
});

// Nutrition logs list provider
final nutritionLogsProvider = FutureProvider<List<NutritionLog>>((ref) async {
  final repository = ref.watch(nutritionLogRepositoryProvider);
  final result = await repository.getNutritionLogs();

  return result.fold(
    (error) => throw Exception(error.toString()),
    (logs) => logs,
  );
});

// Nutrition logs by date range provider
final nutritionLogsByDateRangeProvider = FutureProvider.family<
    List<NutritionLog>, ({DateTime start, DateTime end})>((ref, dates) async {
  final repository = ref.watch(nutritionLogRepositoryProvider);
  final result = await repository.getNutritionLogs(
    startDate: dates.start,
    endDate: dates.end,
  );

  return result.fold(
    (error) => throw Exception(error.toString()),
    (logs) => logs,
  );
});

// Nutrition summary provider
final nutritionSummaryProvider = FutureProvider.family<
    Map<String, dynamic>, ({DateTime start, DateTime end})>((ref, dates) async {
  final repository = ref.watch(nutritionLogRepositoryProvider);
  final result = await repository.getNutritionSummary(
    startDate: dates.start,
    endDate: dates.end,
  );

  return result.fold(
    (error) => throw Exception(error.toString()),
    (summary) => summary,
  );
});

// Single nutrition log provider
final nutritionLogProvider =
    FutureProvider.family<NutritionLog, String>((ref, id) async {
  final repository = ref.watch(nutritionLogRepositoryProvider);
  final result = await repository.getNutritionLog(id);

  return result.fold(
    (error) => throw Exception(error.toString()),
    (log) => log,
  );
});
