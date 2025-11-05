/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/ai_api.dart';
import '../../data/repositories/ai_repository.dart';
import 'auth_provider.dart';

// AI API provider
final aiApiProvider = Provider<AiApi>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AiApi(dioClient.dio);
});

// AI repository provider
final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final aiApi = ref.watch(aiApiProvider);
  return AiRepository(aiApi);
});
