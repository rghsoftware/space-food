/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/household_api.dart';
import '../../data/models/household.dart';
import '../../data/repositories/household_repository.dart';
import 'auth_provider.dart';

// Household API provider
final householdApiProvider = Provider<HouseholdApi>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return HouseholdApi(dioClient.dio);
});

// Household repository provider
final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  final householdApi = ref.watch(householdApiProvider);
  return HouseholdRepository(householdApi);
});

// Households list provider
final householdsProvider = FutureProvider<List<Household>>((ref) async {
  final repository = ref.watch(householdRepositoryProvider);
  final result = await repository.getHouseholds();

  return result.fold(
    (error) => throw Exception(error.toString()),
    (households) => households,
  );
});

// Single household provider
final householdProvider =
    FutureProvider.family<Household, String>((ref, id) async {
  final repository = ref.watch(householdRepositoryProvider);
  final result = await repository.getHousehold(id);

  return result.fold(
    (error) => throw Exception(error.toString()),
    (household) => household,
  );
});

// Household members provider
final householdMembersProvider =
    FutureProvider.family<List<HouseholdMember>, String>((ref, id) async {
  final repository = ref.watch(householdRepositoryProvider);
  final result = await repository.getMembers(id);

  return result.fold(
    (error) => throw Exception(error.toString()),
    (members) => members,
  );
});
