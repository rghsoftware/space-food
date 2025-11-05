/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/nutrition_log.dart';

part 'nutrition_log_api.g.dart';

@RestApi()
abstract class NutritionLogApi {
  factory NutritionLogApi(Dio dio, {String baseUrl}) = _NutritionLogApi;

  @GET('/nutrition/logs')
  Future<List<NutritionLog>> getNutritionLogs({
    @Query('start_date') String? startDate,
    @Query('end_date') String? endDate,
  });

  @GET('/nutrition/logs/{id}')
  Future<NutritionLog> getNutritionLog(@Path('id') String id);

  @POST('/nutrition/logs')
  Future<NutritionLog> createNutritionLog(@Body() NutritionLogCreate log);

  @DELETE('/nutrition/logs/{id}')
  Future<void> deleteNutritionLog(@Path('id') String id);

  @GET('/nutrition/summary')
  Future<Map<String, dynamic>> getNutritionSummary({
    @Query('start_date') required String startDate,
    @Query('end_date') required String endDate,
  });
}
