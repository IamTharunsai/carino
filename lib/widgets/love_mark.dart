import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Cariño's signature: a hand-drawn heart in one continuous line, with a
/// little looping tail — like a heart doodled in the margin of a letter.
class LoveMark extends StatelessWidget {
  const LoveMark({super.key, this.size = 40, this.color = AppColors.sparkCoral});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size * 1.6,
        height: size,
        child: CustomPaint(painter: _LovePainter(color)),
      );
}

class _LovePainter extends CustomPainter {
  _LovePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final h = s.height, w = s.width;
    final p = Path()
      ..moveTo(0, h * 0.78)
      // the tail swoops in…
      ..cubicTo(w * 0.12, h * 0.62, w * 0.2, h * 0.95, w * 0.34, h * 0.86)
      // …draws the heart's left lobe…
      ..cubicTo(w * 0.18, h * 0.62, w * 0.16, h * 0.18, w * 0.36, h * 0.12)
      ..cubicTo(w * 0.48, h * 0.08, w * 0.55, h * 0.24, w * 0.56, h * 0.32)
      // …the right lobe…
      ..cubicTo(w * 0.58, h * 0.18, w * 0.7, h * 0.06, w * 0.8, h * 0.14)
      ..cubicTo(w * 0.96, h * 0.28, w * 0.8, h * 0.62, w * 0.56, h * 0.9)
      // …and trails off with a little flourish.
      ..cubicTo(w * 0.7, h * 0.86, w * 0.86, h * 0.98, w, h * 0.8);
    canvas.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = (h * 0.07).clamp(1.5, 3.5)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_LovePainter old) => old.color != color;
}
