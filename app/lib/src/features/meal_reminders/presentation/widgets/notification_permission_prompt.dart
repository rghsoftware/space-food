/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/meal_reminder_providers.dart';

/// Widget to prompt for notification permissions
class NotificationPermissionPrompt extends ConsumerWidget {
  final VoidCallback? onGranted;
  final VoidCallback? onDenied;

  const NotificationPermissionPrompt({
    super.key,
    this.onGranted,
    this.onDenied,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionStatus = ref.watch(notificationPermissionStatusProvider);

    return permissionStatus.when(
      data: (isGranted) {
        if (isGranted) {
          // Permissions already granted
          return const SizedBox.shrink();
        }

        return _buildPrompt(context, ref);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildPrompt(context, ref),
    );
  }

  Widget _buildPrompt(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_active,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Enable Meal Reminders',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'To receive timely meal reminders, please allow notifications. '
              'This helps you remember to eat throughout the day.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      onDenied?.call();
                    },
                    child: const Text('Not Now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _requestPermissions(context, ref),
                    child: const Text('Enable'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPermissions(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(notificationPermissionStatusProvider.notifier);
    final granted = await notifier.requestPermissions();

    if (granted) {
      onGranted?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Notifications enabled!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      onDenied?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notifications disabled. '
                'You can enable them later in app settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                // TODO: Open app settings
              },
            ),
          ),
        );
      }
    }
  }
}

/// Full-screen onboarding for notification permissions
class NotificationPermissionOnboarding extends ConsumerWidget {
  final VoidCallback? onComplete;

  const NotificationPermissionOnboarding({
    super.key,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.notifications_active_outlined,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Never Forget to Eat',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Set up meal reminders to help you remember to eat '
                'throughout the day. Perfect for busy schedules and ADHD.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildFeature(
                context,
                icon: Icons.alarm,
                title: 'Smart Reminders',
                description: 'Get notified before and during meal times',
              ),
              const SizedBox(height: 20),
              _buildFeature(
                context,
                icon: Icons.touch_app,
                title: 'One-Tap Logging',
                description: 'Log meals instantly with minimal effort',
              ),
              const SizedBox(height: 20),
              _buildFeature(
                context,
                icon: Icons.insights,
                title: 'Progress Tracking',
                description: 'See your eating patterns without judgment',
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => _requestPermissions(context, ref),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Enable Notifications'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  onComplete?.call();
                },
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _requestPermissions(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(notificationPermissionStatusProvider.notifier);
    await notifier.requestPermissions();

    onComplete?.call();
  }
}
