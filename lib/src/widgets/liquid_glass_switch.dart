import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../animation/animation_config.dart';
import '../core/glass_quality.dart';
import '../core/glass_style.dart';
import '../theme/liquid_glass_theme.dart';
import 'liquid_glass_surface.dart';

/// Style of the thumb ("lens") shared by the switch and the slider.
///
/// At rest the thumb is a bright, mostly opaque pill. While [press] goes to
/// `1` it turns into clear glass so the track shows through, mimicking a
/// lens being picked up.
LiquidGlassStyle glassThumbStyle(
  BorderRadius radius,
  double press, {
  Color color = const Color(0xFFFFFFFF),
}) {
  final double p = press.clamp(0.0, 1.0);
  return LiquidGlassStyle(
    blur: 0,
    opacity: 0.97 - 0.75 * p,
    tintColor: color,
    saturation: 1,
    borderColor: Color.fromRGBO(255, 255, 255, 0.6 + 0.3 * p),
    highlightOpacity: 0.5 + 0.5 * p,
    rimLightIntensity: 0.4 + 0.6 * p,
    specularIntensity: 0.3 + 0.5 * p,
    thickness: 8,
    shadowColor: Color.fromRGBO(0, 0, 0, 0.22 - 0.1 * p),
    shadowBlur: 6,
    shadowOffset: const Offset(0, 2),
    borderRadius: radius,
  );
}

/// A glass toggle switch.
///
/// The thumb moves with spring physics, can be dragged, stretches while
/// pressed and turns into clear glass. Supports keyboard toggling
/// (Enter/Space), focus highlight and `toggled` semantics.
class LiquidGlassSwitch extends StatefulWidget {
  /// Creates a switch.
  const LiquidGlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.semanticLabel,
    this.animation,
    this.quality,
    this.focusNode,
    this.autofocus = false,
  });

  /// Whether the switch is on.
  final bool value;

  /// Called with the new value. `null` disables the switch.
  final ValueChanged<bool>? onChanged;

  /// Track color when on. Defaults to the theme accent.
  final Color? activeColor;

  /// Tint of the track when off. Defaults to the theme `foregroundColor`
  /// (drawn at low opacity).
  final Color? inactiveColor;

  /// Thumb color at rest. Defaults to white.
  final Color? thumbColor;

  /// Screen-reader label.
  final String? semanticLabel;

  /// Overrides the theme `animation` for thumb movement.
  final LiquidGlassAnimationConfig? animation;

  /// Quality of the track surface.
  final LiquidGlassQuality? quality;

  /// Focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus.
  final bool autofocus;

  @override
  State<LiquidGlassSwitch> createState() => _LiquidGlassSwitchState();
}

