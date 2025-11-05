/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/shopping_list.dart';

part 'shopping_list_api.g.dart';

@RestApi()
abstract class ShoppingListApi {
  factory ShoppingListApi(Dio dio, {String baseUrl}) = _ShoppingListApi;

  @GET('/shopping-list')
  Future<List<ShoppingListItem>> getShoppingListItems();

  @GET('/shopping-list/{id}')
  Future<ShoppingListItem> getShoppingListItem(@Path('id') String id);

  @POST('/shopping-list')
  Future<ShoppingListItem> createShoppingListItem(
    @Body() ShoppingListItemCreate item,
  );

  @PUT('/shopping-list/{id}')
  Future<ShoppingListItem> updateShoppingListItem(
    @Path('id') String id,
    @Body() ShoppingListItemCreate item,
  );

  @PUT('/shopping-list/{id}/toggle')
  Future<ShoppingListItem> toggleShoppingListItem(@Path('id') String id);

  @DELETE('/shopping-list/{id}')
  Future<void> deleteShoppingListItem(@Path('id') String id);

  @DELETE('/shopping-list/completed')
  Future<void> clearCompleted();
}
