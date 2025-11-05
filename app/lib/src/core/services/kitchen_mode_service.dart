/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// Service for managing kitchen mode features
/// Handles screen wake lock, brightness control, and haptic feedback
class KitchenModeService {
  bool _isScreenOnLocked = false;
  double? _originalBrightness;
  final _screenBrightness = ScreenBrightness();

  /// Enable kitchen mode with screen wake lock and brightness
  Future<void> enableKitchenMode({double? brightness}) async {
    await enableScreenWakeLock();
    if (brightness != null) {
      await setBrightness(brightness);
    }
  }

  /// Disable kitchen mode and restore original settings
  Future<void> disableKitchenMode() async {
    await disableScreenWakeLock();
    if (_originalBrightness != null) {
      await resetBrightness();
    }
  }

  /// Enable screen wake lock to prevent screen from turning off
  Future<void> enableScreenWakeLock() async {
    if (_isScreenOnLocked) return;

    try {
      await WakelockPlus.enable();
      _isScreenOnLocked = true;
    } catch (e) {
      print('Failed to enable screen wake lock: $e');
    }
  }

  /// Disable screen wake lock
  Future<void> disableScreenWakeLock() async {
    if (!_isScreenOnLocked) return;

    try {
      await WakelockPlus.disable();
      _isScreenOnLocked = false;
    } catch (e) {
      print('Failed to disable screen wake lock: $e');
    }
  }

  /// Set screen brightness (0.0 to 1.0)
  Future<void> setBrightness(double brightness) async {
    try {
      // Store original brightness if not already stored
      if (_originalBrightness == null) {
        _originalBrightness = await getBrightness();
      }

      await _screenBrightness.setScreenBrightness(brightness);
    } catch (e) {
      print('Failed to set brightness: $e');
    }
  }

  /// Get current screen brightness
  Future<double> getBrightness() async {
    try {
      final brightness = await _screenBrightness.current;
      return brightness;
    } catch (e) {
      print('Failed to get brightness: $e');
      return 0.5;
    }
  }

  /// Reset brightness to system default
  Future<void> resetBrightness() async {
    try {
      await _screenBrightness.resetScreenBrightness();
      _originalBrightness = null;
    } catch (e) {
      print('Failed to reset brightness: $e');
    }
  }

  /// Provide haptic feedback
  Future<void> hapticFeedback(HapticFeedbackType type) async {
    switch (type) {
      case HapticFeedbackType.light:
        await HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        await HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        await HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.success:
        // Note: May require custom implementation for success pattern
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.warning:
        // Note: May require custom implementation for warning pattern
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 50));
        await HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.error:
        // Note: May require custom implementation for error pattern
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.heavyImpact();
        break;
    }
  }

  /// Check if screen wake lock is enabled
  bool get isScreenOnLocked => _isScreenOnLocked;

  /// Dispose resources
  void dispose() {
    if (_isScreenOnLocked) {
      disableScreenWakeLock();
    }
    if (_originalBrightness != null) {
      resetBrightness();
    }
  }
}

/// Haptic feedback types for kitchen mode
enum HapticFeedbackType {
  light, // Light tap (e.g., button press)
  medium, // Medium tap (e.g., checkbox toggle)
  heavy, // Heavy tap (e.g., important action)
  selection, // Selection change (e.g., picker)
  success, // Success pattern (e.g., timer complete)
  warning, // Warning pattern (e.g., timer expiring soon)
  error, // Error pattern (e.g., invalid action)
}
