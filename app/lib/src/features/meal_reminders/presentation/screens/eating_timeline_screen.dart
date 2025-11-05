/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/eating_timeline.dart';
import '../widgets/quick_meal_log_widget.dart';

/// Screen showing visual eating timeline (shame-free progress tracking)
class EatingTimelineScreen extends ConsumerStatefulWidget {
  const EatingTimelineScreen({super.key});

  @override
  ConsumerState<EatingTimelineScreen> createState() =>
      _EatingTimelineScreenState();
}

class _EatingTimelineScreenState extends ConsumerState<EatingTimelineScreen> {
  DateTime _selectedDate = DateTime.now();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Get timeline data from provider
    // final timelineAsync = ref.watch(timelineProvider(_selectedDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Eating Timeline'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Navigate to settings
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Timeline Settings',
          ),
        ],
      ),
      body: _buildTimeline(context),
      floatingActionButton: const QuickMealLogButton(),
    );
  }

  Widget _buildTimeline(BuildContext context) {
    // TODO: Replace with actual data from provider
    final mockTimeline = _generateMockTimeline();
    final mockSettings = const EatingTimelineSettings(
      userId: 'mock',
      dailyMealGoal: 3,
      dailySnackGoal: 2,
      showStreak: true,
      showMissedMeals: false,
      createdAt: null,
      updatedAt: null,
    );

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Header with streak and today's progress
        SliverToBoxAdapter(
          child: _buildHeader(context, mockTimeline, mockSettings),
        ),

        // Date picker
        SliverToBoxAdapter(
          child: _buildDatePicker(context),
        ),

        // Timeline visualization
        SliverToBoxAdapter(
          child: _buildTimelineGrid(context, mockTimeline, mockSettings),
        ),

        // Today's meals list
        SliverToBoxAdapter(
          child: _buildTodaysMeals(context),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    List<EatingTimeline> timeline,
    EatingTimelineSettings settings,
  ) {
    final today = timeline.firstWhere(
      (t) => _isSameDay(t.date, DateTime.now()),
      orElse: () => EatingTimeline(
        date: DateTime.now(),
        mealCount: 0,
        snackCount: 0,
        totalCount: 0,
        metGoals: false,
      ),
    );

    final currentStreak = timeline.first.streak ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Streak display (if enabled)
          if (settings.showStreak && currentStreak > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department,
                    size: 48, color: Colors.orange),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$currentStreak Day${currentStreak > 1 ? 's' : ''}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    Text(
                      'Current Streak',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Today's progress
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Today',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildProgressIndicator(
                        context,
                        icon: Icons.restaurant,
                        label: 'Meals',
                        current: today.mealCount,
                        goal: settings.dailyMealGoal,
                        color: Colors.blue,
                      ),
                      _buildProgressIndicator(
                        context,
                        icon: Icons.cookie,
                        label: 'Snacks',
                        current: today.snackCount,
                        goal: settings.dailySnackGoal,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int current,
    required int goal,
    required Color color,
  }) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final metGoal = current >= goal;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Icon(icon, size: 32, color: color),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          '$current / $goal',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: metGoal ? Colors.green : null,
              ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 7));
              });
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedDate),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 7));
              });
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineGrid(
    BuildContext context,
    List<EatingTimeline> timeline,
    EatingTimelineSettings settings,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 30 Days',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: timeline.length,
            itemBuilder: (context, index) {
              final day = timeline[index];
              return _buildDayCell(context, day, settings);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    EatingTimeline day,
    EatingTimelineSettings settings,
  ) {
    final isToday = _isSameDay(day.date, DateTime.now());
    final metGoals = day.metGoals;
    final hasData = day.totalCount > 0;

    // Determine cell color
    Color? cellColor;
    if (!hasData && settings.showMissedMeals) {
      cellColor = Colors.red.withOpacity(0.2);
    } else if (metGoals) {
      cellColor = Colors.green.withOpacity(0.7);
    } else if (hasData) {
      cellColor = Colors.blue.withOpacity(0.4);
    } else {
      cellColor = Colors.grey.withOpacity(0.2);
    }

    return GestureDetector(
      onTap: () {
        // TODO: Show day details
      },
      child: Container(
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.date.day.toString(),
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: hasData ? Colors.white : Colors.black87,
              ),
            ),
            if (hasData) ...[
              const SizedBox(height: 2),
              Text(
                day.totalCount.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysMeals(BuildContext context) {
    // TODO: Get today's meals from provider
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Meals',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          // TODO: Replace with actual meal logs
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No meals logged yet today'),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<EatingTimeline> _generateMockTimeline() {
    // Generate 30 days of mock data
    final timeline = <EatingTimeline>[];
    final now = DateTime.now();

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final mealCount = i % 3; // Mock data
      final snackCount = i % 2;

      timeline.add(EatingTimeline(
        date: date,
        mealCount: mealCount,
        snackCount: snackCount,
        totalCount: mealCount + snackCount,
        metGoals: mealCount >= 3,
        streak: i < 5 ? 5 - i : null, // Mock streak
      ));
    }

    return timeline;
  }
}
