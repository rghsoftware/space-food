# Phase 2: Mobile & Tablet Experience Enhancements

**Version:** 1.0  
**Prerequisites:** Complete Phase 1 implementation (Weeks 1-20)  
**Target Audience:** Claude Code / AI Agents  
**Estimated Timeline:** 6-8 weeks

---

## Overview

This document outlines enhancements to transform the meal planning app into a kitchen-optimized experience with tablet-friendly layouts, robust offline capabilities, and cooking-focused features. These improvements build on the core implementation to create a best-in-class mobile cooking companion.

### Enhancement Goals

1. **Kitchen-Optimized UI** - Large touch targets, readable from distance, splatter-resistant design
2. **Tablet Layouts** - Multi-pane views that leverage larger screens
3. **Cooking Mode** - Hands-free, step-by-step recipe guidance with timers
4. **Explicit Offline Support** - Clear UX for offline/online states
5. **Mobile-First Interactions** - Gestures, haptics, and device-native features

---

## Responsive Design System

### Breakpoint Strategy

```dart
// lib/src/core/constants/breakpoints.dart

class Breakpoints {
  // Mobile breakpoints
  static const double mobileSmall = 320;  // iPhone SE
  static const double mobileMedium = 375; // iPhone 12/13/14
  static const double mobileLarge = 414;  // iPhone Pro Max
  
  // Tablet breakpoints
  static const double tabletSmall = 600;  // 7" tablets (portrait)
  static const double tabletMedium = 768; // 10" tablets (portrait) / iPad
  static const double tabletLarge = 1024; // 12" tablets (landscape) / iPad Pro
  
  // Desktop breakpoints
  static const double desktopSmall = 1280;
  static const double desktopMedium = 1440;
  static const double desktopLarge = 1920;
  
  // Kitchen display mode (optimized for counter/wall mount)
  static const double kitchenDisplay = 800; // Minimum for kitchen mode
}

enum DeviceType {
  mobileSmall,
  mobileMedium,
  mobileLarge,
  tabletSmall,
  tabletMedium,
  tabletLarge,
  desktop;
  
  static DeviceType fromWidth(double width) {
    if (width < Breakpoints.mobileMedium) return DeviceType.mobileSmall;
    if (width < Breakpoints.mobileLarge) return DeviceType.mobileMedium;
    if (width < Breakpoints.tabletSmall) return DeviceType.mobileLarge;
    if (width < Breakpoints.tabletMedium) return DeviceType.tabletSmall;
    if (width < Breakpoints.tabletLarge) return DeviceType.tabletMedium;
    if (width < Breakpoints.desktopSmall) return DeviceType.tabletLarge;
    return DeviceType.desktop;
  }
  
  bool get isTablet => [
    DeviceType.tabletSmall,
    DeviceType.tabletMedium,
    DeviceType.tabletLarge,
  ].contains(this);
  
  bool get isMobile => !isTablet && this != DeviceType.desktop;
}
```

### Responsive Layout Builder

```dart
// lib/src/core/utils/responsive_builder.dart

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, DeviceType) builder;
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    Key? key,
    required this.builder,
  })  : mobile = null,
        tablet = null,
        desktop = null,
        super(key: key);

  const ResponsiveBuilder.adaptive({
    Key? key,
    this.mobile,
    this.tablet,
    this.desktop,
  })  : builder = _defaultBuilder,
        super(key: key);

  static Widget _defaultBuilder(BuildContext context, DeviceType deviceType) {
    throw UnimplementedError('Use adaptive constructor or provide builder');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final deviceType = DeviceType.fromWidth(width);

    if (mobile != null || tablet != null || desktop != null) {
      if (deviceType.isMobile && mobile != null) return mobile!;
      if (deviceType.isTablet && tablet != null) return tablet!;
      if (deviceType == DeviceType.desktop && desktop != null) return desktop!;
      
      // Fallback logic
      return tablet ?? mobile ?? desktop ?? const SizedBox.shrink();
    }

    return builder(context, deviceType);
  }
}
```

### Typography Scale for Different Screen Sizes

```dart
// lib/src/core/theme/responsive_typography.dart

class ResponsiveTypography {
  static TextTheme getTextTheme(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobileSmall:
      case DeviceType.mobileMedium:
        return _mobileTextTheme;
      
      case DeviceType.mobileLarge:
      case DeviceType.tabletSmall:
        return _tabletSmallTextTheme;
      
      case DeviceType.tabletMedium:
      case DeviceType.tabletLarge:
        return _tabletLargeTextTheme;
      
      case DeviceType.desktop:
        return _desktopTextTheme;
    }
  }
  
  // Mobile: Comfortable for handheld reading
  static final _mobileTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
  );
  
  // Tablet: Larger text readable from counter distance (2-3 feet)
  static final _tabletLargeTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
    bodySmall: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
  );
  
  // Kitchen display mode: Extra large for wall-mounted tablets
  static final kitchenDisplayTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(fontSize: 52, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
    titleMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.normal),
    bodySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
  );
}
```

### Touch Target Sizing

