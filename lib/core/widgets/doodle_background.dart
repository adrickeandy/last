import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/app_colors.dart';

/// A soft, slowly drifting "doodle" wallpaper (hearts, stars, squiggles,
/// paper planes, graduation caps ...) in the style of a chat wallpaper.
///
/// Drop it behind any screen content:
///
/// ```dart
/// Stack(
///   fit: StackFit.expand,
///   children: [
///     const Positioned.fill(child: DoodleBackground()),
///     /* your content */
///   ],
/// )
/// ```
///
/// Design notes
/// - It is pointer-transparent and sits in its own [RepaintBoundary], so it
///   never steals taps and never forces the chat content to repaint.
/// - The pattern repeats every 5x5 cells and drifts by exactly one repeat per
///   loop, so the animation loops with no visible jump.
/// - Frames are throttled to ~30 fps and the animation stops by itself when the
///   widget is off screen (TickerMode) or the OS asks to reduce motion.
class DoodleBackground extends StatefulWidget {
  /// Set to false for a static wallpaper.
  final bool animate;

  /// Multiplier for the doodle strength (1 = default, 0 = invisible).
  final double intensity;

  const DoodleBackground({
    super.key,
    this.animate = true,
    this.intensity = 1.0,
  });

  @override
  State<DoodleBackground> createState() => _DoodleBackgroundState();
}

