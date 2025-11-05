/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildFeatureCard(
            context,
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
            icon: Icons.psychology,
            title: 'AI Meal Plans',
            subtitle: 'Generate with AI',
            color: Colors.indigo,
            onTap: () {
              context.push('/ai/meal-plan-generate');
            },
          ),
        ],
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
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
