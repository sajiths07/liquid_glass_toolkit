import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../animation/animation_config.dart';
import '../theme/liquid_glass_theme.dart';

/// Visual state passed to [GlassPressable.builder].
@immutable
class GlassInteractionState {
  /// Creates an interaction state.
  const GlassInteractionState({
    required this.press,
    required this.focused,
    required this.hovered,
    required this.enabled,
  });

  /// Press depth. `0` at rest, `1` fully pressed; may briefly leave that
  /// range when a spring overshoots.
  final double press;

  /// Whether keyboard focus highlight should be shown.
  final bool focused;

  /// Whether a pointer hovers the control.
  final bool hovered;

  /// Whether the control accepts input.
  final bool enabled;
}

/// Internal interaction primitive: tap, long press, keyboard activation,
/// focus/hover tracking, button semantics and spring press feedback.
class GlassPressable extends StatefulWidget {
  /// Creates a pressable region.
  const GlassPressable({
    super.key,
    required this.builder,
    required this.onPressed,
    this.onLongPress,
    this.animation,
    this.pressScale = 0.06,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.tooltip,
    this.selected,
    this.inMutuallyExclusiveGroup,
    this.isButton = true,
    this.mouseCursor,
    this.child,
  });

  /// Whether this control is one of a set of mutually exclusive options.
  final bool? inMutuallyExclusiveGroup;

  /// Builds the visuals for the current interaction state.
  final Widget Function(
    BuildContext context,
    GlassInteractionState state,
    Widget? child,
  )
  builder;

  /// Called on tap or keyboard activation. `null` disables the control.
  final VoidCallback? onPressed;

  /// Called on long press.
  final VoidCallback? onLongPress;

  /// Overrides the theme `interactionAnimation`.
  final LiquidGlassAnimationConfig? animation;

  /// How much the control shrinks when fully pressed (`0.06` = 6%).
  final double pressScale;

  /// Focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  /// Semantic label (used when the visual child has no text).
  final String? semanticLabel;

  /// Semantic hint describing the action.
  final String? tooltip;

  /// Selected state for semantics, if applicable.
  final bool? selected;

  /// Whether to expose button semantics.
  final bool isButton;

  /// Mouse cursor. Defaults to a click cursor when enabled.
  final MouseCursor? mouseCursor;

  /// Static child forwarded to [builder].
  final Widget? child;

  @override
  State<GlassPressable> createState() => _GlassPressableState();
}

class _GlassPressableState extends State<GlassPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );
  bool _focused = false;
  bool _hovered = false;
  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  LiquidGlassAnimationConfig _config() {
    return (widget.animation ??
            LiquidGlassTheme.of(context).interactionAnimation)
        .resolve(reduceMotion: LiquidGlassTheme.reduceMotionOf(context));
  }

  void _animateTo(double target) {
    _config().drive(_press, target, velocity: _press.velocity);
  }

  void _handleDown(TapDownDetails details) {
    if (!_enabled) return;
    _down = true;
    _animateTo(1);
  }

  void _handleUp() {
    if (!_down) return;
    _down = false;
    _animateTo(0);
  }

  void _activate() {
    if (!_enabled) return;
    widget.onPressed!();
    // Keyboard activation: brief press pulse so the action is visible.
    _press.value = 0.6;
    _animateTo(0);
  }

  @override
  void didUpdateWidget(GlassPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && _down) {
      _down = false;
      _press.value = 0;
    }
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = _enabled;
    final bool reduceMotion = LiquidGlassTheme.reduceMotionOf(context);
    final Widget visual = AnimatedBuilder(
      animation: _press,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double press = _press.value;
        final double scale = reduceMotion ? 1 : 1 - widget.pressScale * press;
        return Transform.scale(
          scale: scale,
          child: widget.builder(
            context,
            GlassInteractionState(
              press: press,
              focused: _focused,
              hovered: _hovered,
              enabled: enabled,
            ),
            child,
          ),
        );
      },
    );

    return Semantics(
      container: true,
      button: widget.isButton,
      enabled: enabled,
      selected: widget.selected,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup,
      label: widget.semanticLabel,
      hint: widget.tooltip,
      onTap: enabled ? widget.onPressed : null,
      onLongPress: widget.onLongPress,
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor:
            widget.mouseCursor ??
            (enabled ? SystemMouseCursors.click : SystemMouseCursors.basic),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (bool v) => setState(() => _focused = v),
        onShowHoverHighlight: (bool v) => setState(() => _hovered = v),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: enabled ? _handleDown : null,
          onTapUp: enabled ? (_) => _handleUp() : null,
          onTapCancel: enabled ? _handleUp : null,
          onTap: widget.onPressed,
          onLongPress: widget.onLongPress,
          dragStartBehavior: DragStartBehavior.down,
          child: visual,
        ),
      ),
    );
  }
}
