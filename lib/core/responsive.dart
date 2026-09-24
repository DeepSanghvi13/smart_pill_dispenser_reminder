import 'package:flutter/material.dart';

/// Centralized responsive breakpoints and utilities for Smart Pill Reminder.
class Responsive {
  // Breakpoint definitions
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double maxContentWidthDefault = 1200.0;
  static const double maxFormWidthDefault = 640.0;
  static const double maxDialogWidthDefault = 540.0;

  /// Returns true if the viewport width is less than 600dp.
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  /// Returns true if the viewport width is strictly small (< 360dp).
  static bool isSmallMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360.0;

  /// Returns true if the viewport width is between 600dp and 1024dp.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Returns true if the viewport width is 1024dp or greater.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// Returns true if viewport is either tablet or desktop.
  static bool isTabletOrDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileBreakpoint;

  /// Returns the current device orientation.
  static Orientation orientation(BuildContext context) =>
      MediaQuery.orientationOf(context);

  /// Returns true if the current orientation is landscape.
  static bool isLandscape(BuildContext context) =>
      orientation(context) == Orientation.landscape;

  /// Returns the screen width.
  static double width(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  /// Returns the screen height.
  static double height(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  /// Evaluates and returns a value based on the current breakpoint.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= tabletBreakpoint && desktop != null) {
      return desktop;
    }
    if (w >= mobileBreakpoint && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Calculates an optimal column count for grids given available width or item min width.
  static int calculateGridColumns(
    BuildContext context, {
    double minItemWidth = 280.0,
    int minColumns = 1,
    int maxColumns = 6,
  }) {
    return calculateColumnsForWidth(
      MediaQuery.sizeOf(context).width,
      minItemWidth: minItemWidth,
      minColumns: minColumns,
      maxColumns: maxColumns,
    );
  }

  /// Calculates column count directly from a specific width constraint.
  static int calculateColumnsForWidth(
    double width, {
    double minItemWidth = 280.0,
    int minColumns = 1,
    int maxColumns = 6,
  }) {
    final cols = (width / minItemWidth).floor();
    return cols.clamp(minColumns, maxColumns);
  }

  /// Provides responsive horizontal padding for page layouts.
  static EdgeInsets pagePadding(BuildContext context) {
    return value<EdgeInsets>(
      context,
      mobile: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      tablet: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      desktop: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
    );
  }
}

/// A wrapper widget that constraints content to a maximum width and centers it,
/// preventing stretched or distorted UI on large tablet and desktop screens.
class ResponsiveContentWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const ResponsiveContentWrapper({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxContentWidthDefault,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

/// A specialized wrapper for forms and input screens to maintain ideal readable width.
class ResponsiveFormContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveFormContainer({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxFormWidthDefault,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: Responsive.value(context, mobile: 16.0, tablet: 24.0, desktop: 32.0),
          vertical: 16.0,
        );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}

/// A responsive dialog builder that automatically handles viewport constraints,
/// max-width, and keyboard-safe scrollable content.
class ResponsiveDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final double maxWidth;
  final IconData? icon;
  final Color? iconColor;

  const ResponsiveDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.maxWidth = Responsive.maxDialogWidthDefault,
    this.icon,
    this.iconColor,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    double maxWidth = Responsive.maxDialogWidthDefault,
    IconData? icon,
    Color? iconColor,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => ResponsiveDialog(
        title: title,
        content: content,
        actions: actions,
        maxWidth: maxWidth,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: iconColor ?? theme.colorScheme.primary, size: 26),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: content,
                ),
              ),

              // Actions
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
