import 'package:flutter/material.dart';
import '../models/draw_element.dart';

class DrawingPainter extends CustomPainter {
  final List<DrawElement> elements;
  final DrawElement? selectedElement;

  DrawingPainter({required this.elements, this.selectedElement});

  @override
  void paint(Canvas canvas, Size size) {
    for (final element in elements) {
      final paint = Paint()
        ..color = element.color
        ..strokeWidth = element.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      element.paint(canvas, paint);
    }

    if (selectedElement != null) {
      final rect = selectedElement!.boundingRect;
      final selectionPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRect(rect.inflate(4), selectionPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}