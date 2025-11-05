// Space Food - Self-Hosted Meal Planning Application
// Copyright (C) 2025 RGH Software
// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/food_variety_providers.dart';

class VarietyDashboardScreen extends ConsumerWidget {
  const VarietyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Get actual user ID from auth provider
    const userId = 'current-user-id';

    final analysisAsync = ref.watch(varietyAnalysisProvider);
    final hyperfixationsAsync = ref.watch(activeHyperfixationsProvider(userId));
    final insightsAsync = ref.watch(weeklyInsightsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Variety Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to nutrition settings
              Navigator.pushNamed(context, '/nutrition-settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(varietyAnalysisProvider);
          ref.invalidate(activeHyperfixationsProvider(userId));
          ref.invalidate(weeklyInsightsProvider(userId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Variety Score Card
            analysisAsync.when(
              data: (analysis) => _VarietyScoreCard(analysis: analysis),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _ErrorCard(
                message: 'Failed to load variety analysis: $error',
              ),
            ),
            const SizedBox(height: 16),

            // Quick Stats
            analysisAsync.when(
              data: (analysis) => _QuickStatsCard(analysis: analysis),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Active Hyperfixations
            hyperfixationsAsync.when(
              data: (hyperfixations) {
                if (hyperfixations.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _HyperfixationsCard(hyperfixations: hyperfixations);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Weekly Insights
            insightsAsync.when(
              data: (insights) {
                if (insights.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _InsightsCard(insights: insights);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            _ActionButtonsSection(),
          ],
        ),
      ),
    );
  }
}

class _VarietyScoreCard extends StatelessWidget {
  final dynamic analysis;

  const _VarietyScoreCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final score = analysis.varietyScore;
    final color = _getScoreColor(score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Variety Score',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score / 10,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Text(
                  '$score',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getScoreMessage(score),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 8) return Colors.green;
    if (score >= 5) return Colors.orange;
    return Colors.blue; // Blue, not red - non-judgmental
  }

  String _getScoreMessage(int score) {
    if (score >= 8) {
      return 'Great variety! You\'re exploring lots of different foods.';
    } else if (score >= 5) {
      return 'You have a good mix of foods. Keep doing what works for you!';
    } else {
      return 'You have your go-to foods and that\'s okay! Check out suggestions when you\'re ready.';
    }
  }
}

class _QuickStatsCard extends StatelessWidget {
  final dynamic analysis;

  const _QuickStatsCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _StatRow(
              label: 'Unique foods (7 days)',
              value: '${analysis.uniqueFoodsLast7Days}',
            ),
            _StatRow(
              label: 'Unique foods (30 days)',
              value: '${analysis.uniqueFoodsLast30Days}',
            ),
            if (analysis.topFoods.isNotEmpty)
              _StatRow(
                label: 'Most eaten food',
                value: analysis.topFoods[0].foodName,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _HyperfixationsCard extends ConsumerWidget {
  final List<dynamic> hyperfixations;

  const _HyperfixationsCard({required this.hyperfixations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Favorite Foods',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Foods you\'re enjoying often right now',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 12),
            ...hyperfixations.map((hyper) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.favorite, color: Colors.pink),
                  title: Text(hyper.foodName),
                  subtitle: Text(
                      '${hyper.frequencyCount} times since ${_formatDate(hyper.startedAt)}'),
                )),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}

class _InsightsCard extends ConsumerWidget {
  final List<dynamic> insights;

  const _InsightsCard({required this.insights});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Week\'s Insights',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...insights.map((insight) => Card(
                  color: Colors.blue[50],
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb, color: Colors.blue),
                    title: Text(insight.message),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () async {
                        await ref
                            .read(insightDismisserProvider.notifier)
                            .dismissInsight(insight.id);
                        ref.invalidate(weeklyInsightsProvider);
                      },
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ActionButtonsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionButton(
          icon: Icons.link,
          label: 'Get Food Suggestions',
          subtitle: 'Find similar foods to try',
          onTap: () {
            Navigator.pushNamed(context, '/food-chaining');
          },
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.calendar_month,
          label: 'Manage Rotations',
          subtitle: 'Create or edit meal rotations',
          onTap: () {
            Navigator.pushNamed(context, '/rotation-schedules');
          },
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.insights,
          label: 'Generate New Insights',
          subtitle: 'Create this week\'s insights',
          onTap: () async {
            // TODO: Get actual user ID
            // await ref.read(insightGeneratorProvider.notifier).generateInsights(userId: userId);
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(label),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
