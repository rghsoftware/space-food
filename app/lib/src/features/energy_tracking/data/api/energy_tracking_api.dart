/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/energy_snapshot.dart';
import '../models/favorite_meal.dart';

part 'energy_tracking_api.g.dart';

@RestApi()
abstract class EnergyTrackingApi {
  factory EnergyTrackingApi(Dio dio, {String baseUrl}) = _EnergyTrackingApi;

  // Energy recording and history endpoints
  @POST('/energy/record')
  Future<EnergySnapshot> recordEnergy(@Body() RecordEnergyRequest request);

  @GET('/energy/history')
  Future<EnergySnapshotsResponse> getEnergyHistory(@Query('days') int? days);

  @GET('/energy/patterns')
  Future<Map<String, dynamic>> getEnergyPatterns();

  @GET('/energy/recommendations')
  Future<EnergyBasedRecommendation> getRecommendations(
    @Query('energy_level') int? energyLevel,
  );

  @GET('/energy/recipes')
  Future<Map<String, dynamic>> getRecipesByEnergy(
    @Query('max_energy_level') int? maxEnergyLevel,
    @Query('limit') int? limit,
  );

  // Favorite meals endpoints
  @POST('/favorite-meals')
  Future<FavoriteMeal> saveFavoriteMeal(@Body() SaveFavoriteMealRequest request);

  @GET('/favorite-meals')
  Future<Map<String, dynamic>> getFavoriteMeals(
    @Query('energy_level') int? energyLevel,
    @Query('time_of_day') String? timeOfDay,
    @Query('max_results') int? maxResults,
  );

  @GET('/favorite-meals/{id}')
  Future<FavoriteMeal> getFavoriteMeal(@Path('id') String id);

  @PUT('/favorite-meals/{id}')
  Future<FavoriteMeal> updateFavoriteMeal(
    @Path('id') String id,
    @Body() UpdateFavoriteMealRequest request,
  );

  @POST('/favorite-meals/{id}/eaten')
  Future<void> markMealEaten(@Path('id') String id);

  @DELETE('/favorite-meals/{id}')
  Future<void> deleteFavoriteMeal(@Path('id') String id);
}
