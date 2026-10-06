import 'package:flutter/material.dart';
import '../theme.dart';

/// Red cross drawn over a pictogram to show it is not going to happen.
/// Place it on top of the pictogram, e.g. with [Positioned.fill].
class NotCrossOverlay extends StatelessWidget {
  const NotCrossOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _NotCrossPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _NotCrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final inset = side * 0.08;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: side - inset * 2,
      height: side - inset * 2,
    );
    final paint = Paint()
      ..color = AppTheme.accentRed
      ..strokeWidth = (side * 0.09).clamp(3.0, 28.0)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
    canvas.drawLine(rect.topRight, rect.bottomLeft, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