class _DoodleBackgroundState extends State<DoodleBackground>
    with SingleTickerProviderStateMixin {
  /// Seconds for the pattern to drift one full repeat.
  static const double _loopSeconds = 70;

  late final Ticker _ticker;
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);
  Duration _lastPaint = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant DoodleBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  void _syncTicker() {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldRun = widget.animate && !reduceMotion;
    if (shouldRun && !_ticker.isActive) {
      _lastPaint = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    // ~30 fps is plenty for a slow background and keeps low-end phones cool.
    if (elapsed - _lastPaint < const Duration(milliseconds: 33)) return;
    _lastPaint = elapsed;
    _progress.value = (elapsed.inMicroseconds / 1000000.0 / _loopSeconds) % 1.0;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _DoodlePainter(
            progress: _progress,
            isDark: isDark,
            intensity: widget.intensity,
          ),
        ),
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  _DoodlePainter({
    required this.progress,
    required this.isDark,
    required this.intensity,
  }) : super(repaint: progress);

  final ValueListenable<double> progress;
  final bool isDark;
  final double intensity;

  static const double _cell = 92;
  static const int _period = 5;
  static const double _tile = _cell * _period;
  static const double _stroke = 1.5;
  static const double _baseRadius = 13;

  static final List<Path> _shapes = _buildShapes();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final t = progress.value;
    final shift = t * _tile;

    final paints = <Paint>[
      _paint(isDark ? Colors.white : const Color(0xFF111827), isDark ? 0.055 : 0.055),
      _paint(isDark ? AppColors.violet400 : AppColors.violet600, isDark ? 0.14 : 0.12),
      _paint(isDark ? AppColors.coral400 : AppColors.coral500, isDark ? 0.10 : 0.10),
    ];

    final iStart = ((-_cell - shift) / _cell).floor();
    final iEnd = ((size.width + _cell - shift) / _cell).ceil();
    final jStart = ((-_cell - shift) / _cell).floor();
    final jEnd = ((size.height + _cell - shift) / _cell).ceil();

    for (var j = jStart; j <= jEnd; j++) {
      for (var i = iStart; i <= iEnd; i++) {
        // Dart's % is never negative for a positive divisor, so this wraps
        // the pattern cleanly in every direction.
        final h = _hash(i % _period, j % _period);
        if (h % 4 == 0) continue; // leave ~25% of the cells empty

        final path = _shapes[(h >> 3) % _shapes.length];
        final paintIndex = switch ((h >> 17) % 6) {
          0 => 1,
          1 => 2,
          _ => 0,
        };

        final jitterX = ((h >> 7) % 37) - 18.0;
        final jitterY = ((h >> 13) % 37) - 18.0;
        final baseRotation = (((h >> 19) % 100) / 100 - 0.5) * 1.2;
        final scale = 0.8 + ((h >> 5) % 41) / 100;
        final phase = ((h >> 11) % 100) / 100;

        // Whole-number multiples of t keep the loop seamless.
        final bob = math.sin(2 * math.pi * (t * 3 + phase)) * 3;
        final wobble = math.sin(2 * math.pi * (t * 6 + phase)) * 0.07;

        final cx = i * _cell + shift + _cell / 2 + jitterX;
        final cy = j * _cell + shift + _cell / 2 + jitterY + bob;
        final radius = _baseRadius * scale;

        final paint = paints[paintIndex]..strokeWidth = _stroke / radius;

        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(baseRotation + wobble);
        canvas.scale(radius);
        canvas.drawPath(path, paint);
        canvas.restore();
      }
    }
  }

  Paint _paint(Color color, double alpha) {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.withOpacity((alpha * intensity).clamp(0.0, 1.0));
  }

  static int _hash(int a, int b) {
    var h = (a * 73856093) ^ (b * 19349663);
    h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff;
    return (h ^ (h >> 16)) & 0x7fffffff;
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter old) =>
      old.isDark != isDark || old.intensity != intensity;

  // -------------------------------------------------------------------------
  // Doodle shapes, drawn in a unit space of roughly -1..1.
  // -------------------------------------------------------------------------
  static List<Path> _buildShapes() {
    final shapes = <Path>[];

    // 0. Heart
    shapes.add(Path()
      ..moveTo(0, 0.9)
      ..cubicTo(-1.2, 0.2, -1.1, -0.8, -0.5, -0.8)
      ..cubicTo(-0.2, -0.8, 0, -0.6, 0, -0.35)
      ..cubicTo(0, -0.6, 0.2, -0.8, 0.5, -0.8)
      ..cubicTo(1.1, -0.8, 1.2, 0.2, 0, 0.9));

    // 1. Star
    final star = Path();
    for (var k = 0; k < 10; k++) {
      final r = k.isEven ? 0.95 : 0.4;
      final a = -math.pi / 2 + k * math.pi / 5;
      final x = r * math.cos(a);
      final y = r * math.sin(a);
      if (k == 0) {
        star.moveTo(x, y);
      } else {
        star.lineTo(x, y);
      }
    }
    star.close();
    shapes.add(star);

    // 2. Squiggle
    shapes.add(Path()
      ..moveTo(-1, 0)
      ..quadraticBezierTo(-0.75, -0.7, -0.5, 0)
      ..quadraticBezierTo(-0.25, 0.7, 0, 0)
      ..quadraticBezierTo(0.25, -0.7, 0.5, 0)
      ..quadraticBezierTo(0.75, 0.7, 1, 0));

    // 3. Circle
    shapes.add(Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 0.7)));

    // 4. Plus
    shapes.add(Path()
      ..moveTo(-0.7, 0)
      ..lineTo(0.7, 0)
      ..moveTo(0, -0.7)
      ..lineTo(0, 0.7));

    // 5. Triangle
    shapes.add(Path()
      ..moveTo(0, -0.8)
      ..lineTo(0.85, 0.6)
      ..lineTo(-0.85, 0.6)
      ..close());

    // 6. Spiral
    final spiral = Path()..moveTo(0, 0);
    for (var s = 1; s <= 48; s++) {
      final a = s / 48 * 4 * math.pi;
      final r = s / 48 * 0.9;
      spiral.lineTo(r * math.cos(a), r * math.sin(a));
    }
    shapes.add(spiral);

    // 7. Speech bubble
    shapes.add(Path()
      ..addRRect(RRect.fromLTRBR(-0.9, -0.7, 0.9, 0.4, const Radius.circular(0.35)))
      ..moveTo(-0.35, 0.4)
      ..lineTo(-0.55, 0.88)
      ..lineTo(0.05, 0.4));

    // 8. Paper plane
    shapes.add(Path()
      ..moveTo(-0.95, -0.15)
      ..lineTo(0.95, -0.85)
      ..lineTo(0.3, 0.85)
      ..lineTo(-0.05, 0.15)
      ..close()
      ..moveTo(-0.05, 0.15)
      ..lineTo(0.95, -0.85));

    // 9. Smiley
    shapes.add(Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: 0.8))
      ..addOval(Rect.fromCircle(center: const Offset(-0.28, -0.2), radius: 0.06))
      ..addOval(Rect.fromCircle(center: const Offset(0.28, -0.2), radius: 0.06))
      ..arcTo(
        Rect.fromCircle(center: const Offset(0, 0.05), radius: 0.45),
        0.3,
        math.pi - 0.6,
        true,
      ));

    // 10. Music note
    shapes.add(Path()
      ..addOval(Rect.fromCircle(center: const Offset(-0.4, 0.6), radius: 0.3))
      ..moveTo(-0.1, 0.6)
      ..lineTo(-0.1, -0.8)
      ..cubicTo(0.3, -0.7, 0.6, -0.3, 0.5, 0.0));

    // 11. Lightning bolt
    shapes.add(Path()
      ..moveTo(0.2, -0.9)
      ..lineTo(-0.5, 0.1)
      ..lineTo(0, 0.1)
      ..lineTo(-0.2, 0.9)
      ..lineTo(0.5, -0.2)
      ..lineTo(0, -0.2)
      ..close());

    // 12. Cross
    shapes.add(Path()
      ..moveTo(-0.5, -0.5)
      ..lineTo(0.5, 0.5)
      ..moveTo(0.5, -0.5)
      ..lineTo(-0.5, 0.5));

    // 13. Three dots
    shapes.add(Path()
      ..addOval(Rect.fromCircle(center: const Offset(-0.6, 0), radius: 0.12))
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: 0.12))
      ..addOval(Rect.fromCircle(center: const Offset(0.6, 0), radius: 0.12)));

    // 14. Graduation cap (campus theme)
    shapes.add(Path()
      ..moveTo(0, -0.6)
      ..lineTo(1, -0.15)
      ..lineTo(0, 0.3)
      ..lineTo(-1, -0.15)
      ..close()
      ..moveTo(-0.55, 0.05)
      ..lineTo(-0.55, 0.55)
      ..quadraticBezierTo(0, 0.9, 0.55, 0.55)
      ..lineTo(0.55, 0.05));

    // 15. Book (campus theme)
    shapes.add(Path()
      ..addRRect(RRect.fromLTRBR(-0.85, -0.6, 0.85, 0.6, const Radius.circular(0.1)))
      ..moveTo(0, -0.6)
      ..lineTo(0, 0.6)
      ..moveTo(-0.55, -0.2)
      ..lineTo(-0.2, -0.2)
      ..moveTo(0.2, -0.2)
      ..lineTo(0.55, -0.2));

    return shapes;
  }
}
