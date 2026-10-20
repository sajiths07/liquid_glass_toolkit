import 'package:flutter/widgets.dart';

import '../animation/animation_config.dart';
import '../core/glass_quality.dart';
import '../core/glass_style.dart';
import '../theme/liquid_glass_theme.dart';
import 'glass_selector.dart';
import 'liquid_glass_surface.dart';

/// A glass segmented control whose selection indicator glides between
/// segments with spring physics and stretches like liquid while moving.
///
/// The indicator can also be dragged. Each segment is exposed to screen
/// readers as a selectable button in a mutually exclusive group and is
/// keyboard focusable.
class LiquidGlassSegmentedControl<T extends Object> extends StatelessWidget {
  /// Creates a segmented control.
  ///
  /// [segments] maps each value to its visual label; iteration order defines
  /// the segment order. [selected] must be one of the keys.
  LiquidGlassSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.semanticLabels,
    this.style,
    this.indicatorStyle,
    this.quality,
    this.animation,
    this.height = 40,
    this.selectedColor,
    this.unselectedColor,
    this.selectedColors,
    this.unselectedColors,
    this.borderRadius,
  }) : assert(segments.length >= 2, 'Provide at least two segments'),
       assert(
         segments.containsKey(selected),
         'selected must be a key of segments',
       );

  /// Segment values and their labels.
  final Map<T, Widget> segments;

  /// The selected value.
  final T selected;

  /// Called when the user selects a different value. `null` disables the
  /// control.
  final ValueChanged<T>? onChanged;

  /// Optional screen-reader labels per value (useful for icon-only
  /// segments).
  final Map<T, String>? semanticLabels;

  /// Style of the outer glass track.
  final LiquidGlassStyle? style;

  /// Style of the sliding indicator.
  final LiquidGlassStyle? indicatorStyle;

  /// Quality of the outer track.
  final LiquidGlassQuality? quality;

  /// Overrides the theme `animation` for indicator movement.
  final LiquidGlassAnimationConfig? animation;

  /// Height of the control.
  final double height;

  /// Corner radius of the track and the indicator. Defaults to a pill
  /// (`height / 2`).
  final BorderRadius? borderRadius;

  /// Text and icon color of the selected segment, unless [selectedColors]
  /// has an entry for it. Defaults to the theme `foregroundColor`.
  final Color? selectedColor;

  /// Text and icon color of unselected segments, unless [unselectedColors]
  /// has an entry for them. Defaults to the theme `foregroundColor`.
  final Color? unselectedColor;

  /// Per-segment selected colors. Missing values fall back to
  /// [selectedColor].
  final Map<T, Color>? selectedColors;

  /// Per-segment unselected colors. Missing values fall back to
  /// [unselectedColor].
  final Map<T, Color>? unselectedColors;

  @override
  Widget build(BuildContext context) {
    final LiquidGlassThemeData theme = LiquidGlassTheme.of(context);
    final List<T> values = segments.keys.toList(growable: false);
    final BorderRadius pill = borderRadius ?? BorderRadius.circular(height / 2);
    final LiquidGlassStyle track = (style ?? theme.style).copyWith(
      borderRadius: pill,
    );
    final LiquidGlassStyle indicator =
        indicatorStyle ??
        track.copyWith(
          blur: 0,
          saturation: 1,
          brightness: 0,
          contrast: 1,
          opacity: (track.opacity + 0.45).clamp(0.0, 1.0),
          tintColor: track.tintColor,
          shadowBlur: 8,
          shadowOffset: const Offset(0, 2),
          borderRadius: pill,
        );
    final ValueChanged<T>? onChanged = this.onChanged;
    return SizedBox(
      height: height,
      child: LiquidGlassSurface(
        style: track,
        quality: quality,
        child: GlassSelectorRow(
          itemCount: values.length,
          selectedIndex: values.indexOf(selected),
          onSelected: onChanged == null
              ? null
              : (int i) => onChanged(values[i]),
          animation: animation,
          indicatorStyle: indicator,
          semanticLabelBuilder: (int i) => semanticLabels?[values[i]],
          itemBuilder: (BuildContext context, int i, double s) {
            final T value = values[i];
            final Color color = Color.lerp(
              unselectedColors?[value] ??
                  unselectedColor ??
                  theme.foregroundColor,
              selectedColors?[value] ?? selectedColor ?? theme.foregroundColor,
              s,
            )!;
            return Center(
              child: IconTheme.merge(
                data: IconThemeData(color: color),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: s > 0.5 ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: segments[value]!,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
