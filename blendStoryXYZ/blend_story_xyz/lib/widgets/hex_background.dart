import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/blend_theme.dart';

class HexBackground extends StatefulWidget {
  final Widget child;
  const HexBackground({super.key, required this.child});
  @override State<HexBackground> createState() => _HexBackgroundState();
}

class _HexBackgroundState extends State<HexBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Offset? _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))..repeat();
    // auto-pulse
    Future.delayed(const Duration(seconds: 2), _autoPulse);
  }

  void _autoPulse() {
    if (!mounted) return;
    final rng = math.Random();
    final size = MediaQuery.sizeOf(context);
    setState(() => _pulse = Offset(
      rng.nextDouble() * size.width,
      rng.nextDouble() * size.height,
    ));
    final delay = Duration(milliseconds: 3500 + rng.nextInt(4000));
    Future.delayed(delay, _autoPulse);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (d) => setState(() => _pulse = d.globalPosition),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _HexPainter(_ctrl.value, _pulse),
              size: Size.infinite,
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  final double t;
  final Offset? pulse;
  _HexPainter(this.t, this.pulse);

  static const _r = 18.0;
  static const _colors = [
    BlendTheme.gold,
    BlendTheme.goldE,
    BlendTheme.crimson,
    BlendTheme.verd,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rng  = math.Random(7);
    final h    = _r * math.sqrt(3);
    final cols = (size.width  / (_r * 1.5)).ceil() + 2;
    final rows = (size.height / h).ceil() + 2;

    for (var col = -1; col < cols; col++) {
      for (var row = -1; row < rows; row++) {
        final cx = col * _r * 1.5;
        final cy = row * h + (col.isOdd ? h / 2 : 0);
        final path = _hexPath(cx, cy);
        double wave = 0;
        if (pulse != null) {
          final d = (Offset(cx, cy) - pulse!).distance;
          wave = math.max(0, 1 - d / 180) *
              math.sin((t * math.pi * 2) - d / 30).clamp(0, 1);
        }
        final baseAlpha = rng.nextDouble() * 0.06 + 0.01;
        final alpha     = (baseAlpha + wave * 0.25).clamp(0.0, 0.35);
        final c         = _colors[rng.nextInt(_colors.length)];
        canvas.drawPath(path, Paint()
          ..color = c.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6);
      }
    }
  }

  Path _hexPath(double cx, double cy) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i - 30);
      final x = cx + _r * math.cos(angle);
      final y = cy + _r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_HexPainter old) => old.t != t || old.pulse != pulse;
}
