import 'package:flutter/material.dart';

import '../../core/fx.dart';
import 'liquid_glass.dart';

/// Floating iOS-26-style liquid glass tab bar.
///
/// The capsule and per-tab lighting are derived 1:1 from [currentIndex] —
/// there is no separate animation state that can fall out of sync — so a tap
/// or drop **always** lights the destination tab.
///
/// Interaction model:
///  * **Tap** a destination — the capsule glides to it and the page changes.
///  * **Press and hold** the bar, then slide — the glass capsule follows your
///    finger *inside the bar*; tabs light up as it travels. Release to snap
///    it onto a tab and open that page.
///  * **Swipe** quickly anywhere on the bar for a fast fling-switch.
class LiquidGlassNavBar extends StatefulWidget {
  final int currentIndex;

  /// In-laundry piece count (shown as a badge on the Laundry tab).
  final int laundryCount;

  final ValueChanged<int> onDestinationSelected;

  /// Ambient hue of the content behind the bar (see shell gradient).
  final Color tint;

  const LiquidGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.laundryCount,
    required this.onDestinationSelected,
    this.tint = Colors.transparent,
  });

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar>
    with TickerProviderStateMixin {
  static const int _count = 5;

  /// Slot width, captured from the latest layout (pixels per tab).
  double _slot = 1;

  /// Per-tab spring bump fired on selection.
  late final List<AnimationController> _bumps;
  late final List<CurvedAnimation> _curves;

  /// The capsule is being lifted and dragged (long-press).
  bool _dragging = false;
  int _dragOrigin = 0;
  double _dragDx = 0;

  /// A quick fling-swipe is moving the capsule across the bar.
  bool _swiping = false;
  double _swipeSlot = 0;

  /// Capsule position in slot units. At rest this is *exactly*
  /// [widget.currentIndex]; during a drag/swipe it rides the finger.
  double get _slotPosition {
    if (_dragging) {
      return (widget.currentIndex + _dragDx / _slot)
          .clamp(0.0, _count - 1.0)
          .toDouble();
    }
    if (_swiping) return _swipeSlot.clamp(0.0, _count - 1.0).toDouble();
    return widget.currentIndex.toDouble();
  }

  @override
  void initState() {
    super.initState();
    _bumps = List.generate(
      _count,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
    _curves = _bumps
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutBack))
        .toList();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _bumps[widget.currentIndex].forward(from: 0);
    }
  }

  @override
  void dispose() {
    for (final b in _bumps) {
      b.dispose();
    }
    super.dispose();
  }

  // ---- Tap -------------------------------------------------------------
  void _onTap(int index) {
    if (index == widget.currentIndex) {
      _bumps[index].forward(from: 0);
      return;
    }
    Fx.tone(FxTone.tap);
    Fx.light();
    widget.onDestinationSelected(index);
  }

  // ---- Bar-level swipe (quick fling) -----------------------------------
  void _onSwipeStart(DragStartDetails details) {
    setState(() {
      _swiping = true;
      _swipeSlot = widget.currentIndex.toDouble();
    });
  }

  void _onSwipeUpdate(DragUpdateDetails details) {
    setState(() {
      _swipeSlot -= details.delta.dx / _slot;
    });
  }

  void _onSwipeEnd(DragEndDetails details) {
    final vx = details.velocity.pixelsPerSecond.dx;
    var target = _swipeSlot.round();
    if (vx.abs() > 350) {
      target += vx > 0 ? 1 : -1;
    }
    target = target.clamp(0, _count - 1);

    final commit = target != widget.currentIndex;
    setState(() => _swiping = false);

    if (commit) {
      Fx.tone(FxTone.swish);
      Fx.medium();
      widget.onDestinationSelected(target);
    } else {
      Fx.tone(FxTone.tap);
      Fx.light();
    }
  }

  // ---- Long-press: lift & drag the capsule inside the bar ---------------
  void _startDrag(int index) {
    Fx.tone(FxTone.whoosh);
    Fx.medium();
    setState(() {
      _dragging = true;
      _dragOrigin = index;
      _dragDx = 0;
    });
  }

  void _dragMove(Offset offsetFromOrigin) {
    final prev = (_dragOrigin + (_dragDx / _slot).round()).clamp(0, _count - 1);
    final dx = offsetFromOrigin.dx;
    final next = (_dragOrigin + (dx / _slot).round()).clamp(0, _count - 1);
    setState(() => _dragDx = dx);
    if (next != prev) {
      Fx.light();
    }
  }

  void _dropDrag() {
    final target =
        (_dragOrigin + (_dragDx / _slot).round()).clamp(0, _count - 1);
    final commit = target != widget.currentIndex;

    if (commit) {
      Fx.tone(FxTone.swish);
      Fx.medium();
      // Navigate before releasing the drag so the capsule glides straight to
      // the newly selected index in the same build.
      widget.onDestinationSelected(target);
    } else {
      Fx.tone(FxTone.tap);
      Fx.light();
    }
    setState(() {
      _dragging = false;
      _dragDx = 0;
    });
    if (!commit) {
      _bumps[widget.currentIndex].forward(from: 0);
    }
  }

  void _cancelDrag() {
    setState(() {
      _dragging = false;
      _dragDx = 0;
    });
    Fx.tone(FxTone.pop);
    Fx.light();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: SizedBox(
        height: 64,
        child: LiquidGlassContainer(
          tint: widget.tint,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _slot = constraints.maxWidth / _count;
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: _onSwipeStart,
                onHorizontalDragUpdate: _onSwipeUpdate,
                onHorizontalDragEnd: _onSwipeEnd,
                child: Stack(
                  children: [
                    _FocusCapsule(
                      left: _slotPosition * _slot,
                      slotWidth: _slot,
                      animDuration: _dragging || _swiping
                          ? Duration.zero
                          : const Duration(milliseconds: 280),
                    ),
                    Positioned.fill(
                      child: Row(
                        children: List.generate(
                          _count,
                          (i) => Expanded(child: _buildTab(i)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index) {
    final scheme = Theme.of(context).colorScheme;
    final focus = (1 - (index - _slotPosition).abs()).clamp(0.0, 1.0);

    final commissioned = widget.currentIndex == index;
    final muted = scheme.onSurface.withValues(alpha: 0.5);
    final iconColor = Color.lerp(muted, scheme.primary, focus)!;
    final labelColor = Color.lerp(
      scheme.onSurface.withValues(alpha: 0.45),
      scheme.onSurface,
      focus,
    )!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTap(index),
      onLongPressStart: (_) => _startDrag(index),
      onLongPressMoveUpdate: (d) => _dragMove(d.offsetFromOrigin),
      onLongPressEnd: (_) => _dropDrag(),
      onLongPressCancel: () => _cancelDrag(),
      child: Semantics(
        button: true,
        selected: commissioned,
        label: _labelFor(index),
        child: AnimatedScale(
          scale: focus > 0.72 ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.10).animate(_curves[index]),
                child: IconTheme(
                  data: IconThemeData(color: iconColor),
                  child: _iconFor(index, commissioned),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 120),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
                child: Text(_labelFor(index)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconFor(int index, bool selected) {
    final Widget icon = switch (index) {
      0 => Icon(selected ? Icons.home : Icons.home_outlined, size: 24),
      1 => Icon(
          selected ? Icons.checkroom : Icons.checkroom_outlined,
          size: 24,
        ),
      2 => Icon(
          selected ? Icons.add_circle : Icons.add_circle_outline,
          size: 27,
        ),
      3 => Icon(
          selected
              ? Icons.local_laundry_service
              : Icons.local_laundry_service_outlined,
          size: 24,
        ),
      _ => const Icon(Icons.tune, size: 24),
    };
    if (index == 3) {
      return Badge(
        isLabelVisible: widget.laundryCount > 0,
        label: Text('${widget.laundryCount}'),
        child: icon,
      );
    }
    return icon;
  }

  String _labelFor(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Wardrobe';
      case 2:
        return 'Add';
      case 3:
        return 'Laundry';
      default:
        return 'Settings';
    }
  }
}

/// The glowing capsule that sits behind the focused tab.
///
/// [animDuration] zeroes out during an active drag so it tracks the finger
/// exactly, then re-enables for the glide back to [currentIndex] when the
/// drag ends — guaranteeing it always lands on the *selected* tab.
class _FocusCapsule extends StatelessWidget {
  final double left;
  final double slotWidth;
  final Duration animDuration;

  const _FocusCapsule({
    required this.left,
    required this.slotWidth,
    required this.animDuration,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedPositioned(
      left: left + 10,
      top: 6,
      width: slotWidth - 20,
      height: 34,
      duration: animDuration,
      curve: Curves.easeOutCubic,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: isDark ? 0.16 : 0.26),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: scheme.primary.withValues(alpha: isDark ? 0.30 : 0.40),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: isDark ? 0.30 : 0.25),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}