class _LiquidGlassSwitchState extends State<LiquidGlassSwitch>
    with TickerProviderStateMixin {
  static const double _width = 56;
  static const double _height = 32;
  static const double _thumb = 26;
  static const double _inset = 3;
  static const double _travel = _width - _thumb - _inset * 2;

  late final AnimationController _position = AnimationController.unbounded(
    vsync: this,
    value: widget.value ? 1 : 0,
  );
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );
  bool _focused = false;
  bool _dragging = false;

  bool get _enabled => widget.onChanged != null;

  LiquidGlassAnimationConfig _config(LiquidGlassAnimationConfig? override) =>
      (override ?? LiquidGlassTheme.of(context).animation).resolve(
        reduceMotion: LiquidGlassTheme.reduceMotionOf(context),
      );

  void _moveTo(bool on, {double velocity = 0}) {
    _config(widget.animation).drive(_position, on ? 1 : 0, velocity: velocity);
  }

  void _pressTo(double v) {
    _config(
      LiquidGlassTheme.of(context).interactionAnimation,
    ).drive(_press, v, velocity: _press.velocity);
  }

  @override
  void didUpdateWidget(LiquidGlassSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_dragging) {
      _moveTo(widget.value, velocity: _position.velocity);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    _press.dispose();
    super.dispose();
  }

  void _commit(bool next, {double velocity = 0}) {
    if (next != widget.value) widget.onChanged?.call(next);
    _moveTo(next, velocity: velocity);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_dragging && widget.value != next) {
        _moveTo(widget.value, velocity: _position.velocity);
      }
    });
  }

  void _toggle() {
    if (!_enabled) return;
    _commit(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final LiquidGlassThemeData theme = LiquidGlassTheme.of(context);
    final bool reduceMotion = LiquidGlassTheme.reduceMotionOf(context);
    final Color active = widget.activeColor ?? theme.accentColor;
    final LiquidGlassStyle base = theme.style.copyWith(
      borderRadius: BorderRadius.circular(_height / 2),
      shadowBlur: 0,
      shadowOffset: Offset.zero,
    );
    final LiquidGlassStyle offStyle = base.copyWith(
      tintColor: widget.inactiveColor ?? theme.foregroundColor,
      opacity: 0.14,
    );
    final LiquidGlassStyle onStyle = base.copyWith(
      tintColor: active,
      opacity: 0.92,
    );

    final Widget visual = AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_position, _press]),
      builder: (BuildContext context, _) {
        final double pos = _position.value;
        final double p = reduceMotion ? 0 : _press.value;
        final double stretch = 8 * p.clamp(0.0, 1.2);
        final double thumbW = _thumb + stretch;
        final bool rtl = Directionality.maybeOf(context) == TextDirection.rtl;
        final double logical = rtl ? 1 - pos : pos;
        final double left =
            _inset + logical * _travel - stretch * logical.clamp(0.0, 1.0);
        LiquidGlassStyle track = LiquidGlassStyle.lerp(
          offStyle,
          onStyle,
          pos.clamp(0.0, 1.0),
        );
        if (_focused) {
          track = track.copyWith(borderColor: active, borderWidth: 2);
        }
        return SizedBox(
          width: _width,
          height: _height,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: LiquidGlassSurface(
                  style: track,
                  quality: widget.quality,
                ),
              ),
              Positioned(
                left: left,
                top: _inset - p.clamp(0.0, 1.0) * 2,
                width: thumbW,
                height: _thumb + p.clamp(0.0, 1.0) * 4,
                child: LiquidGlassSurface(
                  style: glassThumbStyle(
                    BorderRadius.circular(_thumb),
                    p,
                    color: widget.thumbColor ?? const Color(0xFFFFFFFF),
                  ),
                  quality: LiquidGlassQuality.standard,
                ),
              ),
            ],
          ),
        );
      },
    );

    return Semantics(
      container: true,
      toggled: widget.value,
      enabled: _enabled,
      label: widget.semanticLabel,
      onTap: _enabled ? _toggle : null,
      child: FocusableActionDetector(
        enabled: _enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _toggle();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (bool v) => setState(() => _focused = v),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: _enabled ? (_) => _pressTo(1) : null,
          onTapCancel: _enabled ? () => _pressTo(0) : null,
          onTapUp: _enabled ? (_) => _pressTo(0) : null,
          onTap: _enabled ? _toggle : null,
          onHorizontalDragStart: _enabled
              ? (_) {
                  _dragging = true;
                  _position.stop();
                  _pressTo(1);
                }
              : null,
          onHorizontalDragUpdate: _enabled
              ? (DragUpdateDetails d) {
                  final bool rtl =
                      Directionality.maybeOf(context) == TextDirection.rtl;
                  final double delta = d.primaryDelta! / _travel;
                  _position.value = (_position.value + (rtl ? -delta : delta))
                      .clamp(-0.15, 1.15);
                }
              : null,
          onHorizontalDragEnd: _enabled
              ? (DragEndDetails d) {
                  _dragging = false;
                  _pressTo(0);
                  final bool rtl =
                      Directionality.maybeOf(context) == TextDirection.rtl;
                  final double v =
                      (d.primaryVelocity ?? 0) / _travel * (rtl ? -1 : 1);
                  final bool next = v.abs() > 3 ? v > 0 : _position.value > 0.5;
                  _commit(next, velocity: v);
                }
              : null,
          onHorizontalDragCancel: _enabled
              ? () {
                  _dragging = false;
                  _pressTo(0);
                  _moveTo(widget.value);
                }
              : null,
          child: Padding(
            // Pads the 32 px tall control to a 48 px touch target.
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Opacity(opacity: _enabled ? 1 : 0.45, child: visual),
          ),
        ),
      ),
    );
  }
}

