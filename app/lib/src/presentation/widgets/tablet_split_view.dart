/// Space Food - Self-Hosted Meal Planning Application
/// Copyright (C) 2025 RGH Software
/// Licensed under AGPL-3.0

import 'package:flutter/material.dart';
import '../../core/utils/responsive_builder.dart';

/// Split-view layout optimized for tablets in landscape mode
/// Displays two panels side-by-side with adjustable ratio
class TabletSplitView extends StatelessWidget {
  final Widget leftPanel;
  final Widget rightPanel;
  final double leftFlex;
  final double rightFlex;
  final Widget? divider;
  final bool showDivider;

  const TabletSplitView({
    super.key,
    required this.leftPanel,
    required this.rightPanel,
    this.leftFlex = 2.0,
    this.rightFlex = 3.0,
    this.divider,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, info) {
        // Only show split view on tablets in landscape
        if (info.isTablet && info.isLandscape) {
          return Row(
            children: [
              Expanded(
                flex: leftFlex.toInt(),
                child: leftPanel,
              ),
              if (showDivider)
                divider ??
                    VerticalDivider(
                      width: 1,
                      color: Theme.of(context).dividerColor,
                    ),
              Expanded(
                flex: rightFlex.toInt(),
                child: rightPanel,
              ),
            ],
          );
        }

        // On mobile or tablet portrait, show only right panel
        // (left panel typically accessible via back navigation or tabs)
        return rightPanel;
      },
    );
  }
}

/// Master-detail layout optimized for tablets
/// Shows master list on left, detail view on right
class TabletMasterDetailView extends StatefulWidget {
  final Widget masterPanel;
  final Widget Function(BuildContext context)? detailBuilder;
  final Widget? emptyDetailView;
  final double masterFlex;
  final double detailFlex;

  const TabletMasterDetailView({
    super.key,
    required this.masterPanel,
    this.detailBuilder,
    this.emptyDetailView,
    this.masterFlex = 2.0,
    this.detailFlex = 3.0,
  });

  @override
  State<TabletMasterDetailView> createState() => _TabletMasterDetailViewState();
}

class _TabletMasterDetailViewState extends State<TabletMasterDetailView> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, info) {
        if (info.isTablet && info.isLandscape) {
          // Tablet landscape: Show split view
          return Row(
            children: [
              // Master panel (list)
              Expanded(
                flex: widget.masterFlex.toInt(),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: widget.masterPanel,
                ),
              ),
              // Detail panel
              Expanded(
                flex: widget.detailFlex.toInt(),
                child: widget.detailBuilder?.call(context) ??
                    widget.emptyDetailView ??
                    _buildEmptyDetailView(context),
              ),
            ],
          );
        }

        // Mobile/portrait: Show only master panel
        return widget.masterPanel;
      },
    );
  }

  Widget _buildEmptyDetailView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_back,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Select an item to view details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }
}

/// Three-panel layout for large tablets/desktops
/// Shows navigation, list, and detail panels
class TabletThreePanelView extends StatelessWidget {
  final Widget? navigationPanel;
  final Widget masterPanel;
  final Widget detailPanel;
  final double navigationFlex;
  final double masterFlex;
  final double detailFlex;

  const TabletThreePanelView({
    super.key,
    this.navigationPanel,
    required this.masterPanel,
    required this.detailPanel,
    this.navigationFlex = 1.0,
    this.masterFlex = 2.0,
    this.detailFlex = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, info) {
        if (info.isDesktop || (info.isTablet && info.width >= 1024)) {
          // Large screen: Show three panels
          return Row(
            children: [
              if (navigationPanel != null) ...[
                Expanded(
                  flex: navigationFlex.toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: navigationPanel,
                  ),
                ),
              ],
              Expanded(
                flex: masterFlex.toInt(),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: masterPanel,
                ),
              ),
              Expanded(
                flex: detailFlex.toInt(),
                child: detailPanel,
              ),
            ],
          );
        } else if (info.isTablet && info.isLandscape) {
          // Tablet landscape: Show two panels (master + detail)
          return Row(
            children: [
              Expanded(
                flex: masterFlex.toInt(),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: masterPanel,
                ),
              ),
              Expanded(
                flex: detailFlex.toInt(),
                child: detailPanel,
              ),
            ],
          );
        }

        // Mobile/portrait: Show only detail panel
        return detailPanel;
      },
    );
  }
}

/// Adaptive container that adjusts padding and constraints for tablets
class TabletAdaptiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final double? maxWidth;

  const TabletAdaptiveContainer({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, info) {
        final padding = info.isTablet
            ? (tabletPadding ?? const EdgeInsets.all(24))
            : (mobilePadding ?? const EdgeInsets.all(16));

        Widget content = Padding(
          padding: padding,
          child: child,
        );

        // Apply max width constraint if specified
        if (maxWidth != null) {
          content = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth!),
              child: content,
            ),
          );
        }

        return content;
      },
    );
  }
}