```dart
// lib/src/core/constants/touch_targets.dart

class TouchTargets {
  // Minimum touch target sizes (accessibility guidelines)
  static const double minimumMobile = 44.0;    // iOS HIG recommendation
  static const double minimumAndroid = 48.0;   // Material Design recommendation
  
  // Kitchen mode: larger targets for messy hands
  static const double kitchenSmall = 56.0;
  static const double kitchenMedium = 72.0;
  static const double kitchenLarge = 96.0;
  
  // Spacing between interactive elements
  static const double minimumSpacing = 8.0;
  static const double kitchenSpacing = 16.0;
  
  static double getMinimumSize(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS 
        ? minimumMobile 
        : minimumAndroid;
  }
  
  static double getKitchenSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return kitchenSmall;
      case ButtonSize.medium:
        return kitchenMedium;
      case ButtonSize.large:
        return kitchenLarge;
    }
  }
}

enum ButtonSize { small, medium, large }
```

---

## Kitchen Display Mode

### Kitchen Mode State Management

```dart
// lib/src/features/kitchen_mode/presentation/providers/kitchen_mode_provider.dart

@riverpod
class KitchenMode extends _$KitchenMode {
  @override
  KitchenModeState build() {
    return const KitchenModeState(
      isEnabled: false,
      brightness: 1.0,
      keepAwake: false,
      handsFreeMode: false,
      textScale: 1.0,
    );
  }
  
  void toggleKitchenMode() {
    if (state.isEnabled) {
      _disableKitchenMode();
    } else {
      _enableKitchenMode();
    }
  }
  
  Future<void> _enableKitchenMode() async {
    // Keep screen awake
    await WakelockPlus.enable();
    
    // Set max brightness
    await ScreenBrightness().setScreenBrightness(1.0);
    
    // Enable orientation lock to landscape (for tablets)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    state = state.copyWith(
      isEnabled: true,
      keepAwake: true,
      brightness: 1.0,
      textScale: 1.2, // Slightly larger text
    );
  }
  
  Future<void> _disableKitchenMode() async {
    // Release screen wake lock
    await WakelockPlus.disable();
    
    // Reset brightness to system default
    await ScreenBrightness().resetScreenBrightness();
    
    // Allow all orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    state = state.copyWith(
      isEnabled: false,
      keepAwake: false,
      textScale: 1.0,
    );
  }
  
  void toggleHandsFreeMode() {
    state = state.copyWith(handsFreeMode: !state.handsFreeMode);
  }
  
  void adjustTextScale(double scale) {
    state = state.copyWith(textScale: scale.clamp(1.0, 2.0));
  }
}

@freezed
class KitchenModeState with _$KitchenModeState {
  const factory KitchenModeState({
    required bool isEnabled,
    required double brightness,
    required bool keepAwake,
    required bool handsFreeMode,
    required double textScale,
  }) = _KitchenModeState;
}
```

### Kitchen Mode Recipe View

