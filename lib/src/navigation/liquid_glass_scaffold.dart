import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/liquid_glass_theme.dart';

/// Lays out a background, a body that scrolls underneath floating glass
/// bars, an optional [LiquidGlassAppBar]-style top bar and an optional
/// [LiquidGlassNavigationBar]-style bottom bar.
///
/// This is an ordinary widget, usable as the `home` of a `MaterialApp`,
/// `CupertinoApp` or inside any route; it does not replace your app
/// architecture.
///
/// What it coordinates:
///
/// * The body receives a [MediaQuery] whose top/bottom padding includes the
///   bars, so scroll views start below the app bar and end above the
///   navigation bar while still scrolling underneath the glass.
/// * The status-bar/navigation-bar icon brightness is set from the ambient
///   brightness through [AnnotatedRegion].
/// * The keyboard inset is respected when [resizeToAvoidBottomInset] is true.
/// * A transparent [Material] is provided so Material widgets in the body
///   (for example `ListTile`) work without an extra `Scaffold`.
class LiquidGlassScaffold extends StatelessWidget {
  /// Creates a scaffold.
  const LiquidGlassScaffold({
    super.key,
    required this.body,
    this.background,
    this.appBar,
    this.navigationBar,
    this.floatingAction,
    this.extendBody = true,
    this.resizeToAvoidBottomInset = true,
    this.systemOverlayStyle,
  });

  /// Main content.
  final Widget body;

  /// Painted behind everything; this is what the glass refracts. Defaults to
  /// the theme's opaque surface color.
  final Widget? background;

  /// Top bar, typically a [LiquidGlassAppBar].
  final PreferredSizeWidget? appBar;

  /// Bottom bar, typically a [LiquidGlassNavigationBar].
  final PreferredSizeWidget? navigationBar;

  /// A widget floating above the navigation bar at the bottom end corner.
  final Widget? floatingAction;

  /// Whether [body] extends behind the bars (true) or is laid out between
  /// them (false).
  final bool extendBody;

  /// Whether the body avoids the on-screen keyboard.
  final bool resizeToAvoidBottomInset;

  /// Overrides the automatic system UI overlay style.
  final SystemUiOverlayStyle? systemOverlayStyle;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq =
        MediaQuery.maybeOf(context) ?? const MediaQueryData();
    final LiquidGlassThemeData theme = LiquidGlassTheme.of(context);
    final Brightness brightness = LiquidGlassTheme.brightnessOf(context);

    final double appBarHeight = appBar?.preferredSize.height ?? 0;
    final double navHeight = navigationBar?.preferredSize.height ?? 0;
    final double top = mq.padding.top + appBarHeight;
    double bottom = mq.padding.bottom + navHeight;
    if (resizeToAvoidBottomInset) {
      bottom = math.max(bottom, mq.viewInsets.bottom);
    }

    Widget content;
    if (extendBody) {
      content = MediaQuery(
        data: mq.copyWith(
          padding: mq.padding.copyWith(top: top, bottom: bottom),
        ),
        child: body,
      );
    } else {
      content = Padding(
        padding: EdgeInsets.only(top: top, bottom: bottom),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          child: body,
        ),
      );
    }
    final Widget? appBarWidget = appBar;
    final Widget? navigationBarWidget = navigationBar;
    final Widget? floatingActionWidget = floatingAction;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          systemOverlayStyle ??
          (brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark),
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: background ?? ColoredBox(color: theme.opaqueSurfaceColor),
            ),
            Positioned.fill(child: content),
            if (appBarWidget != null)
              Positioned(top: 0, left: 0, right: 0, child: appBarWidget),
            if (navigationBarWidget != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: navigationBarWidget,
              ),
            if (floatingActionWidget != null)
              PositionedDirectional(
                end: 20,
                bottom: mq.padding.bottom + navHeight + 16,
                child: floatingActionWidget,
              ),
          ],
        ),
      ),
    );
  }
}
