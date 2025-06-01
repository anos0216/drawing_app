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

// ------------------ Freehand Drawing ------------------

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

// ------------------ PenPoint for Bézier editing ------------------
class PenPoint {
  Offset anchor;
  Offset? handleIn;
  Offset? handleOut;

  PenPoint({required this.anchor, this.handleIn, this.handleOut});

  PenPoint copyWith({Offset? anchor, Offset? handleIn, Offset? handleOut}) {
    return PenPoint(
      anchor: anchor ?? this.anchor,
      handleIn: handleIn ?? this.handleIn,
      handleOut: handleOut ?? this.handleOut,
    );
  }
}

class PenDrawElement extends DrawElement {
  final List<PenPoint> points;

  PenDrawElement({
    required super.color,
    required super.strokeWidth,
    super.fillColor,
    required this.points,
  });

  @override
  void paint(Canvas canvas, Paint paint) {
    if (points.length < 2) return;

    final path = Path()..moveTo(points[0].anchor.dx, points[0].anchor.dy);

    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      final control1 = prev.handleOut ?? prev.anchor;
      final control2 = curr.handleIn ?? curr.anchor;

      path.cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        curr.anchor.dx,
        curr.anchor.dy,
      );
    }

    if (fillColor != null) {
      final fillPaint =
          Paint()
            ..color = fillColor!
            ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }

    paint.style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);

    // --- Draw editing points if selected ---
    final handlePaint =
        Paint()
          ..color = Colors.grey
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    final anchorPaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

    final handleCirclePaint =
        Paint()
          ..color = Colors.purple
          ..style = PaintingStyle.fill;

    for (final p in points) {
      // Anchor point
      canvas.drawCircle(p.anchor, 5, anchorPaint);

      // Handles
      if (p.handleIn != null) {
        canvas.drawLine(p.anchor, p.handleIn!, handlePaint);
        canvas.drawCircle(p.handleIn!, 4, handleCirclePaint);
      }

      if (p.handleOut != null) {
        canvas.drawLine(p.anchor, p.handleOut!, handlePaint);
        canvas.drawCircle(p.handleOut!, 4, handleCirclePaint);
      }
    }
  }

  @override
  bool contains(Offset point) {
    for (var p in points) {
      if ((p.anchor - point).distance < 10) return true;
      if (p.handleIn != null && (p.handleIn! - point).distance < 10) {
        return true;
      }
      if (p.handleOut != null && (p.handleOut! - point).distance < 10) {
        return true;
      }
    }
    return false;
  }

  @override
  void move(Offset delta) {
    for (var p in points) {
      p.anchor += delta;
      if (p.handleIn != null) p.handleIn = p.handleIn! + delta;
      if (p.handleOut != null) p.handleOut = p.handleOut! + delta;
    }
  }

  @override
  void editPoint(int index, Offset newPosition) {
    if (index < 0 || index >= points.length) return;
    points[index].anchor = newPosition;
  }

  // Optional: Add a new point at a specific index
  void addPoint(PenPoint point, {int? index}) {
    if (index != null && index >= 0 && index < points.length) {
      points.insert(index, point);
    } else {
      points.add(point);
    }
  }

  // Optional: Remove point at index
  void removePoint(int index) {
    if (index >= 0 && index < points.length) {
      points.removeAt(index);
    }
  }

  @override
  Rect get boundingRect {
    final allPoints = points.expand(
      (p) => [
        p.anchor,
        if (p.handleIn != null) p.handleIn!,
        if (p.handleOut != null) p.handleOut!,
      ],
    );
    final dxs = allPoints.map((e) => e.dx);
    final dys = allPoints.map((e) => e.dy);
    return Rect.fromLTRB(
      dxs.reduce((a, b) => a < b ? a : b),
      dys.reduce((a, b) => a < b ? a : b),
      dxs.reduce((a, b) => a > b ? a : b),
      dys.reduce((a, b) => a > b ? a : b),
    );
  }
}

// ------------------ Shapes ------------------

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
  void resize(Offset handlePoint, Offset newPoint) {
    // Basic behavior: drag corner to resize shape
    // Determine which corner is being dragged
    if ((handlePoint - start).distance < 20) {
      start = newPoint;
    } else if ((handlePoint - end).distance < 20) {
      end = newPoint;
    } else {
      // Midpoint resizing logic (e.g. top-right, bottom-left) if needed
      // You can expand this for more granular control
    }
  }

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
