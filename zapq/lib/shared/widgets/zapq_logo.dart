import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ZapQLogo extends StatelessWidget {
  final double size;
  final bool showBackground;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const ZapQLogo({
    super.key,
    this.size = 80,
    this.showBackground = false,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget logoWidget = CustomPaint(
      size: Size(size, size),
      painter: ZapQLogoPainter(),
    );

    if (showBackground) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: size * 0.7,
            height: size * 0.7,
            child: logoWidget,
          ),
        ),
      );
    }

    return logoWidget;
  }
}

class ZapQLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.15
      ..strokeCap = StrokeCap.round;

    // Create gradient
    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF4CAF50), // Green
        const Color(0xFF2196F3), // Blue
        const Color(0xFF1976D2), // Dark Blue
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Draw the main circular arc (about 270 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.75 * 3.14159, // Start angle (roughly -135 degrees)
      1.5 * 3.14159,   // Sweep angle (270 degrees)
      false,
      paint,
    );

    // Draw the arrow/play button element
    final arrowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF4CAF50), // Green
          const Color(0xFF2196F3), // Blue
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final arrowSize = size.width * 0.25;
    final arrowX = center.dx - arrowSize * 0.8;
    final arrowY = center.dy;

    final arrowPath = Path();
    arrowPath.moveTo(arrowX, arrowY - arrowSize * 0.5);
    arrowPath.lineTo(arrowX + arrowSize * 0.8, arrowY);
    arrowPath.lineTo(arrowX, arrowY + arrowSize * 0.5);
    arrowPath.lineTo(arrowX + arrowSize * 0.3, arrowY);
    arrowPath.close();

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
