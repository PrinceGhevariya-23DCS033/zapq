import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class IconGenerator {
  static Future<void> generateAppIcon() async {
    // Create a custom painter for the app icon
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(512, 512);
    
    // Paint the background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    
    // Create gradient
    final gradient = const RadialGradient(
      colors: [
        Color(0xFF4CAF50), // Green
        Color(0xFF2196F3), // Blue
      ],
      stops: [0.0, 1.0],
    );
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    
    // Create gradient paint
    final gradientPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius));
    
    // Draw the circular background
    canvas.drawCircle(center, radius, gradientPaint);
    
    // Draw the queue/arrow symbol
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    
    // Draw queue lines
    final lineLength = radius * 0.6;
    final lineSpacing = radius * 0.15;
    
    for (int i = 0; i < 3; i++) {
      final y = center.dy - lineSpacing + (i * lineSpacing);
      final startX = center.dx - lineLength / 2;
      final endX = center.dx + lineLength / 2;
      
      canvas.drawLine(
        Offset(startX, y),
        Offset(endX, y),
        arrowPaint,
      );
    }
    
    // Draw arrow
    final arrowSize = radius * 0.3;
    final arrowPath = Path();
    arrowPath.moveTo(center.dx + lineLength / 3, center.dy - arrowSize / 2);
    arrowPath.lineTo(center.dx + lineLength / 2, center.dy);
    arrowPath.lineTo(center.dx + lineLength / 3, center.dy + arrowSize / 2);
    
    canvas.drawPath(arrowPath, arrowPaint);
    
    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      final pngBytes = byteData.buffer.asUint8List();
      
      // Save the icon
      final file = File('assets/images/app_icon.png');
      await file.writeAsBytes(pngBytes);
      print('App icon generated successfully!');
    }
  }
}
