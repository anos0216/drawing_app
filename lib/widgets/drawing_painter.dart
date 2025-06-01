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

    // Draw selection bounding box
    if (selectedElement != null) {
      final rect = selectedElement!.boundingRect;
      final selectionPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRect(rect.inflate(4), selectionPaint);

      // If it's a PenDrawElement, draw anchor and handle points
      if (selectedElement is PenDrawElement) {
        final pen = selectedElement as PenDrawElement;

        final anchorPaint = Paint()
          ..color = Colors.purple
          ..style = PaintingStyle.fill;

        final handlePaint = Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

        final connectorPaint = Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        for (final point in pen.points) {
          // Draw connectors from anchor to handles
          if (point.handleIn != null) {
            canvas.drawLine(point.anchor, point.handleIn!, connectorPaint);
            canvas.drawCircle(point.handleIn!, 4, handlePaint);
          }
          if (point.handleOut != null) {
            canvas.drawLine(point.anchor, point.handleOut!, connectorPaint);
            canvas.drawCircle(point.handleOut!, 4, handlePaint);
          }

          // Draw anchor point
          canvas.drawCircle(point.anchor, 5, anchorPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
