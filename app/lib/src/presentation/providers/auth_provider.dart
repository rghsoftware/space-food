/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/dio_client.dart';
import '../../data/api/auth_api.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

// Secure storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Dio client provider
final dioClientProvider = Provider<DioClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DioClient(secureStorage);
});

// Auth API provider
final authApiProvider = Provider<AuthApi>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthApi(dioClient.dio);
});

// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authApi = ref.watch(authApiProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepository(authApi, secureStorage);
});

// Current user provider
final currentUserProvider = StateProvider<User?>((ref) => null);

// Auth state provider
final authStateProvider = FutureProvider<bool>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.isAuthenticated();
});