```dart
// lib/src/features/recipes/presentation/pages/kitchen_recipe_view.dart

class KitchenRecipeView extends ConsumerStatefulWidget {
  final Recipe recipe;
  
  const KitchenRecipeView({Key? key, required this.recipe}) : super(key: key);
  
  @override
  ConsumerState<KitchenRecipeView> createState() => _KitchenRecipeViewState();
}

class _KitchenRecipeViewState extends ConsumerState<KitchenRecipeView> {
  int _currentStep = 0;
  final List<Timer?> _activeTimers = [];
  
  @override
  Widget build(BuildContext context) {
    final kitchenMode = ref.watch(kitchenModeProvider);
    final deviceType = DeviceType.fromWidth(MediaQuery.of(context).size.width);
    
    return Scaffold(
      backgroundColor: Colors.white, // High contrast for kitchen
      body: SafeArea(
        child: deviceType.isTablet
            ? _buildTabletLayout()
            : _buildMobileLayout(),
      ),
    );
  }
  
  Widget _buildTabletLayout() {
    // Split screen: ingredients on left, instructions on right
    return Row(
      children: [
        // Ingredients panel (1/3 width)
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(24),
            child: _buildIngredientsPanel(),
          ),
        ),
        
        // Instructions panel (2/3 width)
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(32),
            child: _buildInstructionsPanel(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMobileLayout() {
    return PageView(
      children: [
        _buildIngredientsPanel(),
        _buildInstructionsPanel(),
      ],
    );
  }
  
  Widget _buildIngredientsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredients',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        
        Expanded(
          child: ListView.builder(
            itemCount: widget.recipe.ingredients.length,
            itemBuilder: (context, index) {
              final ingredient = widget.recipe.ingredients[index];
              return _IngredientCheckItem(ingredient: ingredient);
            },
          ),
        ),
        
        // Servings adjuster
        _buildServingsAdjuster(),
      ],
    );
  }
  
  Widget _buildInstructionsPanel() {
    final instruction = widget.recipe.instructions[_currentStep];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${_currentStep + 1} of ${widget.recipe.instructions.length}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            _buildTimerButton(instruction),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Current instruction
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              instruction.text,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                height: 1.6,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Navigation buttons
        _buildNavigationButtons(),
        
        // Active timers display
        if (_activeTimers.isNotEmpty) _buildActiveTimers(),
      ],
    );
  }
  
  Widget _buildNavigationButtons() {
    return Row(
      children: [
        // Previous button
        Expanded(
          child: ElevatedButton(
            onPressed: _currentStep > 0 ? _previousStep : null,
            style: ElevatedButton.styleFrom(
              minimumSize: Size.fromHeight(TouchTargets.kitchenLarge),
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back, size: 32),
                const SizedBox(width: 8),
                Text('Previous', style: TextStyle(fontSize: 20)),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Next button
        Expanded(
          child: ElevatedButton(
            onPressed: _currentStep < widget.recipe.instructions.length - 1
                ? _nextStep
                : _completeRecipe,
            style: ElevatedButton.styleFrom(
              minimumSize: Size.fromHeight(TouchTargets.kitchenLarge),
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentStep < widget.recipe.instructions.length - 1
                      ? 'Next'
                      : 'Complete',
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTimerButton(Instruction instruction) {
    // Parse instruction for time mentions (e.g., "30 minutes", "2 hours")
    final timeMatch = _extractTimeFromText(instruction.text);
    
    if (timeMatch == null) return const SizedBox.shrink();
    
    return ElevatedButton.icon(
      onPressed: () => _startTimer(timeMatch),
      icon: Icon(Icons.timer, size: 28),
      label: Text('Set ${timeMatch.display}', style: TextStyle(fontSize: 18)),
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(TouchTargets.kitchenMedium),
        backgroundColor: Colors.orange,
      ),
    );
  }
  
  void _previousStep() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentStep = (_currentStep - 1).clamp(0, widget.recipe.instructions.length - 1);
    });
  }
  
  void _nextStep() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentStep = (_currentStep + 1).clamp(0, widget.recipe.instructions.length - 1);
    });
  }
  
  void _completeRecipe() {
    HapticFeedback.mediumImpact();
    // Mark recipe as completed, show rating dialog, etc.
    showDialog(
      context: context,
      builder: (context) => RecipeCompletionDialog(recipe: widget.recipe),
    );
  }
  
  void _startTimer(TimeDuration duration) {
    HapticFeedback.mediumImpact();
    
    // Navigate to timer screen or show timer overlay
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => KitchenTimerScreen(
          duration: duration,
          stepName: widget.recipe.instructions[_currentStep].text,
        ),
      ),
    );
  }
  
  TimeDuration? _extractTimeFromText(String text) {
    // Simple regex to find time mentions
    final patterns = [
      RegExp(r'(\d+)\s*minutes?', caseSensitive: false),
      RegExp(r'(\d+)\s*hours?', caseSensitive: false),
      RegExp(r'(\d+)\s*seconds?', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final value = int.parse(match.group(1)!);
        if (pattern.pattern.contains('minute')) {
          return TimeDuration(minutes: value);
        } else if (pattern.pattern.contains('hour')) {
          return TimeDuration(hours: value);
        } else if (pattern.pattern.contains('second')) {
          return TimeDuration(seconds: value);
        }
      }
    }
    
    return null;
  }
}

class _IngredientCheckItem extends StatefulWidget {
  final Ingredient ingredient;
  
  const _IngredientCheckItem({required this.ingredient});
  
  @override
  State<_IngredientCheckItem> createState() => _IngredientCheckItemState();
}

class _IngredientCheckItemState extends State<_IngredientCheckItem> {
  bool _isChecked = false;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _isChecked = !_isChecked;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isChecked ? Colors.green[50] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isChecked ? Colors.green : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: TouchTargets.kitchenSmall,
                height: TouchTargets.kitchenSmall,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isChecked ? Colors.green : Colors.white,
                  border: Border.all(
                    color: _isChecked ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                ),
                child: _isChecked
                    ? Icon(Icons.check, color: Colors.white, size: 28)
                    : null,
              ),
              
              const SizedBox(width: 16),
              
              // Ingredient info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.ingredient.quantity} ${widget.ingredient.unit}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                        decoration: _isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.ingredient.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        decoration: _isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Kitchen Timer Implementation

```dart
// lib/src/features/kitchen_mode/presentation/pages/kitchen_timer_screen.dart

class KitchenTimerScreen extends ConsumerStatefulWidget {
  final TimeDuration duration;
  final String stepName;
  
  const KitchenTimerScreen({
    Key? key,
    required this.duration,
    required this.stepName,
  }) : super(key: key);
  
  @override
  ConsumerState<KitchenTimerScreen> createState() => _KitchenTimerScreenState();
}

