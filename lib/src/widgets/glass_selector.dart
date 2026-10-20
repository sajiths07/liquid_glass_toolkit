import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../animation/animation_config.dart';
import '../core/glass_drop_style.dart';
import '../core/glass_quality.dart';
import '../core/glass_style.dart';
import '../theme/liquid_glass_theme.dart';
import 'glass_pressable.dart';
import 'liquid_glass_surface.dart';

/// Builds one item of a [GlassSelectorRow]. [selectedness] is `1` when the
/// indicator sits exactly on the item and falls to `0` one item away, so
/// colors can follow the moving indicator.
typedef GlassSelectorItemBuilder =
    Widget Function(BuildContext context, int index, double selectedness);

/// Internal row of equally sized options with a liquid sliding indicator.
///
/// The indicator position is a spring-driven value in "item units". While
/// moving it stretches horizontally in proportion to its velocity and
/// slightly flattens, which reads as a liquid drop being pulled along. The
/// indicator can also be dragged; on release it snaps (with the release
/// velocity) to the nearest item.
class GlassSelectorRow extends StatefulWidget {
  /// Creates a selector row.
  const GlassSelectorRow({
    super.key,
    required this.itemCount,
    required this.selectedIndex,
    required this.onSelected,
    required this.itemBuilder,
    required this.semanticLabelBuilder,
    required this.indicatorStyle,
    this.indicatorQuality = LiquidGlassQuality.minimal,
    this.animation,
    this.indicatorInset = const EdgeInsets.all(3),
    this.enableDrag = true,
    this.indicatorForegroundBuilder,
    this.drop,
  }) : assert(itemCount > 0),
       assert(selectedIndex >= 0 && selectedIndex < itemCount);

  /// Number of items.
  final int itemCount;

  /// Currently selected index.
  final int selectedIndex;

  /// Called with a new index when the user selects an item. `null` disables
  /// the row.
  final ValueChanged<int>? onSelected;

  /// Builds item content.
  final GlassSelectorItemBuilder itemBuilder;

  /// Semantic label per item.
  final String? Function(int index) semanticLabelBuilder;

  /// Glass style of the indicator.
  final LiquidGlassStyle indicatorStyle;

  /// Quality of the indicator surface.
  final LiquidGlassQuality indicatorQuality;

  /// Overrides the theme `animation`.
  final LiquidGlassAnimationConfig? animation;

  /// Gap between the indicator and the item bounds.
  final EdgeInsets indicatorInset;

  /// Whether the indicator can be dragged.
  final bool enableDrag;

  /// Optional decoration painted inside the indicator (for example drop
  /// optics), built with the indicator's current corner radius. It is sized
  /// to the indicator.
  final Widget Function(BorderRadius radius)? indicatorForegroundBuilder;

  /// When set, the indicator is a water drop: its size, shape, stretch,
  /// shadow and magnification come from this style.
  final LiquidGlassDropStyle? drop;

  @override
  State<GlassSelectorRow> createState() => _GlassSelectorRowState();
}

