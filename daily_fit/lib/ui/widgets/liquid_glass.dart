import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

/// iOS-26-style liquid glass surface: strong backdrop blur, translucent
/// wash, an ambient [tint] pulled from the content behind it, a specular
/// highlight and an optional slow diagonal shine sweep.
class LiquidGlassContainer extends StatefulWidget {
  final Widget child;

  /// Ambient hue of the surrounding content, blended into the glass wash.
  final Color tint;

  final double borderRadius;

  /// When true (and the OS allows animations), a faint diagonal shine
  /// periodically sweeps across the surface.
  final bool animateShine;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    required this.tint,
    this.borderRadius = 28,
    this.animateShine = true,
  });

  @override
  State<LiquidGlassContainer> createState() => _LiquidGlassContainerState();
}

class _LiquidGlassContainerState extends State<LiquidGlassContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _phase;
  Timer? _timer;
  late bool _animationsOk;

  @override
  void initState() {
    super.initState();
    _phase = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _animationsOk = widget.animateShine;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animateShine != widget.animateShine) {
      _syncAnimationState();
    }
  }

  void _syncAnimationState() {
    _animationsOk =
        widget.animateShine && !MediaQuery.disableAnimationsOf(context);
    _timer?.cancel();
    _timer = null;
    _phase.stop();
    if (_animationsOk) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (mounted) _phase.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final wash = isDark
        ? [Colors.white.withValues(alpha: 0.14), Colors.white.withValues(alpha: 0.06)]
        : [Colors.white.withValues(alpha: 0.5), Colors.white.withValues(alpha: 0.24)];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
          child: RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: wash,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.tint.withValues(
                        alpha: isDark ? 0.10 : 0.06,
                      ),
                    ),
                  ),
                ),
                CustomPaint(
                  painter: _LiquidGlassPainter(
                    phase: _animationsOk ? _phase.value : null,
                    repaint: _animationsOk ? _phase : null,
                  ),
                ),
                Positioned.fill(child: widget.child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Static top-edge sheen plus an optional animated diagonal shine band.
class _LiquidGlassPainter extends CustomPainter {
  /// 0..1 sweep position, or null for a static-only finish.
  final double? phase;

  _LiquidGlassPainter({this.phase, super.repaint});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Soft top-edge highlight.
    final sheen = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5],
      ).createShader(rect);
    canvas.drawRect(rect, sheen);

    // Subtle bottom depth.
    final depth = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.black.withValues(alpha: 0.10),
          Colors.black.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.35],
      ).createShader(rect);
    canvas.drawRect(rect, depth);

    final t = phase;
    if (t == null) return;

    // Diagonal shine band gliding left -> right.
    final band = size.width * 0.7;
    final cx = t * (size.width + band) - band / 2;
    final bandRect = Rect.fromLTRB(
      cx - band / 2,
      0,
      cx + band / 2,
      size.height,
    );
    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.09),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(-0.22),
      ).createShader(bandRect);
    canvas.drawRect(bandRect, bandPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassPainter old) =>
      old.phase != phase;
}