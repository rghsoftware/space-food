/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/household.dart';

part 'household_api.g.dart';

@RestApi()
abstract class HouseholdApi {
  factory HouseholdApi(Dio dio, {String baseUrl}) = _HouseholdApi;

  @GET('/households')
  Future<List<Household>> getHouseholds();

  @GET('/households/{id}')
  Future<Household> getHousehold(@Path('id') String id);

  @POST('/households')
  Future<Household> createHousehold(@Body() HouseholdCreate household);

  @PUT('/households/{id}')
  Future<Household> updateHousehold(
    @Path('id') String id,
    @Body() HouseholdCreate household,
  );

  @DELETE('/households/{id}')
  Future<void> deleteHousehold(@Path('id') String id);

  @GET('/households/{id}/members')
  Future<List<HouseholdMember>> getMembers(@Path('id') String id);

  @POST('/households/{id}/members')
  Future<HouseholdMember> addMember(
    @Path('id') String id,
    @Body() HouseholdInvitation invitation,
  );

  @DELETE('/households/{household_id}/members/{user_id}')
  Future<void> removeMember(
    @Path('household_id') String householdId,
    @Path('user_id') String userId,
  );
}
