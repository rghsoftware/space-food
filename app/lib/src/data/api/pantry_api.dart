/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/pantry.dart';

part 'pantry_api.g.dart';

@RestApi()
abstract class PantryApi {
  factory PantryApi(Dio dio, {String baseUrl}) = _PantryApi;

  @GET('/pantry')
  Future<List<PantryItem>> getPantryItems({
    @Query('category') String? category,
  });

  @GET('/pantry/{id}')
  Future<PantryItem> getPantryItem(@Path('id') String id);

  @POST('/pantry')
  Future<PantryItem> createPantryItem(@Body() PantryItemCreate item);

  @PUT('/pantry/{id}')
  Future<PantryItem> updatePantryItem(
    @Path('id') String id,
    @Body() PantryItemCreate item,
  );

  @DELETE('/pantry/{id}')
  Future<void> deletePantryItem(@Path('id') String id);
}
