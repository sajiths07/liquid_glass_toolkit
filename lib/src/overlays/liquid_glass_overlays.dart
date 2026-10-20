import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../animation/animation_config.dart';
import '../animation/glass_presence.dart';
import '../animation/liquid_glass_transitions.dart';
import '../core/glass_quality.dart';
import '../core/glass_style.dart';
import '../theme/liquid_glass_theme.dart';
import '../widgets/glass_pressable.dart';
import '../widgets/liquid_glass_button.dart';
import '../widgets/liquid_glass_surface.dart';

String _dismissLabel(BuildContext context) {
  return Localizations.of<MaterialLocalizations>(
        context,
        MaterialLocalizations,
      )?.modalBarrierDismissLabel ??
      Localizations.of<CupertinoLocalizations>(
        context,
        CupertinoLocalizations,
      )?.modalBarrierDismissLabel ??
      'Dismiss';
}

LiquidGlassAnimationConfig _overlayConfig(
  BuildContext context,
  LiquidGlassAnimationConfig? override,
) {
  return (override ?? LiquidGlassTheme.of(context).overlayAnimation).resolve(
    reduceMotion: LiquidGlassTheme.reduceMotionOf(context),
  );
}

/// Shared plumbing for this package's popup routes: theme capture, timing
/// and a single, disposed [CurvedAnimation].
abstract class _GlassPopupRoute<T> extends PopupRoute<T> {
  _GlassPopupRoute({
    required this.config,
    required this.themes,
    required this.dismissible,
    required this.barrierColorValue,
    required this.label,
    super.settings,
  });

  final LiquidGlassAnimationConfig config;
  final CapturedThemes themes;
  final bool dismissible;
  final Color? barrierColorValue;
  final String label;

  CurvedAnimation? _curved;

  /// The route animation shaped by the config's curves.
  Animation<double> get curved => _curved ??= CurvedAnimation(
    parent: animation!,
    curve: config.curve,
    reverseCurve: config.effectiveReverseCurve,
  );

  @override
  bool get barrierDismissible => dismissible;

  @override
  Color? get barrierColor => barrierColorValue;

  @override
  String? get barrierLabel => label;

  @override
  Duration get transitionDuration => config.duration;

  @override
  Duration get reverseTransitionDuration => config.effectiveReverseDuration;

  @override
  void dispose() {
    _curved?.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Dialog
// ---------------------------------------------------------------------------

/// Shows a modal glass dialog built by [builder] (typically a
/// [LiquidGlassDialog]) and returns the value passed to `Navigator.pop`.
///
/// The dialog fades its glass in (without breaking blur) while settling from
/// a slightly enlarged scale. Timing comes from [animation] or the theme's
/// `overlayAnimation`; reduced motion turns it into a short fade.
Future<T?> showLiquidGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor = const Color(0x33000000),
  String? barrierLabel,
  LiquidGlassAnimationConfig? animation,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  final NavigatorState navigator = Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  );
  return navigator.push<T>(
    _LiquidGlassDialogRoute<T>(
      builder: builder,
      config: _overlayConfig(context, animation),
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      dismissible: barrierDismissible,
      barrierColorValue: barrierColor,
      label: barrierLabel ?? _dismissLabel(context),
      settings: routeSettings,
    ),
  );
}

class _LiquidGlassDialogRoute<T> extends _GlassPopupRoute<T> {
  _LiquidGlassDialogRoute({
    required this.builder,
    required super.config,
    required super.themes,
    required super.dismissible,
    required super.barrierColorValue,
    required super.label,
    super.settings,
  });

  final WidgetBuilder builder;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return themes.wrap(
      SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Builder(builder: builder),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return LiquidGlassTransition(
      animation: curved,
      scaleBegin: 1.12,
      child: child,
    );
  }
}

