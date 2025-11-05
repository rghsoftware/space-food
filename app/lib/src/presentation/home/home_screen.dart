/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/responsive_builder.dart';
import '../../core/constants/touch_targets.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Space Food'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              ref.read(currentUserProvider.notifier).state = null;
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: ResponsiveBuilder(
        builder: (context, info) {
          // Determine grid columns based on device type
          final crossAxisCount = info.isMobile
              ? 2
              : info.isTablet
                  ? 3
                  : 4;

          // Use responsive padding
          final padding = info.standardPadding;

          // Use responsive spacing
          final spacing = info.isKitchenMode ? 24.0 : 16.0;

          return GridView.count(
            crossAxisCount: crossAxisCount,
            padding: padding,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            children: [
              _buildFeatureCard(
                context,
                info,
                icon: Icons.restaurant_menu,
                title: 'Recipes',
                subtitle: 'Browse and manage recipes',
                color: Colors.orange,
                onTap: () {
                  context.push('/recipes');
                },
              ),
              _buildFeatureCard(
                context,
                info,
                icon: Icons.calendar_today,
                title: 'Meal Plans',
                subtitle: 'Plan your meals',
                color: Colors.blue,
                onTap: () {
                  context.push('/meal-plans');
                },
              ),
              _buildFeatureCard(
                context,
                info,
                icon: Icons.inventory,
                title: 'Pantry',
                subtitle: 'Track your ingredients',
                color: Colors.green,
                onTap: () {
                  context.push('/pantry');
                },
              ),
              _buildFeatureCard(
                context,
                info,
                icon: Icons.shopping_cart,
                title: 'Shopping',
                subtitle: 'Your shopping lists',
                color: Colors.purple,
                onTap: () {
                  context.push('/shopping-list');
                },
              ),
              _buildFeatureCard(
                context,
                info,
                icon: Icons.analytics,
                title: 'Nutrition',
                subtitle: 'Track your nutrition',
                color: Colors.red,
                onTap: () {
                  context.push('/nutrition');
                },
              ),
              _buildFeatureCard(
                context,
                info,
                icon: Icons.people,
                title: 'Household',
                subtitle: 'Family sharing',
                color: Colors.teal,
                onTap: () {
                  context.push('/households');
                },
              ),
              _buildFeatureCard(
                context,
                info,
                icon: Icons.auto_awesome,
                title: 'AI Recipes',
                subtitle: 'Get AI suggestions',
                color: Colors.deepPurple,
                onTap: () {
                  context.push('/ai/recipe-suggest');
                },
              ),
              _buildFeatureCard(
                context,
                info,
                icon: Icons.psychology,
                title: 'AI Meal Plans',
                subtitle: 'Generate with AI',
                color: Colors.indigo,
                onTap: () {
                  context.push('/ai/meal-plan-generate');
                },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: user != null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Welcome, ${user.firstName} ${user.lastName}!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : null,
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    ResponsiveInfo info, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Responsive icon size
    final iconSize = info.isMobile
        ? 48.0
        : info.isTablet
            ? 56.0
            : 64.0;

    // Responsive padding
    final cardPadding = info.isMobile ? 16.0 : 20.0;

    // Responsive spacing
    final spacing = info.isMobile ? 12.0 : 16.0;

    // Minimum touch target size for card
    final minTouchTarget = TouchTargets.forDeviceType(
      info.deviceType,
      isKitchenMode: info.isKitchenMode,
    );

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: BoxConstraints(
            minHeight: minTouchTarget,
            minWidth: minTouchTarget,
          ),
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: color),
              SizedBox(height: spacing),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: info.isMobile ? 14 : 16,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: info.isMobile ? 12 : 14,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
