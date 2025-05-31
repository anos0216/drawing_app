import 'package:flutter/material.dart';
import 'draw_tool.dart';

abstract class DrawElement {
  final Color color;
  final double strokeWidth;
  final Color? fillColor;

  DrawElement({required this.color, required this.strokeWidth, this.fillColor});

  void paint(Canvas canvas, Paint paint);
  bool contains(Offset point);
  void move(Offset delta);
  void resize(Offset handlePoint, Offset newPoint) {}
  void editPoint(int index, Offset newPosition) {}
  Rect get boundingRect;
}

class FreeDrawElement extends DrawElement {
  final List<Offset> points;

  FreeDrawElement({
    required super.color,
    required super.strokeWidth,
    super.fillColor,
    required this.points,
  });

  @override
  void paint(Canvas canvas, Paint paint) {
    if (points.length < 2) return;

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    if (fillColor != null) {
      final fill =
          Paint()
            ..color = fillColor!
            ..style = PaintingStyle.fill;
      canvas.drawPath(path, fill);
    }

    paint.style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);
  }

  @override
  bool contains(Offset point) {
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    return path.contains(point);
  }

  @override
  void move(Offset delta) {
    for (int i = 0; i < points.length; i++) {
      points[i] += delta;
    }
  }

  @override
  Rect get boundingRect {
    final dxs = points.map((e) => e.dx);
    final dys = points.map((e) => e.dy);
    return Rect.fromLTRB(
      dxs.reduce((a, b) => a < b ? a : b),
      dys.reduce((a, b) => a < b ? a : b),
      dxs.reduce((a, b) => a > b ? a : b),
      dys.reduce((a, b) => a > b ? a : b),
    );
  }
}

class PenDrawElement extends FreeDrawElement {
  PenDrawElement({
    required super.color,
    required super.strokeWidth,
    super.fillColor,
    required super.points,
  });
}

class ShapeDrawElement extends DrawElement {
  Offset start;
  Offset end;
  final DrawToolType shapeType;

  ShapeDrawElement({
    required super.color,
    required super.strokeWidth,
    super.fillColor,
    required this.start,
    required this.end,
    required this.shapeType,
  });

  @override
  void paint(Canvas canvas, Paint paint) {
    final rect = Rect.fromPoints(start, end);

    if (fillColor != null) {
      final fill =
          Paint()
            ..color = fillColor!
            ..style = PaintingStyle.fill;
      _drawShape(canvas, fill, rect);
    }

    final stroke =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;
    _drawShape(canvas, stroke, rect);
  }

  void _drawShape(Canvas canvas, Paint paint, Rect rect) {
    switch (shapeType) {
      case DrawToolType.rectangle:
        canvas.drawRect(rect, paint);
        break;
      case DrawToolType.circle:
        canvas.drawOval(rect, paint);
        break;
      case DrawToolType.triangle:
        final path =
            Path()
              ..moveTo(rect.center.dx, rect.top)
              ..lineTo(rect.bottomLeft.dx, rect.bottomLeft.dy)
              ..lineTo(rect.bottomRight.dx, rect.bottomRight.dy)
              ..close();
        canvas.drawPath(path, paint);
        break;
      default:
        break;
    }
  }

  @override
  bool contains(Offset point) {
    final rect = Rect.fromPoints(start, end);
    switch (shapeType) {
      case DrawToolType.rectangle:
      case DrawToolType.circle:
        return rect.contains(point);
      case DrawToolType.triangle:
        final path =
            Path()
              ..moveTo(rect.center.dx, rect.top)
              ..lineTo(rect.bottomLeft.dx, rect.bottomLeft.dy)
              ..lineTo(rect.bottomRight.dx, rect.bottomRight.dy)
              ..close();
        return path.contains(point);
      default:
        return false;
    }
  }

  @override
  void move(Offset delta) {
    start += delta;
    end += delta;
  }

  @override
  Rect get boundingRect => Rect.fromPoints(start, end);
}