/// A glass alert-style dialog with an optional [title], [content] and a
/// row (or column, when space is tight) of [actions].
class LiquidGlassDialog extends StatelessWidget {
  /// Creates a dialog.
  const LiquidGlassDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const <Widget>[],
    this.style,
    this.quality,
    this.maxWidth = 340,
    this.semanticLabel,
    this.foregroundColor,
  });

  /// Default color of the title, content and glass buttons in [actions]
  /// that don't set their own. Defaults to the theme `foregroundColor`.
  final Color? foregroundColor;

  /// Title, exposed as a header.
  final Widget? title;

  /// Body.
  final Widget? content;

  /// Action widgets, typically [LiquidGlassButton]s.
  final List<Widget> actions;

  /// Glass style. Defaults to a more opaque version of the theme style for
  /// legibility.
  final LiquidGlassStyle? style;

  /// Rendering quality.
  final LiquidGlassQuality? quality;

  /// Maximum width.
  final double maxWidth;

  /// Label announced when the dialog opens.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final LiquidGlassThemeData theme = LiquidGlassTheme.of(context);
    final LiquidGlassStyle base = theme.style;
    final LiquidGlassStyle effective =
        style ??
        base.copyWith(
          opacity: math.max(base.opacity, 0.42),
          blur: math.max(base.blur, 20),
          borderRadius: BorderRadius.circular(30),
        );
    final Widget dialog = Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: LiquidGlassSurface(
          style: effective,
          quality: quality,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (title != null)
                  Semantics(
                    header: true,
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                      child: title!,
                    ),
                  ),
                if (title != null && content != null) const SizedBox(height: 8),
                if (content != null)
                  Flexible(
                    child: SingleChildScrollView(
                      child: DefaultTextStyle.merge(
                        style: const TextStyle(fontSize: 15, height: 1.35),
                        textAlign: TextAlign.center,
                        child: content!,
                      ),
                    ),
                  ),
                if (actions.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints c) {
                      final bool stacked =
                          actions.length > 2 || c.maxWidth < 240;
                      if (stacked) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            for (
                              int i = 0;
                              i < actions.length;
                              i++
                            ) ...<Widget>[
                              if (i > 0) const SizedBox(height: 8),
                              actions[i],
                            ],
                          ],
                        );
                      }
                      return Row(
                        children: <Widget>[
                          for (int i = 0; i < actions.length; i++) ...<Widget>[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(child: actions[i]),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    final Color? fg = foregroundColor;
    if (fg == null) return dialog;
    return LiquidGlassTheme(
      data: theme.copyWith(foregroundColor: fg),
      child: dialog,
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet
// ---------------------------------------------------------------------------

/// Shows a floating glass bottom sheet.
///
/// The sheet slides up using [animation] (or the theme `overlayAnimation`).
/// With [enableDrag], it follows the finger, rubber-bands when pulled up,
/// dismisses on a downward fling or a long drag, and otherwise springs back
/// using the config's spring (velocity preserved).
Future<T?> showLiquidGlassSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = true,
  double maxHeightFactor = 0.9,
  Color? barrierColor = const Color(0x29000000),
  LiquidGlassStyle? style,
  LiquidGlassQuality? quality,
  LiquidGlassAnimationConfig? animation,
  bool useRootNavigator = false,
  RouteSettings? routeSettings,
  Color? foregroundColor,
  Color? dragHandleColor,
}) {
  final NavigatorState navigator = Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  );
  return navigator.push<T>(
    _LiquidGlassSheetRoute<T>(
      builder: builder,
      config: _overlayConfig(context, animation),
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      dismissible: isDismissible,
      barrierColorValue: barrierColor,
      label: _dismissLabel(context),
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      maxHeightFactor: maxHeightFactor.clamp(0.1, 1.0),
      style: style,
      quality: quality,
      foregroundColor: foregroundColor,
      dragHandleColor: dragHandleColor,
      settings: routeSettings,
    ),
  );
}

class _LiquidGlassSheetRoute<T> extends _GlassPopupRoute<T> {
  _LiquidGlassSheetRoute({
    required this.builder,
    required super.config,
    required super.themes,
    required super.dismissible,
    required super.barrierColorValue,
    required super.label,
    required this.enableDrag,
    required this.showDragHandle,
    required this.maxHeightFactor,
    this.style,
    this.quality,
    this.foregroundColor,
    this.dragHandleColor,
    super.settings,
  });

  final WidgetBuilder builder;
  final bool enableDrag;
  final bool showDragHandle;
  final double maxHeightFactor;
  final LiquidGlassStyle? style;
  final LiquidGlassQuality? quality;
  final Color? foregroundColor;
  final Color? dragHandleColor;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return themes.wrap(_SheetFrame<T>(route: this));
  }
}

