/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/utils/responsive_builder.dart';
import '../../core/constants/touch_targets.dart';
import '../../core/services/kitchen_mode_service.dart';
import '../../core/services/kitchen_timer_service.dart';
import '../../data/models/recipe.dart';
import '../providers/kitchen_mode_provider.dart';

class KitchenRecipeView extends HookConsumerWidget {
  final Recipe recipe;

  const KitchenRecipeView({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kitchenModeState = ref.watch(kitchenModeStateProvider);
    final kitchenModeNotifier = ref.read(kitchenModeStateProvider.notifier);
    final activeTimersAsync = ref.watch(activeTimersProvider);

    // Parse instructions into steps
    final steps = recipe.instructions
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    return ResponsiveBuilder(
      isKitchenMode: true,
      builder: (context, info) {
        if (info.isTablet && info.isLandscape) {
          // Tablet landscape: Split view (ingredients | instructions)
          return _buildSplitView(
            context,
            info,
            kitchenModeState,
            kitchenModeNotifier,
            steps,
            activeTimersAsync,
          );
        } else {
          // Mobile/portrait: Single column view
          return _buildSingleView(
            context,
            info,
            kitchenModeState,
            kitchenModeNotifier,
            steps,
            activeTimersAsync,
          );
        }
      },
    );
  }

  Widget _buildSplitView(
    BuildContext context,
    ResponsiveInfo info,
    kitchenModeState,
    kitchenModeNotifier,
    List<String> steps,
    AsyncValue activeTimersAsync,
  ) {
    return Scaffold(
      appBar: _buildKitchenAppBar(context, info, kitchenModeNotifier),
      body: Row(
        children: [
          // Left panel: Ingredients (40% width)
          Expanded(
            flex: 2,
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              padding: EdgeInsets.all(info.standardPadding.left),
              child: _buildIngredientsPanel(context, info),
            ),
          ),
          // Divider
          VerticalDivider(
            width: 1,
            color: Theme.of(context).dividerColor,
          ),
          // Right panel: Instructions (60% width)
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.all(info.standardPadding.left),
              child: _buildInstructionsPanel(
                context,
                info,
                kitchenModeState,
                kitchenModeNotifier,
                steps,
                activeTimersAsync,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleView(
    BuildContext context,
    ResponsiveInfo info,
    kitchenModeState,
    kitchenModeNotifier,
    List<String> steps,
    AsyncValue activeTimersAsync,
  ) {
    return Scaffold(
      appBar: _buildKitchenAppBar(context, info, kitchenModeNotifier),
      body: PageView(
        children: [
          // Page 1: Ingredients
          Container(
            padding: info.standardPadding,
            child: _buildIngredientsPanel(context, info),
          ),
          // Page 2: Instructions
          Container(
            padding: info.standardPadding,
            child: _buildInstructionsPanel(
              context,
              info,
              kitchenModeState,
              kitchenModeNotifier,
              steps,
              activeTimersAsync,
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildKitchenAppBar(
    BuildContext context,
    ResponsiveInfo info,
    kitchenModeNotifier,
  ) {
    return AppBar(
      title: Text(
        recipe.title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      actions: [
        // Brightness control
        IconButton(
          icon: const Icon(Icons.brightness_6, size: 32),
          iconSize: TouchTargets.kitchenStandard,
          onPressed: () => _showBrightnessDialog(context, kitchenModeNotifier),
        ),
        // Exit kitchen mode
        IconButton(
          icon: const Icon(Icons.close, size: 32),
          iconSize: TouchTargets.kitchenStandard,
          onPressed: () async {
            await kitchenModeNotifier.disableKitchenMode();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }

  Widget _buildIngredientsPanel(BuildContext context, ResponsiveInfo info) {
    return ListView(
      children: [
        Text(
          'Ingredients',
          style: TextStyle(
            fontSize: info.isKitchenMode ? 32 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        ...recipe.ingredients.map((ingredient) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 10, right: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${ingredient.quantity} ${ingredient.unit} ${ingredient.name}',
                    style: TextStyle(fontSize: info.isKitchenMode ? 24 : 18),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInstructionsPanel(
    BuildContext context,
    ResponsiveInfo info,
    kitchenModeState,
    kitchenModeNotifier,
    List<String> steps,
    AsyncValue activeTimersAsync,
  ) {
    final currentStep = kitchenModeState.currentStep ?? 0;

    return Column(
      children: [
        // Active timers section
        activeTimersAsync.when(
          data: (timers) {
            if (timers.isEmpty) return const SizedBox.shrink();
            return _buildActiveTimersSection(
              context,
              info,
              timers,
              kitchenModeNotifier,
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Current step display
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Step ${currentStep + 1} of ${steps.length}',
                    style: TextStyle(
                      fontSize: info.isKitchenMode ? 28 : 20,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    steps[currentStep],
                    style: TextStyle(fontSize: info.isKitchenMode ? 32 : 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Quick timer buttons
                  _buildQuickTimerButtons(
                    context,
                    info,
                    kitchenModeNotifier,
                    currentStep,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Navigation buttons
        const SizedBox(height: 24),
        _buildNavigationButtons(
          context,
          info,
          kitchenModeNotifier,
          currentStep,
          steps.length,
        ),
      ],
    );
  }

  Widget _buildActiveTimersSection(
    BuildContext context,
    ResponsiveInfo info,
    List timers,
    kitchenModeNotifier,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Timers',
            style: TextStyle(
              fontSize: info.isKitchenMode ? 24 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...timers.map((timer) => _buildTimerCard(
                context,
                info,
                timer,
                kitchenModeNotifier,
              )),
        ],
      ),
    );
  }

  Widget _buildTimerCard(
    BuildContext context,
    ResponsiveInfo info,
    timer,
    kitchenModeNotifier,
  ) {
    final isExpiringSoon = timer.isExpiringSoon;
    final isExpired = timer.isExpired;

    return Card(
      color: isExpired
          ? Theme.of(context).colorScheme.error
          : isExpiringSoon
              ? Theme.of(context).colorScheme.errorContainer
              : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timer.label,
                    style: TextStyle(
                      fontSize: info.isKitchenMode ? 20 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timer.formattedTime,
                    style: TextStyle(
                      fontSize: info.isKitchenMode ? 36 : 28,
                      fontWeight: FontWeight.bold,
                      color: isExpired
                          ? Theme.of(context).colorScheme.onError
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: timer.progress,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    timer.isRunning ? Icons.pause : Icons.play_arrow,
                    size: TouchTargets.kitchenStandard,
                  ),
                  onPressed: () {
                    if (timer.isRunning) {
                      kitchenModeNotifier.pauseTimer(timer.id);
                    } else {
                      kitchenModeNotifier.resumeTimer(timer.id);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: TouchTargets.kitchenStandard,
                  ),
                  onPressed: () => kitchenModeNotifier.cancelTimer(timer.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTimerButtons(
    BuildContext context,
    ResponsiveInfo info,
    kitchenModeNotifier,
    int currentStep,
  ) {
    final commonTimers = [
      {'label': '5 min', 'seconds': 300},
      {'label': '10 min', 'seconds': 600},
      {'label': '15 min', 'seconds': 900},
      {'label': '30 min', 'seconds': 1800},
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: commonTimers.map((timerData) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: Size(
              TouchTargets.kitchenStandard,
              TouchTargets.kitchenStandard,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          onPressed: () {
            final timerId = kitchenModeNotifier.createTimer(
              'Step ${currentStep + 1}: ${timerData['label']}',
              timerData['seconds'] as int,
            );
            kitchenModeNotifier.startTimer(timerId);
          },
          child: Text(
            timerData['label'] as String,
            style: TextStyle(fontSize: info.isKitchenMode ? 24 : 18),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    ResponsiveInfo info,
    kitchenModeNotifier,
    int currentStep,
    int totalSteps,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(
                double.infinity,
                TouchTargets.kitchenLarge,
              ),
            ),
            onPressed: currentStep > 0
                ? () => kitchenModeNotifier.previousStep()
                : null,
            icon: Icon(Icons.arrow_back, size: info.isKitchenMode ? 32 : 24),
            label: Text(
              'Previous',
              style: TextStyle(fontSize: info.isKitchenMode ? 24 : 18),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(
                double.infinity,
                TouchTargets.kitchenLarge,
              ),
            ),
            onPressed: currentStep < totalSteps - 1
                ? () => kitchenModeNotifier.nextStep(totalSteps)
                : null,
            icon: Icon(Icons.arrow_forward, size: info.isKitchenMode ? 32 : 24),
            label: Text(
              'Next',
              style: TextStyle(fontSize: info.isKitchenMode ? 24 : 18),
            ),
          ),
        ),
      ],
    );
  }

  void _showBrightnessDialog(BuildContext context, kitchenModeNotifier) {
    showDialog(
      context: context,
      builder: (context) => _BrightnessDialog(
        notifier: kitchenModeNotifier,
      ),
    );
  }
}

class _BrightnessDialog extends HookConsumerWidget {
  final dynamic notifier;

  const _BrightnessDialog({required this.notifier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kitchenModeState = ref.watch(kitchenModeStateProvider);
    final brightness = useState(kitchenModeState.brightness);

    return AlertDialog(
      title: const Text('Screen Brightness'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${(brightness.value * 100).round()}%'),
          Slider(
            value: brightness.value,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            label: '${(brightness.value * 100).round()}%',
            onChanged: (value) {
              brightness.value = value;
              notifier.updateBrightness(value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