/// A glass slider with a lens-like thumb that enlarges and clears while
/// dragged.
///
/// Supports tapping the track, dragging, [divisions], arrow-key adjustment,
/// right-to-left layouts and slider semantics (increase/decrease actions).
class LiquidGlassSlider extends StatefulWidget {
  /// Creates a slider.
  const LiquidGlassSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.onChangeStart,
    this.onChangeEnd,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.semanticLabel,
    this.semanticFormatter,
    this.quality,
    this.focusNode,
    this.autofocus = false,
  }) : assert(max > min, 'max must be greater than min'),
       assert(divisions == null || divisions > 0);

  /// Current value, between [min] and [max].
  final double value;

  /// Called while the value changes. `null` disables the slider.
  final ValueChanged<double>? onChanged;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Number of discrete steps, or `null` for a continuous slider.
  final int? divisions;

  /// Called when the user starts changing the value.
  final ValueChanged<double>? onChangeStart;

  /// Called when the user finishes changing the value.
  final ValueChanged<double>? onChangeEnd;

  /// Fill color of the active track. Defaults to the theme accent.
  final Color? activeColor;

  /// Tint of the inactive track. Defaults to the theme `foregroundColor`
  /// (drawn at low opacity).
  final Color? inactiveColor;

  /// Thumb color at rest. Defaults to white.
  final Color? thumbColor;

  /// Screen-reader label.
  final String? semanticLabel;

  /// Formats the value for screen readers. Defaults to a percentage.
  final String Function(double value)? semanticFormatter;

  /// Quality of the track surface.
  final LiquidGlassQuality? quality;

  /// Focus node.
  final FocusNode? focusNode;

  /// Whether to autofocus.
  final bool autofocus;

  @override
  State<LiquidGlassSlider> createState() => _LiquidGlassSliderState();
}