class _SheetFrame<T> extends StatefulWidget {
  const _SheetFrame({super.key, required this.route});

  final _LiquidGlassSheetRoute<T> route;

  @override
  State<_SheetFrame<T>> createState() => _SheetFrameState<T>();
}

class _SheetFrameState<T> extends State<_SheetFrame<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drag = AnimationController.unbounded(
    vsync: this,
  );
  final GlobalKey _sheetKey = GlobalKey();
  bool _popping = false;

  double get _sheetHeight => _sheetKey.currentContext?.size?.height ?? 300;

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_popping) return;
    final double next = _drag.value + d.primaryDelta!;
    // Resist upward drags.
    _drag.value = next < 0 ? _drag.value + d.primaryDelta! * 0.2 : next;
  }

  void _onDragEnd(DragEndDetails d) {
    if (_popping) return;
    final double velocity = d.primaryVelocity ?? 0;
    final bool dismiss =
        widget.route.dismissible &&
        (velocity > 700 || _drag.value > _sheetHeight * 0.35);
    if (dismiss) {
      _popping = true;
      Navigator.of(context).pop();
      return;
    }
    final LiquidGlassAnimationConfig config = widget.route.config;
    config.drive(
      _drag,
      0,
      velocity: velocity,
      tolerance: const Tolerance(distance: 0.5, velocity: 5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _LiquidGlassSheetRoute<T> route = widget.route;
    final LiquidGlassThemeData theme = LiquidGlassTheme.of(context);
    final Color fg = route.foregroundColor ?? theme.foregroundColor;
    final MediaQueryData mq = MediaQuery.of(context);
    final LiquidGlassStyle style =
        route.style ??
        theme.style.copyWith(
          opacity: math.max(theme.style.opacity, 0.36),
          blur: math.max(theme.style.blur, 22),
          borderRadius: BorderRadius.circular(34),
        );

    Widget sheet = LiquidGlassSurface(
      key: _sheetKey,
      style: style,
      quality: route.quality,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (route.showDragHandle)
              Semantics(
                button: route.dismissible,
                label: route.label,
                onTap: route.dismissible
                    ? () => Navigator.of(context).maybePop()
                    : null,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    width: 38,
                    height: 5,
                    decoration: BoxDecoration(
                      color:
                          route.dragHandleColor ??
                          fg.withValues(alpha: fg.a * 0.28),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            Flexible(child: Builder(builder: route.builder)),
          ],
        ),
      ),
    );
    if (route.foregroundColor != null) {
      sheet = LiquidGlassTheme(
        data: theme.copyWith(foregroundColor: fg),
        child: sheet,
      );
    }

    if (route.enableDrag) {
      sheet = GestureDetector(
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        child: sheet,
      );
    }

    sheet = Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      child: sheet,
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          8,
          mq.padding.top + 8,
          8,
          math.max(mq.padding.bottom, 8) + mq.viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight: mq.size.height * route.maxHeightFactor,
          ),
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[route.curved, _drag]),
            child: sheet,
            builder: (BuildContext context, Widget? child) {
              final double t = route.curved.value;
              return Transform.translate(
                offset: Offset(0, _drag.value),
                child: FractionalTranslation(
                  translation: Offset(0, (1 - t) * 1.1),
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Morph (trigger -> surface) and menu
// ---------------------------------------------------------------------------

/// Expands a glass surface out of the widget at [context] (the trigger) into
/// a panel of [size], and collapses it back into the trigger on dismissal.
///
/// The morph interpolates position, size and corner radius from the
/// trigger's on-screen rectangle to the destination, fades the glass in
/// first and the content after the shape has mostly formed. The
/// destination is placed below the trigger when it fits (otherwise above),
/// aligned to the trigger's leading or trailing edge and kept inside the
/// safe area. The trigger rectangle is re-measured every frame, so
/// orientation changes and layout shifts are followed.
///
/// [size] is the preferred destination size; it is clamped to the screen
/// and the content should be scrollable if it can overflow.
///
/// [triggerBorderRadius] should match the trigger's shape for a seamless
/// start; it defaults to a capsule.
Future<T?> showLiquidGlassMorph<T>({
  required BuildContext context,
  required Size size,
  required WidgetBuilder builder,
  BorderRadius? triggerBorderRadius,
  LiquidGlassStyle? style,
  LiquidGlassQuality? quality,
  LiquidGlassAnimationConfig? animation,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  final NavigatorState navigator = Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  );
  final RenderBox? overlayBox =
      navigator.overlay?.context.findRenderObject() as RenderBox?;
  final Rect source = _measure(context, overlayBox) ?? Rect.zero;
  return navigator.push<T>(
    _LiquidGlassMorphRoute<T>(
      triggerContext: context,
      initialSource: source,
      triggerRadius:
          triggerBorderRadius ??
          BorderRadius.circular(math.min(source.width, source.height) / 2),
      size: size,
      builder: builder,
      style: style,
      quality: quality,
      config: _overlayConfig(context, animation),
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      dismissible: barrierDismissible,
      barrierColorValue: barrierColor,
      label: _dismissLabel(context),
      settings: routeSettings,
    ),
  );
}

Rect? _measure(BuildContext context, RenderBox? ancestor) {
  if (!context.mounted) return null;
  final RenderObject? object = context.findRenderObject();
  if (object is! RenderBox || !object.attached || !object.hasSize) return null;
  if (ancestor != null && !ancestor.attached) return null;
  return MatrixUtils.transformRect(
    object.getTransformTo(ancestor),
    Offset.zero & object.size,
  );
}

class _LiquidGlassMorphRoute<T> extends _GlassPopupRoute<T> {
  _LiquidGlassMorphRoute({
    required this.triggerContext,
    required Rect initialSource,
    required this.triggerRadius,
    required this.size,
    required this.builder,
    required super.config,
    required super.themes,
    required super.dismissible,
    required super.barrierColorValue,
    required super.label,
    this.style,
    this.quality,
    super.settings,
  }) : _lastSource = initialSource;

  final BuildContext triggerContext;
  final BorderRadius triggerRadius;
  final Size size;
  final WidgetBuilder builder;
  final LiquidGlassStyle? style;
  final LiquidGlassQuality? quality;
  Rect _lastSource;

  Rect currentSource() {
    final RenderBox? overlayBox =
        navigator?.overlay?.context.findRenderObject() as RenderBox?;
    final Rect? measured = _measure(triggerContext, overlayBox);
    if (measured != null && measured.isFinite) _lastSource = measured;
    return _lastSource;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return themes.wrap(_MorphFrame<T>(route: this));
  }
}

/// Places the destination rectangle next to [source] inside [bounds].
Rect glassMorphDestination({
  required Rect source,
  required Size size,
  required Rect bounds,
  required TextDirection textDirection,
  double gap = 8,
}) {
  final double width = math.min(size.width, math.max(0, bounds.width));
  final double height = math.min(size.height, math.max(0, bounds.height));
  double left = textDirection == TextDirection.ltr
      ? source.left
      : source.right - width;
  if (left + width > bounds.right) left = source.right - width;
  if (left < bounds.left) left = source.left;
  left = left.clamp(bounds.left, math.max(bounds.left, bounds.right - width));

  final double below = source.bottom + gap;
  final double above = source.top - gap - height;
  double top;
  if (below + height <= bounds.bottom) {
    top = below;
  } else if (above >= bounds.top) {
    top = above;
  } else {
    top = bounds.bottom - height;
  }
  top = top.clamp(bounds.top, math.max(bounds.top, bounds.bottom - height));
  return Rect.fromLTWH(left, top, width, height);
}

class _MorphFrame<T> extends StatelessWidget {
  const _MorphFrame({super.key, required this.route});

  final _LiquidGlassMorphRoute<T> route;

  @override
  Widget build(BuildContext context) {
    final LiquidGlassThemeData theme = LiquidGlassTheme.of(context);
    final bool reduceMotion = LiquidGlassTheme.reduceMotionOf(context);
    final MediaQueryData mq = MediaQuery.of(context);
    final TextDirection dir =
        Directionality.maybeOf(context) ?? TextDirection.ltr;
    final LiquidGlassStyle destStyle =
        route.style ??
        theme.style.copyWith(
          opacity: math.max(theme.style.opacity, 0.4),
          blur: math.max(theme.style.blur, 20),
          borderRadius: BorderRadius.circular(24),
        );
    final Widget content = Material(
      type: MaterialType.transparency,
      child: Builder(builder: route.builder),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Rect bounds = mq.padding
            .deflateRect(Offset.zero & constraints.biggest)
            .deflate(12);
        return AnimatedBuilder(
          animation: route.curved,
          child: content,
          builder: (BuildContext context, Widget? child) {
            final Rect source = route.currentSource();
            final Rect dest = glassMorphDestination(
              source: source,
              size: route.size,
              bounds: bounds,
              textDirection: dir,
            );
            final double t = route.curved.value;
            final double g = reduceMotion ? 1 : t;
            final Rect rect = Rect.lerp(source, dest, g)!;
            final BorderRadius radius = BorderRadius.lerp(
              route.triggerRadius,
              destStyle.borderRadius,
              g.clamp(0.0, 1.0),
            )!;
            final double glassPresence = (t * 4).clamp(0.0, 1.0);
            final double contentOpacity = ((t - 0.4) / 0.6).clamp(0.0, 1.0);
            final double contentScale = lerpDouble(0.94, 1, g.clamp(0.0, 1.0))!;
            final Alignment anchor = Alignment(
              dest.center.dx >= source.center.dx ? -1 : 1,
              dest.top >= source.top ? -1 : 1,
            );
            return Stack(
              children: <Widget>[
                Positioned.fromRect(
                  rect: rect,
                  child: LiquidGlassPresence(
                    value: glassPresence,
                    child: LiquidGlassSurface(
                      style: destStyle.copyWith(borderRadius: radius),
                      quality: route.quality,
                      child: Semantics(
                        scopesRoute: true,
                        namesRoute: true,
                        explicitChildNodes: true,
                        child: IgnorePointer(
                          ignoring: contentOpacity < 0.5,
                          child: Opacity(
                            opacity: contentOpacity,
                            child: OverflowBox(
                              alignment: anchor,
                              minWidth: dest.width,
                              maxWidth: dest.width,
                              minHeight: dest.height,
                              maxHeight: dest.height,
                              child: Transform.scale(
                                scale: contentScale,
                                alignment: anchor,
                                child: child,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// An entry of a liquid-glass menu.
@immutable
class LiquidGlassMenuItem {
  /// Creates a menu item.
  const LiquidGlassMenuItem({
    required this.label,
    this.leading,
    this.onPressed,
    this.destructive = false,
    this.color,
  });

  /// Text and icon color of this item. Falls back to the menu's
  /// `destructiveColor` / `foregroundColor`, then the theme
  /// `destructiveColor` / `foregroundColor`.
  final Color? color;

  /// Item text.
  final String label;

  /// Optional icon before the label.
  final Widget? leading;

  /// Called after the menu closes. `null` disables the item.
  final VoidCallback? onPressed;

  /// Renders the item in the destructive color (red by default).
  final bool destructive;
}

/// Opens a menu that morphs out of the widget at [context]. Selecting an
/// item closes the menu and then calls its `onPressed`.
///
/// [foregroundColor] and [destructiveColor] apply to items that don't set
/// their own `color`, and default to the theme colors of the same name.
Future<void> showLiquidGlassMenu({
  required BuildContext context,
  required List<LiquidGlassMenuItem> items,
  double width = 240,
  BorderRadius? triggerBorderRadius,
  LiquidGlassStyle? style,
  LiquidGlassQuality? quality,
  LiquidGlassAnimationConfig? animation,
  Color? foregroundColor,
  Color? destructiveColor,
}) async {
  assert(items.isNotEmpty, 'A menu needs at least one item');
  final double textScale =
      (MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling).scale(
        16,
      ) /
      16;
  final double itemHeight = 48 * math.max(1, textScale);
  final VoidCallback? selected = await showLiquidGlassMorph<VoidCallback>(
    context: context,
    size: Size(width, items.length * itemHeight + 12),
    triggerBorderRadius: triggerBorderRadius,
    style: style,
    quality: quality,
    animation: animation,
    builder: (BuildContext context) => _MenuList(
      items: items,
      itemHeight: itemHeight,
      foregroundColor: foregroundColor,
      destructiveColor: destructiveColor,
    ),
  );
  selected?.call();
}

class _MenuList extends StatelessWidget {
  const _MenuList({
    required this.items,
    required this.itemHeight,
    this.foregroundColor,
    this.destructiveColor,
  });

  final List<LiquidGlassMenuItem> items;
  final double itemHeight;
  final Color? foregroundColor;
  final Color? destructiveColor;

  @override
  Widget build(BuildContext context) {
    final LiquidGlassThemeData theme = LiquidGlassTheme.of(context);
    final Color fg = foregroundColor ?? theme.foregroundColor;
    final Color destructive = destructiveColor ?? theme.destructiveColor;
    return ListView.builder(
      padding: const EdgeInsets.all(6),
      physics: const ClampingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int i) {
        final LiquidGlassMenuItem item = items[i];
        final Color color = item.color ?? (item.destructive ? destructive : fg);
        final VoidCallback? onPressed = item.onPressed;
        return GlassPressable(
          onPressed: onPressed == null
              ? null
              : () => Navigator.of(context).pop<VoidCallback>(onPressed),
          semanticLabel: item.label,
          pressScale: 0.02,
          autofocus: i == 0,
          builder: (BuildContext context, GlassInteractionState s, _) {
            final double highlight = math.max(
              s.press.clamp(0.0, 1.0),
              s.hovered || s.focused ? 0.6 : 0,
            );
            return Container(
              height: itemHeight,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: fg.withValues(alpha: fg.a * 0.1 * highlight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ExcludeSemantics(
                child: Row(
                  children: <Widget>[
                    if (item.leading != null) ...<Widget>[
                      IconTheme.merge(
                        data: IconThemeData(color: color, size: 20),
                        child: item.leading!,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          color: s.enabled
                              ? color
                              : color.withValues(alpha: color.a * 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// A glass button that opens a [showLiquidGlassMenu] morphing out of it.
class LiquidGlassMenuButton extends StatelessWidget {
  /// Creates a menu button.
  const LiquidGlassMenuButton({
    super.key,
    required this.items,
    required this.child,
    this.semanticLabel,
    this.menuWidth = 240,
    this.style,
    this.menuStyle,
    this.quality,
    this.animation,
    this.foregroundColor,
    this.menuForegroundColor,
    this.menuDestructiveColor,
  });

  /// Color of the trigger button's content. Defaults to the theme
  /// `foregroundColor`.
  final Color? foregroundColor;

  /// Color of menu items that don't set their own `color`. Defaults to the
  /// theme `foregroundColor`.
  final Color? menuForegroundColor;

  /// Color of destructive menu items that don't set their own `color`.
  /// Defaults to the theme `destructiveColor`.
  final Color? menuDestructiveColor;

  /// Menu entries.
  final List<LiquidGlassMenuItem> items;

  /// Button content.
  final Widget child;

  /// Label for screen readers (recommended for icon-only buttons).
  final String? semanticLabel;

  /// Width of the menu.
  final double menuWidth;

  /// Style of the trigger button.
  final LiquidGlassStyle? style;

  /// Style of the menu surface.
  final LiquidGlassStyle? menuStyle;

  /// Rendering quality.
  final LiquidGlassQuality? quality;

  /// Overrides the theme `overlayAnimation`.
  final LiquidGlassAnimationConfig? animation;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext triggerContext) {
        return LiquidGlassButton(
          style: style,
          quality: quality,
          semanticLabel: semanticLabel,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          onPressed: () => showLiquidGlassMenu(
            context: triggerContext,
            items: items,
            width: menuWidth,
            style: menuStyle,
            quality: quality,
            animation: animation,
            foregroundColor: menuForegroundColor,
            destructiveColor: menuDestructiveColor,
          ),
          child: child,
        );
      },
    );
  }
}
