import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/draw_element.dart';
import '../models/draw_tool.dart';

final drawElementsProvider =
    StateNotifierProvider<DrawController, List<DrawElement>>(
      (ref) => DrawController(ref),
    );

final drawControllerProvider = Provider<DrawController>(
  (ref) => ref.read(drawElementsProvider.notifier),
);

final currentToolProvider = StateProvider<DrawToolType>(
  (ref) => DrawToolType.pencil,
);

final currentColorProvider = StateProvider<Color>((ref) => Colors.black);

final strokeWidthProvider = StateProvider<double>((ref) => 2.0);

final fillColorProvider = StateProvider<Color?>(
  (ref) => null, // null means no fill
);

class DrawController extends StateNotifier<List<DrawElement>> {
  DrawController(this.ref) : super([]);

  final Ref ref;

  FreeDrawElement? _currentFreeDraw;
  PenDrawElement? _currentPenPath;
  ShapeDrawElement? _currentShape;
  DateTime? _lastTapTime;

  // Unified current element
  DrawElement? get currentElement =>
      _currentFreeDraw ?? _currentPenPath ?? _currentShape;

  DrawElement? _selectedElement;

  DrawElement? get selectedElement => _selectedElement;

  void selectElementAt(Offset point) {
    for (final element in state.reversed) {
      if (element.contains(point)) {
        _selectedElement = element;
        state = [...state]; // repaint
        return;
      }
    }
    _selectedElement = null;
    state = [...state]; // clear selection
  }

  void moveSelectedElement(Offset delta) {
    _selectedElement?.move(delta);
    state = [...state];
  }

  void deselect() {
    _selectedElement = null;
    state = [...state];
  }

  void startDrawing(Offset point, Size canvasSize) {
    final tool = ref.read(currentToolProvider);
    final color = ref.read(currentColorProvider);
    final strokeWidth = ref.read(strokeWidthProvider);
    final fillColor = ref.read(fillColorProvider);

    if (tool == DrawToolType.pencil || tool == DrawToolType.brush) {
      _currentFreeDraw = FreeDrawElement(
        color: color,
        strokeWidth: strokeWidth,
        points: [point],
        fillColor: fillColor,
      );
    } else if (_isShapeTool(tool)) {
      _currentShape = ShapeDrawElement(
        color: color,
        strokeWidth: strokeWidth,
        fillColor: fillColor,
        start: point,
        end: point,
        shapeType: tool,
      );
    }
  }

  void updateDrawing(Offset point) {
    if (_currentFreeDraw != null) {
      _currentFreeDraw!.points.add(point);
    } else if (_currentShape != null) {
      _currentShape = ShapeDrawElement(
        start: _currentShape!.start,
        end: point,
        color: _currentShape!.color,
        strokeWidth: _currentShape!.strokeWidth,
        shapeType: _currentShape!.shapeType,
        fillColor: _currentShape!.fillColor,
      );
    }
    state = [...state];
  }

  void endDrawing() {
    if (_currentFreeDraw != null) {
      state = [...state, _currentFreeDraw!];
      _currentFreeDraw = null;
    } else if (_currentShape != null) {
      state = [...state, _currentShape!];
      _currentShape = null;
    }
  }

  void tapOnCanvas(Offset point) {
    final tool = ref.read(currentToolProvider);
    final color = ref.read(currentColorProvider);
    final strokeWidth = ref.read(strokeWidthProvider);

    if (tool != DrawToolType.pen) return;

    final now = DateTime.now();
    final isDoubleTap =
        _lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 300);
    _lastTapTime = now;

    if (_currentPenPath == null) {
      _currentPenPath = PenDrawElement(
        color: color,
        strokeWidth: strokeWidth,
        points: [point],
      );
    } else if (isDoubleTap) {
      if (_currentPenPath!.points.length >= 2) {
        state = [...state, _currentPenPath!];
      }
      _currentPenPath = null;
    } else {
      _currentPenPath!.points.add(point);
      state = [...state];
    }
  }

  bool _isShapeTool(DrawToolType tool) {
    return tool == DrawToolType.rectangle ||
        tool == DrawToolType.circle ||
        tool == DrawToolType.triangle;
  }
}