class _GlassSelectorRowState extends State<GlassSelectorRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: widget.selectedIndex.toDouble(),
  );
  double _itemWidth = 1;
  bool _dragging = false;

  LiquidGlassAnimationConfig _config() =>
      (widget.animation ?? LiquidGlassTheme.of(context).animation).resolve(
        reduceMotion: LiquidGlassTheme.reduceMotionOf(context),
      );

  void _animateTo(int index, {double velocity = 0}) {
    _config().drive(
      _position,
      index.toDouble(),
      velocity: velocity,
      tolerance: const Tolerance(distance: 0.001, velocity: 0.01),
    );
  }

  @override
  void didUpdateWidget(GlassSelectorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex && !_dragging) {
      _animateTo(widget.selectedIndex, velocity: _position.velocity);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  bool get _rtl => Directionality.maybeOf(context) == TextDirection.rtl;

  void _select(int index, {double velocity = 0}) {
    if (index != widget.selectedIndex) widget.onSelected?.call(index);
    _animateTo(index, velocity: velocity);
    // If the parent rejects the change, return to the selected item.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_dragging && widget.selectedIndex != index) {
        _animateTo(widget.selectedIndex, velocity: _position.velocity);
      }
    });
  }

  void _onDragStart(DragStartDetails details) {
    _dragging = true;
    _position.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final double delta = details.primaryDelta! / _itemWidth;
    final double max = widget.itemCount - 1.0;
    double next = _position.value + (_rtl ? -delta : delta);
    // Rubber-band beyond the ends.
    if (next < 0) next = _position.value + (next - _position.value) * 0.35;
    if (next > max) next = _position.value + (next - _position.value) * 0.35;
    _position.value = next.clamp(-0.4, max + 0.4);
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    final double velocity =
        (details.primaryVelocity ?? 0) / _itemWidth * (_rtl ? -1 : 1);
    final int target = (_position.value + velocity * 0.08).round().clamp(
      0,
      widget.itemCount - 1,
    );
    _select(target, velocity: velocity);
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = LiquidGlassTheme.reduceMotionOf(context);
    final LiquidGlassDropStyle? drop = widget.drop;
    final bool magnify =
        (drop?.usesMagnification ?? false) &&
        !LiquidGlassTheme.reduceTransparencyOf(context);
    final bool enabled = widget.onSelected != null;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        _itemWidth = math.max(1, width / widget.itemCount);
        final Widget items = Row(
          children: List<Widget>.generate(widget.itemCount, (int i) {
            return Expanded(
              child: GlassPressable(
                onPressed: enabled ? () => _select(i) : null,
                selected: i == widget.selectedIndex,
                inMutuallyExclusiveGroup: true,
                semanticLabel: widget.semanticLabelBuilder(i),
                pressScale: 0.08,
                builder:
                    (BuildContext context, GlassInteractionState state, _) {
                      return AnimatedBuilder(
                        animation: _position,
                        builder: (BuildContext context, _) {
                          final double s = (1 - (_position.value - i).abs())
                              .clamp(0.0, 1.0);
                          return widget.itemBuilder(context, i, s);
                        },
                      );
                    },
              ),
            );
          }),
        );

        final Widget indicator = AnimatedBuilder(
          animation: _position,
          builder: (BuildContext context, _) {
            final double v = _position.value;
            final bool canStretch = !reduceMotion && (drop?.stretch ?? true);
            final double speed = canStretch ? _position.velocity.abs() : 0;
            final double stretch = math.min(0.4, speed * 0.05);
            final double logical = _rtl ? (widget.itemCount - 1 - v) : v;
            final EdgeInsets inset = widget.indicatorInset;
            final double fullH = constraints.maxHeight.isFinite
                ? constraints.maxHeight - inset.vertical
                : 0;
            final Size slot = Size(
              math.max(0, _itemWidth - inset.horizontal),
              math.max(0, fullH),
            );
            final Size base = drop?.resolveSize(slot) ?? slot;
            final double w = base.width * (1 + stretch);
            final double h = base.height * (1 - stretch * 0.18);
            final double centreX = (logical + 0.5) * _itemWidth;
            final BorderRadius radius =
                drop?.resolveRadius(Size(w, h)) ??
                widget.indicatorStyle.borderRadius;
            final LiquidGlassStyle style = drop == null
                ? widget.indicatorStyle
                : widget.indicatorStyle.copyWith(borderRadius: radius);
            final Widget Function(BorderRadius)? foreground =
                widget.indicatorForegroundBuilder;
            Widget lens = LiquidGlassSurface(
              style: style,
              quality: widget.indicatorQuality,
              child: foreground == null
                  ? null
                  : SizedBox.expand(child: foreground(radius)),
            );
            if (magnify && w > 0 && h > 0) {
              lens = Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  RawMagnifier(
                    size: Size(w, h),
                    magnificationScale: drop!.magnification,
                    decoration: MagnifierDecoration(
                      shape: RoundedRectangleBorder(borderRadius: radius),
                    ),
                  ),
                  lens,
                ],
              );
            }
            return Positioned(
              left: centreX - w / 2,
              top: inset.top + (fullH - h) / 2,
              width: w,
              height: h,
              child: IgnorePointer(child: lens),
            );
          },
        );

        Widget row = Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            indicator,
            Positioned.fill(child: items),
          ],
        );
        if (enabled && widget.enableDrag) {
          row = GestureDetector(
            behavior: HitTestBehavior.translucent,
            dragStartBehavior: DragStartBehavior.start,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            onHorizontalDragCancel: () {
              _dragging = false;
              _animateTo(widget.selectedIndex);
            },
            child: row,
          );
        }
        return Semantics(container: true, explicitChildNodes: true, child: row);
      },
    );
  }
}
