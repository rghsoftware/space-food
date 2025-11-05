/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/meal_plan.dart';

part 'meal_plan_api.g.dart';

@RestApi()
abstract class MealPlanApi {
  factory MealPlanApi(Dio dio, {String baseUrl}) = _MealPlanApi;

  @GET('/meal-plans')
  Future<List<MealPlan>> getMealPlans({
    @Query('start_date') String? startDate,
    @Query('end_date') String? endDate,
  });

  @GET('/meal-plans/{id}')
  Future<MealPlan> getMealPlan(@Path('id') String id);

  @POST('/meal-plans')
  Future<MealPlan> createMealPlan(@Body() MealPlanCreate mealPlan);

  @PUT('/meal-plans/{id}')
  Future<MealPlan> updateMealPlan(
    @Path('id') String id,
    @Body() MealPlanCreate mealPlan,
  );

  @DELETE('/meal-plans/{id}')
  Future<void> deleteMealPlan(@Path('id') String id);

  @POST('/meal-plans/{id}/meals')
  Future<PlannedMeal> addPlannedMeal(
    @Path('id') String mealPlanId,
    @Body() PlannedMealCreate meal,
  );

  @DELETE('/meal-plans/{meal_plan_id}/meals/{meal_id}')
  Future<void> deletePlannedMeal(
    @Path('meal_plan_id') String mealPlanId,
    @Path('meal_id') String mealId,
  );
}
