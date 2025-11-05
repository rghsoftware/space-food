/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/utils/responsive_builder.dart';
import '../../data/models/meal_plan.dart';
import '../widgets/tablet_split_view.dart';

/// Tablet-optimized meal planning view with calendar and details
class TabletMealPlanningView extends HookConsumerWidget {
  const TabletMealPlanningView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveBuilder(
      builder: (context, info) {
        if (info.isTablet && info.isLandscape) {
          return _buildTabletLandscapeView(context, ref, info);
        } else {
          return _buildMobileView(context, ref, info);
        }
      },
    );
  }

  Widget _buildTabletLandscapeView(
    BuildContext context,
    WidgetRef ref,
    ResponsiveInfo info,
  ) {
    return TabletSplitView(
      leftFlex: 3,
      rightFlex: 2,
      leftPanel: _buildCalendarPanel(context, ref, info),
      rightPanel: _buildMealDetailsPanel(context, ref, info),
    );
  }

  Widget _buildMobileView(
    BuildContext context,
    WidgetRef ref,
    ResponsiveInfo info,
  ) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: _buildCalendarPanel(context, ref, info),
        ),
        Expanded(
          flex: 1,
          child: _buildMealDetailsPanel(context, ref, info),
        ),
      ],
    );
  }

  Widget _buildCalendarPanel(
    BuildContext context,
    WidgetRef ref,
    ResponsiveInfo info,
  ) {
    final focusedDay = DateTime.now();
    final selectedDay = DateTime.now();

    return Container(
      padding: info.standardPadding,
      child: Column(
        children: [
          // Calendar header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Meal Calendar',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.today),
                    tooltip: 'Today',
                    onPressed: () {
                      // TODO: Navigate to today
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Add Meal',
                    onPressed: () {
                      // TODO: Add meal dialog
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Calendar widget
          Expanded(
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: focusedDay,
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle:
                    Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ) ??
                        const TextStyle(),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                // TODO: Handle day selection
              },
              eventLoader: (day) {
                // TODO: Return list of meals for this day
                return [];
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealDetailsPanel(
    BuildContext context,
    WidgetRef ref,
    ResponsiveInfo info,
  ) {
    return Container(
      padding: info.standardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Meals',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Add meal for selected day
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Meal'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildMealsList(context, ref, info),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList(
    BuildContext context,
    WidgetRef ref,
    ResponsiveInfo info,
  ) {
    // TODO: Get meals from provider
    final meals = <Map<String, dynamic>>[];

    if (meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No meals planned for this day',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                // TODO: Add meal
              },
              icon: const Icon(Icons.add),
              label: const Text('Add First Meal'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return _buildMealCard(context, meal);
      },
    );
  }

  Widget _buildMealCard(BuildContext context, Map<String, dynamic> meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMealTypeColor(context, meal['type'] as String?),
          child: Icon(
            _getMealTypeIcon(meal['type'] as String?),
            color: Colors.white,
          ),
        ),
        title: Text(meal['recipeName'] as String? ?? 'Unknown'),
        subtitle: Text(meal['type'] as String? ?? 'Meal'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Edit meal
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // TODO: Delete meal
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getMealTypeColor(BuildContext context, String? mealType) {
    switch (mealType?.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.blue;
      case 'snack':
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getMealTypeIcon(String? mealType) {
    switch (mealType?.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }
}
