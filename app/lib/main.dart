/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'src/app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SpaceFoodApp(),
    ),
  );
}