class _KitchenTimerScreenState extends ConsumerState<KitchenTimerScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Duration _remainingTime;
  bool _isRunning = false;
  bool _isPaused = false;
  
  @override
  void initState() {
    super.initState();
    _remainingTime = Duration(
      hours: widget.duration.hours,
      minutes: widget.duration.minutes,
      seconds: widget.duration.seconds,
    );
    
    _controller = AnimationController(
      vsync: this,
      duration: _remainingTime,
    );
    
    _controller.addListener(() {
      setState(() {
        _remainingTime = _controller.duration! * (1 - _controller.value);
      });
      
      if (_controller.isCompleted) {
        _onTimerComplete();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Step name
              Text(
                widget.stepName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 48),
              
              // Circular timer
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress circle
                        SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: CircularProgressIndicator(
                            value: 1 - _controller.value,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _remainingTime.inSeconds < 60
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ),
                        
                        // Time display
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(_remainingTime),
                              style: TextStyle(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isRunning
                                  ? (_isPaused ? 'Paused' : 'Running')
                                  : 'Ready',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Control buttons
              _buildControlButtons(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildControlButtons() {
    if (!_isRunning) {
      // Start button
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _startTimer,
          style: ElevatedButton.styleFrom(
            minimumSize: Size.fromHeight(TouchTargets.kitchenLarge),
            backgroundColor: Colors.green,
          ),
          child: Text(
            'START',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    
    return Row(
      children: [
        // Pause/Resume button
        Expanded(
          child: ElevatedButton(
            onPressed: _isPaused ? _resumeTimer : _pauseTimer,
            style: ElevatedButton.styleFrom(
              minimumSize: Size.fromHeight(TouchTargets.kitchenLarge),
              backgroundColor: Colors.orange,
            ),
            child: Icon(
              _isPaused ? Icons.play_arrow : Icons.pause,
              size: 48,
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Stop button
        Expanded(
          child: ElevatedButton(
            onPressed: _stopTimer,
            style: ElevatedButton.styleFrom(
              minimumSize: Size.fromHeight(TouchTargets.kitchenLarge),
              backgroundColor: Colors.red,
            ),
            child: Icon(Icons.stop, size: 48),
          ),
        ),
      ],
    );
  }
  
  void _startTimer() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _controller.forward();
  }
  
  void _pauseTimer() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPaused = true;
    });
    _controller.stop();
  }
  
  void _resumeTimer() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPaused = false;
    });
    _controller.forward();
  }
  
  void _stopTimer() {
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop();
  }
  
  void _onTimerComplete() {
    HapticFeedback.heavyImpact();
    
    // Vibrate pattern: 3 strong pulses
    HapticFeedback.heavyImpact();
    Future.delayed(Duration(milliseconds: 500), () => HapticFeedback.heavyImpact());
    Future.delayed(Duration(milliseconds: 1000), () => HapticFeedback.heavyImpact());
    
    // Show completion dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Timer Complete!'),
        content: Text(widget.stepName),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close timer screen
            },
            child: Text('OK', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class TimeDuration {
  final int hours;
  final int minutes;
  final int seconds;
  
  const TimeDuration({
    this.hours = 0,
    this.minutes = 0,
    this.seconds = 0,
  });
  
  String get display {
    if (hours > 0) {
      return '$hours hr${hours != 1 ? 's' : ''}';
    } else if (minutes > 0) {
      return '$minutes min';
    } else {
      return '$seconds sec';
    }
  }
}
```

---

## Offline Capabilities Matrix

### Offline Feature Support

```dart
// lib/src/core/offline/offline_capabilities.dart

enum OfflineCapability {
  fullyOffline,      // Works completely offline
  offlineWithCache,  // Works if data previously cached
  requiresSync,      // Needs sync but queues operations
  requiresOnline,    // Must be online
}

class FeatureCapabilities {
  static const Map<String, OfflineCapability> features = {
    // Recipe features
    'view_recipes': OfflineCapability.offlineWithCache,
    'search_recipes_local': OfflineCapability.fullyOffline,
    'create_recipe': OfflineCapability.requiresSync,
    'edit_recipe': OfflineCapability.requiresSync,
    'delete_recipe': OfflineCapability.requiresSync,
    'import_recipe_url': OfflineCapability.requiresOnline,
    'recipe_ai_suggestions': OfflineCapability.requiresOnline,
    
    // Meal planning
    'view_meal_plans': OfflineCapability.offlineWithCache,
    'create_meal_plan': OfflineCapability.requiresSync,
    'edit_meal_plan': OfflineCapability.requiresSync,
    'ai_meal_generation': OfflineCapability.requiresOnline,
    
    // Pantry
    'view_pantry': OfflineCapability.offlineWithCache,
    'add_pantry_item': OfflineCapability.requiresSync,
    'update_pantry_item': OfflineCapability.requiresSync,
    'scan_barcode': OfflineCapability.requiresOnline, // Needs API lookup
    
    // Shopping list
    'view_shopping_list': OfflineCapability.fullyOffline,
    'add_shopping_item': OfflineCapability.fullyOffline,
    'check_off_item': OfflineCapability.fullyOffline,
    'generate_from_meal_plan': OfflineCapability.fullyOffline,
    
    // Nutrition tracking
    'view_nutrition_logs': OfflineCapability.offlineWithCache,
    'log_nutrition': OfflineCapability.requiresSync,
    'nutrition_charts': OfflineCapability.offlineWithCache,
    
    // Kitchen mode
    'kitchen_mode': OfflineCapability.fullyOffline,
    'cooking_timers': OfflineCapability.fullyOffline,
    'step_by_step_cooking': OfflineCapability.offlineWithCache,
  };
  
  static OfflineCapability getCapability(String feature) {
    return features[feature] ?? OfflineCapability.requiresOnline;
  }
  
  static bool isAvailableOffline(String feature, bool isCached) {
    final capability = getCapability(feature);
    
    switch (capability) {
      case OfflineCapability.fullyOffline:
        return true;
      case OfflineCapability.offlineWithCache:
        return isCached;
      case OfflineCapability.requiresSync:
      case OfflineCapability.requiresOnline:
        return false;
    }
  }
}
```

### Offline Status Indicator

```dart
// lib/src/core/widgets/offline_status_bar.dart

class OfflineStatusBar extends ConsumerWidget {
  const OfflineStatusBar({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStatus = ref.watch(connectivityProvider);
    final syncStatus = ref.watch(syncServiceProvider);
    
    if (connectivityStatus.isOnline) {
      // Show sync status when online
      if (syncStatus.isSyncing) {
        return _buildStatusBar(
          context,
          icon: Icons.sync,
          message: 'Syncing changes...',
          color: Colors.blue,
          animated: true,
        );
      } else if (syncStatus.pendingChanges > 0) {
        return _buildStatusBar(
          context,
          icon: Icons.cloud_upload,
          message: '${syncStatus.pendingChanges} changes pending',
          color: Colors.orange,
        );
      }
      return const SizedBox.shrink();
    }
    
    // Offline mode
    return _buildStatusBar(
      context,
      icon: Icons.cloud_off,
      message: 'Offline Mode - Changes will sync when connected',
      color: Colors.grey[700]!,
    );
  }
  
  Widget _buildStatusBar(
    BuildContext context, {
    required IconData icon,
    required String message,
    required Color color,
    bool animated = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          animated
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Offline-Aware Actions

```dart
// lib/src/core/widgets/offline_aware_button.dart

class OfflineAwareButton extends ConsumerWidget {
  final String feature;
  final VoidCallback onPressed;
  final Widget child;
  final bool requiresCachedData;
  final bool isCached;
  
  const OfflineAwareButton({
    Key? key,
    required this.feature,
    required this.onPressed,
    required this.child,
    this.requiresCachedData = false,
    this.isCached = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).isOnline;
    final capability = FeatureCapabilities.getCapability(feature);
    
    final isAvailable = _checkAvailability(isOnline, capability);
    
    return ElevatedButton(
      onPressed: isAvailable ? onPressed : () => _showUnavailableDialog(context),
      child: child,
    );
  }
  
  bool _checkAvailability(bool isOnline, OfflineCapability capability) {
    switch (capability) {
      case OfflineCapability.fullyOffline:
        return true;
      
      case OfflineCapability.offlineWithCache:
        return isCached;
      
      case OfflineCapability.requiresSync:
        return true; // Can queue offline
      
      case OfflineCapability.requiresOnline:
        return isOnline;
    }
  }
  
  void _showUnavailableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Internet Required'),
        content: Text(
          'This feature requires an internet connection. '
          'Please connect to Wi-Fi or mobile data to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

### Graceful Degradation Strategy

```dart
// lib/src/core/offline/offline_fallback.dart

class OfflineFallback {
  // Recipe image fallback
  static ImageProvider getRecipeImage(Recipe recipe, bool isOnline) {
    if (recipe.localImagePath != null) {
      return FileImage(File(recipe.localImagePath!));
    }
    
    if (recipe.cachedImagePath != null) {
      return FileImage(File(recipe.cachedImagePath!));
    }
    
    if (isOnline && recipe.imageUrl != null) {
      return CachedNetworkImageProvider(recipe.imageUrl!);
    }
    
    return AssetImage('assets/images/recipe_placeholder.png');
  }
  
  // AI feature fallback
  static Future<String> getRecipeSuggestion({
    required Recipe recipe,
    required bool isOnline,
    required AIProvider? aiProvider,
  }) async {
    if (isOnline && aiProvider != null) {
      try {
        return await aiProvider.getRecipeSuggestion(recipe);
      } catch (e) {
        // Fall back to template-based suggestion
        return _getTemplateSuggestion(recipe);
      }
    }
    
    return _getTemplateSuggestion(recipe);
  }
  
  static String _getTemplateSuggestion(Recipe recipe) {
    // Simple template-based suggestions when AI unavailable
    final suggestions = [
      'Try substituting ${recipe.ingredients.first.name} with a seasonal alternative',
      'This recipe pairs well with a simple green salad',
      'Consider doubling this recipe for meal prep',
    ];
    
    return suggestions[Random().nextInt(suggestions.length)];
  }
  
  // Nutrition data fallback
  static NutritionInfo? getNutritionInfo({
    required Recipe recipe,
    required bool isOnline,
  }) {
    // Check local cache first
    if (recipe.nutritionInfo != null) {
      return recipe.nutritionInfo;
    }
    
    // If offline, show estimated values with disclaimer
    if (!isOnline) {
      return NutritionInfo.estimated(
        calories: _estimateCalories(recipe),
        showDisclaimer: true,
      );
    }
    
    return null;
  }
  
  static int _estimateCalories(Recipe recipe) {
    // Very rough estimation based on ingredient count
    // In reality, would use more sophisticated logic
    return recipe.ingredients.length * 100;
  }
}
```

---

## Mobile-Specific Features

### Gesture Navigation

```dart
// lib/src/core/widgets/swipeable_recipe_card.dart

class SwipeableRecipeCard extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback? onSwipeLeft;  // e.g., Add to shopping list
  final VoidCallback? onSwipeRight; // e.g., Add to meal plan
  final VoidCallback? onTap;
  
  const SwipeableRecipeCard({
    Key? key,
    required this.recipe,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onTap,
  }) : super(key: key);
  
  @override
  State<SwipeableRecipeCard> createState() => _SwipeableRecipeCardState();
}

class _SwipeableRecipeCardState extends State<SwipeableRecipeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  double _dragExtent = 0;
  
  static const double _dismissThreshold = 100.0;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_controller);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      onTap: widget.onTap,
      child: Stack(
        children: [
          // Background actions
          _buildSwipeActions(),
          
          // Card content
          SlideTransition(
            position: _slideAnimation,
            child: RecipeCard(recipe: widget.recipe),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSwipeActions() {
    return Positioned.fill(
      child: Row(
        children: [
          // Left swipe action (shopping list)
          Expanded(
            child: Container(
              color: Colors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart, color: Colors.white, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    'Shopping List',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          
          // Right swipe action (meal plan)
          Expanded(
            child: Container(
              color: Colors.blue,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, color: Colors.white, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    'Meal Plan',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta!;
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(_dragExtent / context.size!.width, 0),
      ).animate(_controller);
    });
  }
  
  void _handleDragEnd(DragEndDetails details) {
    if (_dragExtent.abs() >= _dismissThreshold) {
      HapticFeedback.mediumImpact();
      
      if (_dragExtent > 0 && widget.onSwipeRight != null) {
        widget.onSwipeRight!();
      } else if (_dragExtent < 0 && widget.onSwipeLeft != null) {
        widget.onSwipeLeft!();
      }
    }
    
    // Reset position
    setState(() {
      _dragExtent = 0;
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset.zero,
      ).animate(_controller);
    });
  }
}
```

### Haptic Feedback Strategy

```dart
// lib/src/core/utils/haptic_feedback_helper.dart

class HapticFeedbackHelper {
  // Light impact for selections, toggles
  static void light() {
    HapticFeedback.lightImpact();
  }
  
  // Medium impact for button presses, navigation
  static void medium() {
    HapticFeedback.mediumImpact();
  }
  
  // Heavy impact for important actions, completions
  static void heavy() {
    HapticFeedback.heavyImpact();
  }
  
  // Selection feedback for pickers
  static void selection() {
    HapticFeedback.selectionClick();
  }
  
  // Success pattern (3 light vibrations)
  static void success() {
    HapticFeedback.lightImpact();
    Future.delayed(Duration(milliseconds: 100), () {
      HapticFeedback.lightImpact();
      Future.delayed(Duration(milliseconds: 100), () {
        HapticFeedback.lightImpact();
      });
    });
  }
  
  // Error pattern (2 heavy vibrations)
  static void error() {
    HapticFeedback.heavyImpact();
    Future.delayed(Duration(milliseconds: 200), () {
      HapticFeedback.heavyImpact();
    });
  }
  
  // Warning pattern (medium then heavy)
  static void warning() {
    HapticFeedback.mediumImpact();
    Future.delayed(Duration(milliseconds: 150), () {
      HapticFeedback.heavyImpact();
    });
  }
}

// Usage in widgets
class ExampleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        HapticFeedbackHelper.medium();
        // Handle button press
      },
      child: Text('Press Me'),
    );
  }
}
```

### Screen Wake Lock Management

```dart
// lib/src/core/services/screen_management_service.dart

@riverpod
class ScreenManagementService extends _$ScreenManagementService {
  @override
  FutureOr<ScreenManagementState> build() async {
    return ScreenManagementState(
      isWakeLockEnabled: false,
      brightness: await ScreenBrightness().current,
    );
  }
  
  Future<void> enableWakeLock() async {
    try {
      await WakelockPlus.enable();
      state = AsyncData(state.value!.copyWith(isWakeLockEnabled: true));
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> disableWakeLock() async {
    try {
      await WakelockPlus.disable();
      state = AsyncData(state.value!.copyWith(isWakeLockEnabled: false));
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> setBrightness(double brightness) async {
    try {
      await ScreenBrightness().setScreenBrightness(brightness);
      state = AsyncData(state.value!.copyWith(brightness: brightness));
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> resetBrightness() async {
    try {
      await ScreenBrightness().resetScreenBrightness();
      final currentBrightness = await ScreenBrightness().current;
      state = AsyncData(state.value!.copyWith(brightness: currentBrightness));
    } catch (e) {
      // Handle error
    }
  }
}

@freezed
class ScreenManagementState with _$ScreenManagementState {
  const factory ScreenManagementState({
    required bool isWakeLockEnabled,
    required double brightness,
  }) = _ScreenManagementState;
}
```

### Pull-to-Refresh Implementation

```dart
// lib/src/core/widgets/refreshable_list.dart

class RefreshableList<T> extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final Widget? emptyWidget;
  
  const RefreshableList({
    Key? key,
    required this.onRefresh,
    required this.items,
    required this.itemBuilder,
    this.emptyWidget,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && emptyWidget != null) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: emptyWidget,
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedbackHelper.light();
        await onRefresh();
        HapticFeedbackHelper.success();
      },
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return itemBuilder(context, items[index]);
        },
      ),
    );
  }
}
```

---

## Tablet-Specific Layouts

### Recipe Detail Split View

```dart
// lib/src/features/recipes/presentation/pages/recipe_detail_page.dart

class RecipeDetailPage extends ConsumerWidget {
  final Recipe recipe;
  
  const RecipeDetailPage({Key? key, required this.recipe}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceType = DeviceType.fromWidth(MediaQuery.of(context).size.width);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
        actions: [
          IconButton(
            icon: Icon(Icons.kitchen),
            onPressed: () => _enterKitchenMode(context),
            tooltip: 'Kitchen Mode',
          ),
        ],
      ),
      body: deviceType.isTablet
          ? _buildTabletLayout(context)
          : _buildMobileLayout(context),
    );
  }
  
  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel: Recipe info and ingredients
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipe image
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: recipe.imageUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Recipe metadata
                _buildMetadataRow(context),
                
                const SizedBox(height: 32),
                
                // Ingredients section
                Text(
                  'Ingredients',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                _buildIngredientsList(context),
                
                const SizedBox(height: 32),
                
                // Nutrition info
                if (recipe.nutritionInfo != null) ...[
                  Text(
                    'Nutrition',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildNutritionCard(context),
                ],
              ],
            ),
          ),
        ),
        
        // Right panel: Instructions
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.grey[50],
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionsList(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: recipe.imageUrl ?? '',
              fit: BoxFit.cover,
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetadataRow(context),
                const SizedBox(height: 24),
                
                // Tabbed view for ingredients/instructions
                _buildTabbedContent(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetadataRow(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        _MetadataChip(
          icon: Icons.schedule,
          label: '${recipe.prepTime + recipe.cookTime} min',
        ),
        _MetadataChip(
          icon: Icons.restaurant,
          label: '${recipe.servings} servings',
        ),
        if (recipe.difficulty != null)
          _MetadataChip(
            icon: Icons.bar_chart,
            label: recipe.difficulty!,
          ),
      ],
    );
  }
  
  Widget _buildIngredientsList(BuildContext context) {
    return Column(
      children: recipe.ingredients.map((ingredient) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${ingredient.quantity} ${ingredient.unit} ${ingredient.name}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildInstructionsList(BuildContext context) {
    return Column(
      children: recipe.instructions.asMap().entries.map((entry) {
        final index = entry.key;
        final instruction = entry.value;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step number
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Instruction text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instruction.text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                      ),
                    ),
                    if (instruction.imageUrl != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: instruction.imageUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  void _enterKitchenMode(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => KitchenRecipeView(recipe: recipe),
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  
  const _MetadataChip({
    required this.icon,
    required this.label,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Meal Planning Calendar - Tablet View

```dart
// lib/src/features/meal_planning/presentation/pages/meal_planning_page.dart

class MealPlanningPage extends ConsumerWidget {
  const MealPlanningPage({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceType = DeviceType.fromWidth(MediaQuery.of(context).size.width);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Planning'),
      ),
      body: deviceType.isTablet
          ? _buildTabletLayout(context, ref)
          : _buildMobileLayout(context, ref),
    );
  }
  
  Widget _buildTabletLayout(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Left: Calendar view (60%)
        Expanded(
          flex: 3,
          child: _buildCalendarSection(context, ref),
        ),
        
        // Right: Recipe browser / Details (40%)
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.grey[50],
            child: _buildRecipeBrowser(context, ref),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    return _buildCalendarSection(context, ref);
  }
  
  Widget _buildCalendarSection(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final mealPlans = ref.watch(mealPlansProvider);
    
    return Column(
      children: [
        // Calendar widget
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: selectedDate,
          calendarFormat: CalendarFormat.week,
          selectedDayPredicate: (day) => isSameDay(day, selectedDate),
          onDaySelected: (selected, focused) {
            ref.read(selectedDateProvider.notifier).state = selected;
          },
          eventLoader: (day) {
            return mealPlans.value
                ?.where((plan) => isSameDay(plan.date, day))
                .toList() ?? [];
          },
        ),
        
        // Meals for selected date
        Expanded(
          child: _buildMealsList(context, ref, selectedDate),
        ),
      ],
    );
  }
  
  Widget _buildMealsList(BuildContext context, WidgetRef ref, DateTime date) {
    final mealsForDate = ref.watch(mealsForDateProvider(date));
    
    return mealsForDate.when(
      data: (meals) {
        if (meals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No meals planned for this day',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _addMeal(context, ref, date),
                  icon: Icon(Icons.add),
                  label: Text('Add Meal'),
                ),
              ],
            ),
          );
        }
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMealSection(context, 'Breakfast', meals, MealType.breakfast),
            const SizedBox(height: 16),
            _buildMealSection(context, 'Lunch', meals, MealType.lunch),
            const SizedBox(height: 16),
            _buildMealSection(context, 'Dinner', meals, MealType.dinner),
            const SizedBox(height: 16),
            _buildMealSection(context, 'Snacks', meals, MealType.snack),
          ],
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading meals')),
    );
  }
  
  Widget _buildMealSection(
    BuildContext context,
    String title,
    List<MealPlanEntry> meals,
    MealType mealType,
  ) {
    final mealsOfType = meals.where((m) => m.mealType == mealType).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    // Add meal for this type
                  },
                ),
              ],
            ),
            
            if (mealsOfType.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No meals planned',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...mealsOfType.map((meal) => _buildMealCard(context, meal)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMealCard(BuildContext context, MealPlanEntry meal) {
    return ListTile(
      leading: meal.recipe.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: meal.recipe.imageUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            )
          : Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.restaurant),
            ),
      title: Text(meal.recipe.title),
      subtitle: Text('${meal.servings} servings'),
      trailing: IconButton(
        icon: Icon(Icons.more_vert),
        onPressed: () {
          // Show options menu
        },
      ),
      onTap: () {
        // Navigate to recipe detail
      },
    );
  }
}
```

---

## Required Dependencies

Add these to `pubspec.yaml` for mobile/tablet enhancements:

```yaml
dependencies:
  # Screen management
  wakelock_plus: ^1.2.0
  screen_brightness: ^1.0.1
  
  # Device info
  device_info_plus: ^10.0.1
  
  # Haptic feedback (built into Flutter SDK)
  
  # Gestures & interactions
  flutter_slidable: ^3.0.1
  
  # Calendar
  table_calendar: ^3.1.1
  
  # Pull to refresh (built into Material/Cupertino)
```

---

## Implementation Roadmap for Phase 2

### Week 1-2: Responsive Design System
- Implement breakpoint system and device detection
- Create responsive typography scales
- Build ResponsiveBuilder widget
- Add touch target constants and helpers
- Test on various device sizes

### Week 3-4: Kitchen Display Mode
- Implement kitchen mode state management
- Create kitchen recipe view with split layout
- Add kitchen timer with visual countdown
- Implement screen wake lock
- Add brightness controls
- Test on tablets in kitchen scenarios

### Week 5: Offline Capabilities Matrix
- Document all feature offline capabilities
- Build offline status indicators
- Create offline-aware widgets
- Implement graceful degradation
- Add offline fallback strategies

### Week 6: Mobile-Specific Features
- Implement swipe gestures on recipe cards
- Add haptic feedback throughout app
- Create pull-to-refresh on lists
- Implement screen wake management
- Test gestures on real devices

### Week 7-8: Tablet Layouts
- Build split-view recipe detail page
- Create tablet meal planning layout
- Implement multi-pane shopping list
- Add landscape optimizations
- Test on 7", 10", 12" tablets
- Optimize for kitchen counter use

---

## Testing Strategy for Mobile Features

### Device Testing Matrix

Test on representative devices from each category:

**Mobile:**
- iPhone SE (small screen, 320pt width)
- iPhone 14 (medium screen, 390pt width)
- iPhone 14 Pro Max (large screen, 430pt width)
- Android small (Pixel 4a)
- Android large (Samsung Galaxy S23 Ultra)

**Tablet:**
- iPad Mini (7.9", 768pt width)
- iPad (10.2", 810pt width)
- iPad Pro 12.9" (1024pt width)
- Android tablet (Samsung Tab S8)

**Test Scenarios:**
1. Kitchen mode with messy hands (use stylus/knuckle)
2. Bright sunlight readability
3. Reading from 2-3 feet away
4. Offline cooking (airplane mode)
5. Quick meal planning during grocery shopping
6. Recipe browsing while preparing ingredients

### Performance Benchmarks

- App launch: <2s cold start
- Kitchen mode activation: <500ms
- Recipe navigation: <100ms
- Offline sync: <3s for 100 items
- Timer accuracy: ±1s over 60 minutes
- Gesture response: <16ms (60fps)

---

## Success Criteria

✅ Kitchen mode usable with messy hands (56px+ touch targets)  
✅ Text readable from 3 feet away in bright kitchen  
✅ All core features work offline  
✅ Smooth 60fps animations and gestures  
✅ Battery usage acceptable during cooking session (<10%/hour)  
✅ Screen stays awake during active recipe viewing  
✅ Haptic feedback feels natural and helpful  
✅ Tablet layouts utilize screen space effectively  
✅ App adapts gracefully to offline/online transitions  
✅ Users can cook a recipe start-to-finish without frustration

---

## Future Enhancements (Phase 3)

- **Voice control** for hands-free operation ("Next step", "Set timer")
- **Collaborative cooking** (multiple users cooking same recipe simultaneously)
- **Kitchen display casting** (cast to TV/smart display)
- **Smart home integration** (preheat oven, start dishwasher)
- **Video tutorials** inline with recipe steps
- **AR ingredient recognition** using camera
- **Meal prep mode** (batch cooking optimization)
- **Kid-friendly mode** (simplified UI, step-by-step with images)
