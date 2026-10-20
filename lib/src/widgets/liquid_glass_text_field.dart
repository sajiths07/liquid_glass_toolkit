import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../animation/animation_config.dart';
import '../animation/liquid_glass_transitions.dart';
import '../core/glass_quality.dart';
import '../core/glass_style.dart';
import '../theme/liquid_glass_theme.dart';

/// A text field on a glass surface.
///
/// Built on [CupertinoTextField], so it works in both Material and Cupertino
/// apps and keeps platform text editing, selection, IME and accessibility
/// behaviour. Focus is shown by an animated accent border and brighter
/// glass.
class LiquidGlassTextField extends StatefulWidget {
  /// Creates a glass text field.
  const LiquidGlassTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.prefix,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.autofillHints,
    this.style,
    this.textStyle,
    this.quality,
    this.animation,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.foregroundColor,
    this.placeholderColor,
    this.cursorColor,
    this.focusColor,
  });

  /// Text, prefix and suffix color. [textStyle]'s color wins for the text.
  /// Defaults to the theme `foregroundColor`.
  final Color? foregroundColor;

  /// Placeholder color. Defaults to [foregroundColor] at 45% opacity.
  final Color? placeholderColor;

  /// Cursor color. Defaults to [focusColor], then the theme `accentColor`.
  final Color? cursorColor;

  /// Border color while focused. Defaults to the theme `accentColor`.
  final Color? focusColor;

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// Focus node.
  final FocusNode? focusNode;

  /// Hint shown when empty. Also used as the semantic label.
  final String? placeholder;

  /// Widget before the text (for example a search icon).
  final Widget? prefix;

  /// Widget after the text (for example a clear button).
  final Widget? suffix;

  /// Called on every change.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits.
  final ValueChanged<String>? onSubmitted;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Keyboard action button.
  final TextInputAction? textInputAction;

  /// Hides the text (passwords).
  final bool obscureText;

  /// Whether the field accepts input.
  final bool enabled;

  /// Whether to autofocus.
  final bool autofocus;

  /// Maximum lines.
  final int? maxLines;

  /// Minimum lines.
  final int? minLines;

  /// Input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Autofill hints.
  final Iterable<String>? autofillHints;

  /// Glass style. Defaults to the theme style with 16 px corners.
  final LiquidGlassStyle? style;

  /// Text style. Defaults to 16 px in the theme foreground color.
  final TextStyle? textStyle;

  /// Rendering quality.
  final LiquidGlassQuality? quality;

  /// Overrides the theme `animation` used for the focus transition.
  final LiquidGlassAnimationConfig? animation;

  /// Padding inside the glass.
  final EdgeInsetsGeometry padding;

  @override
  State<LiquidGlassTextField> createState() => _LiquidGlassTextFieldState();
}

class _LiquidGlassTextFieldState extends State<LiquidGlassTextField> {
  FocusNode? _ownedFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(LiquidGlassTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownedFocusNode)?.removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LiquidGlassThemeData theme = LiquidGlassTheme.of(context);
    final LiquidGlassStyle base =
        widget.style ??
        theme.style.copyWith(
          borderRadius: BorderRadius.circular(16),
          shadowBlur: 12,
          shadowOffset: const Offset(0, 4),
        );
    final bool focused = _focusNode.hasFocus;
    final Color focus = widget.focusColor ?? theme.accentColor;
    final LiquidGlassStyle effective = focused
        ? base.copyWith(
            borderColor: focus,
            borderWidth: base.borderWidth < 1.5 ? 1.5 : base.borderWidth,
            opacity: (base.opacity + 0.08).clamp(0.0, 1.0),
          )
        : base;
    final Color fg = widget.foregroundColor ?? theme.foregroundColor;
    return AnimatedLiquidGlassSurface(
      style: effective,
      quality: widget.quality,
      animation: widget.animation,
      foregroundColor: widget.enabled ? fg : fg.withValues(alpha: 0.45),
      child: CupertinoTextField(
        controller: widget.controller,
        focusNode: _focusNode,
        placeholder: widget.placeholder,
        prefix: widget.prefix == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(start: 12),
                child: widget.prefix,
              ),
        suffix: widget.suffix == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: widget.suffix,
              ),
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        obscureText: widget.obscureText,
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        minLines: widget.minLines,
        inputFormatters: widget.inputFormatters,
        autofillHints: widget.autofillHints,
        padding: widget.padding,
        decoration: null,
        cursorColor: widget.cursorColor ?? focus,
        style: (widget.textStyle ?? const TextStyle(fontSize: 16)).copyWith(
          color: widget.textStyle?.color ?? fg,
        ),
        placeholderStyle: TextStyle(
          fontSize: widget.textStyle?.fontSize ?? 16,
          color: widget.placeholderColor ?? fg.withValues(alpha: fg.a * 0.45),
        ),
      ),
    );
  }
}
