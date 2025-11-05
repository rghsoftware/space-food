/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// Provides the current user ID
@riverpod
String currentUserId(CurrentUserIdRef ref) {
  // TODO: Get actual user ID from auth service
  // final authState = ref.watch(authStateProvider);
  // return authState.user?.id ?? '';

  return 'current-user-id'; // Placeholder for now
}

/// Provides the current auth token
@riverpod
String? authToken(AuthTokenRef ref) {
  // TODO: Get actual auth token from secure storage
  return null;
}