class _LiquidGlassSliderState extends State<LiquidGlassSlider>
    with SingleTickerProviderStateMixin {
  static const double _height = 44;
  static const double _trackHeight = 8;
  static const double _thumbW = 34;
  static const double _thumbH = 24;

  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );
  bool _focused = false;
  bool _active = false;

  bool get _enabled => widget.onChanged != null;

  double get _fraction {
    final double f = (widget.value - widget.min) / (widget.max - widget.min);
    return f.isFinite ? f.clamp(0.0, 1.0) : 0;
  }

  double _valueFor(double fraction) {
    double f = fraction.clamp(0.0, 1.0);
    final int? divisions = widget.divisions;
    if (divisions != null) f = (f * divisions).round() / divisions;
    return widget.min + f * (widget.max - widget.min);
  }

  double get _step {
    final int? divisions = widget.divisions;
    return divisions != null ? 1 / divisions : 0.05;
  }

  void _pressTo(double v) {
    (LiquidGlassTheme.of(context).interactionAnimation)
        .resolve(reduceMotion: LiquidGlassTheme.reduceMotionOf(context))
        .drive(_press, v, velocity: _press.velocity);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  double _fractionFromLocal(Offset local, double width) {
    final double usable = math.max(1, width - _thumbW);
    double f = (local.dx - _thumbW / 2) / usable;
    if (Directionality.maybeOf(context) == TextDirection.rtl) f = 1 - f;
    return f;
  }

  void _start(Offset local, double width) {
    if (!_enabled) return;
    _active = true;
    widget.onChangeStart?.call(widget.value);
    _pressTo(1);
    _update(local, width);
  }

  void _update(Offset local, double width) {
    if (!_enabled || !_active) return;
    final double next = _valueFor(_fractionFromLocal(local, width));
    if (next != widget.value) widget.onChanged!(next);
  }

  void _end() {
    if (!_active) return;
    _active = false;
    _pressTo(0);
    widget.onChangeEnd?.call(widget.value);
  }

  void _nudge(double direction) {
    if (!_enabled) return;
    final double next = _valueFor(_fraction + _step * direction);
    if (next == widget.value) return;
    widget.onChangeStart?.call(widget.value);
    widget.onChanged!(next);
    widget.onChangeEnd?.call(next);
  }

  String _format(double v) {
    final String Function(double)? f = widget.semanticFormatter;
    if (f != null) return f(v);
    final double fraction = (v - widget.min) / (widget.max - widget.min);
    return '${(fraction * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final LiquidGlassThemeData theme = LiquidGlassTheme.of(context);
    final bool reduceMotion = LiquidGlassTheme.reduceMotionOf(context);
    final Color active = widget.activeColor ?? theme.accentColor;
    final bool rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final LiquidGlassStyle trackStyle = theme.style.copyWith(
      borderRadius: BorderRadius.circular(_trackHeight / 2),
      thickness: 3,
      shadowBlur: 0,
      shadowOffset: Offset.zero,
      tintColor: widget.inactiveColor ?? theme.foregroundColor,
      opacity: 0.12,
      borderColor: _focused ? active : null,
      borderWidth: _focused ? 2 : null,
    );

    final Widget slider = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 200;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: (TapDownDetails d) => _start(d.localPosition, width),
          onTapUp: (_) => _end(),
          onTapCancel: () {
            if (_active) _end();
          },
          onHorizontalDragStart: (DragStartDetails d) {
            if (!_active) _start(d.localPosition, width);
          },
          onHorizontalDragUpdate: (DragUpdateDetails d) =>
              _update(d.localPosition, width),
          onHorizontalDragEnd: (_) => _end(),
          onHorizontalDragCancel: _end,
          child: SizedBox(
            width: width,
            height: _height,
            child: AnimatedBuilder(
              animation: _press,
              builder: (BuildContext context, _) {
                final double p = reduceMotion ? 0 : _press.value;
                final double scale = 1 + 0.3 * p.clamp(-0.2, 1.2);
                final double f = _fraction;
                final double usable = math.max(0, width - _thumbW);
                final double thumbCentre =
                    _thumbW / 2 + (rtl ? 1 - f : f) * usable;
                final double fillWidth = rtl
                    ? width - thumbCentre
                    : thumbCentre;
                return Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned(
                      left: 0,
                      right: 0,
                      top: (_height - _trackHeight) / 2,
                      height: _trackHeight,
                      child: LiquidGlassSurface(
                        style: trackStyle,
                        quality: widget.quality,
                      ),
                    ),
                    Positioned(
                      left: rtl ? thumbCentre : 0,
                      width: fillWidth,
                      top: (_height - _trackHeight) / 2,
                      height: _trackHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: active,
                          borderRadius: BorderRadius.circular(_trackHeight / 2),
                        ),
                      ),
                    ),
                    Positioned(
                      left: thumbCentre - _thumbW * scale / 2,
                      top: (_height - _thumbH * scale) / 2,
                      width: _thumbW * scale,
                      height: _thumbH * scale,
                      child: LiquidGlassSurface(
                        style: glassThumbStyle(
                          BorderRadius.circular(_thumbH * scale / 2),
                          p,
                          color: widget.thumbColor ?? const Color(0xFFFFFFFF),
                        ),
                        quality: LiquidGlassQuality.standard,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    final double up = _valueFor(_fraction + _step);
    final double down = _valueFor(_fraction - _step);
    return Semantics(
      container: true,
      slider: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      value: _format(widget.value),
      increasedValue: _format(up),
      decreasedValue: _format(down),
      onIncrease: _enabled && up != widget.value ? () => _nudge(1) : null,
      onDecrease: _enabled && down != widget.value ? () => _nudge(-1) : null,
      child: FocusableActionDetector(
        enabled: _enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.arrowRight):
              _SliderNudgeIntent(rtl ? -1 : 1),
          const SingleActivator(LogicalKeyboardKey.arrowLeft):
              _SliderNudgeIntent(rtl ? 1 : -1),
          const SingleActivator(LogicalKeyboardKey.arrowUp):
              const _SliderNudgeIntent(1),
          const SingleActivator(LogicalKeyboardKey.arrowDown):
              const _SliderNudgeIntent(-1),
        },
        actions: <Type, Action<Intent>>{
          _SliderNudgeIntent: CallbackAction<_SliderNudgeIntent>(
            onInvoke: (_SliderNudgeIntent intent) {
              _nudge(intent.direction);
              return null;
            },
          ),
        },
        onShowFocusHighlight: (bool v) => setState(() => _focused = v),
        child: Opacity(opacity: _enabled ? 1 : 0.45, child: slider),
      ),
    );
  }
}

class _SliderNudgeIntent extends Intent {
  const _SliderNudgeIntent(this.direction);

  final double direction;
}
