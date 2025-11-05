/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/recipe.dart';

part 'recipe_api.g.dart';

@RestApi()
abstract class RecipeApi {
  factory RecipeApi(Dio dio, {String baseUrl}) = _RecipeApi;

  @GET('/recipes')
  Future<List<Recipe>> getRecipes();

  @GET('/recipes/{id}')
  Future<Recipe> getRecipe(@Path('id') String id);

  @POST('/recipes')
  Future<Recipe> createRecipe(@Body() RecipeCreate recipe);

  @PUT('/recipes/{id}')
  Future<Recipe> updateRecipe(
    @Path('id') String id,
    @Body() RecipeCreate recipe,
  );

  @DELETE('/recipes/{id}')
  Future<void> deleteRecipe(@Path('id') String id);

  @GET('/recipes/search')
  Future<List<Recipe>> searchRecipes(@Query('q') String query);

  @POST('/recipes/import')
  Future<Recipe> importRecipe(@Body() Map<String, String> body);

  @POST('/recipes/{id}/image')
  @MultiPart()
  Future<Map<String, String>> uploadImage(
    @Path('id') String id,
    @Part(name: 'image') File image,
  );
}
