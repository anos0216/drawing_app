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
final fillColorProvider = StateProvider<Color?>((ref) => null);

class DrawController extends StateNotifier<List<DrawElement>> {
  DrawController(this.ref) : super([]);

  final Ref ref;

  FreeDrawElement? _currentFreeDraw;
  PenDrawElement? _currentPenPath;
  ShapeDrawElement? _currentShape;
  DateTime? _lastTapTime;

  DrawElement? _selectedElement;
  int? _selectedPointIndex;
  String? _selectedHandle; // 'anchor', 'handleIn', 'handleOut'

  DrawElement? get selectedElement => _selectedElement;

  DrawElement? get currentElement =>
      _currentFreeDraw ?? _currentPenPath ?? _currentShape;

  bool _isDraggingPoint = false;

void startDragAt(Offset point) {
  // Attempt to select a point or handle at the given position
  selectElementAt(point);

  // If a PenDrawElement's point or handle is selected, start dragging that point
  if (_selectedElement is PenDrawElement && _selectedPointIndex != null && _selectedHandle != null) {
    _isDraggingPoint = true;
  } else {
    // If no point/handle selected, consider dragging the whole element
    _isDraggingPoint = false;
  }
}

void dragTo(Offset newPosition, Offset delta) {
  if (_isDraggingPoint && _selectedElement is PenDrawElement && _selectedPointIndex != null && _selectedHandle != null) {
    final pen = _selectedElement as PenDrawElement;
    final point = pen.points[_selectedPointIndex!];

    switch (_selectedHandle) {
      case 'anchor':
        point.anchor += delta;
        // Move handles together with anchor to keep curve shape consistent
        if (point.handleIn != null) point.handleIn = point.handleIn! + delta;
        if (point.handleOut != null) point.handleOut = point.handleOut! + delta;
        break;
      case 'handleIn':
        if (point.handleIn != null) {
          point.handleIn = point.handleIn! + delta;
        }
        break;
      case 'handleOut':
        if (point.handleOut != null) {
          point.handleOut = point.handleOut! + delta;
        }
        break;
    }
    // Trigger UI update
    state = [...state];
  } else if (_selectedElement != null && !_isDraggingPoint) {
    // Move entire selected element if no point dragging active
    _selectedElement!.move(delta);
    state = [...state];
  }
}

void endDrag() {
  _isDraggingPoint = false;
}


  void selectElementAt(Offset point) {
    // Check if the same thing is already selected — toggle to deselect
    if (_selectedElement != null) {
      if (_selectedElement!.contains(point)) {
        // If no specific handle is tapped, toggle deselect
        if (_selectedPointIndex == null && _selectedHandle == null) {
          deselect();
          return;
        }

        // If it's a PenDrawElement, check for same point/handle again
        if (_selectedElement is PenDrawElement) {
          final pen = _selectedElement as PenDrawElement;
          final selectedPoint = pen.points[_selectedPointIndex ?? -1];

          if (_selectedHandle == 'anchor' &&
              (selectedPoint.anchor - point).distance < 10) {
            deselect();
            return;
          }
          if (_selectedHandle == 'handleIn' &&
              selectedPoint.handleIn != null &&
              (selectedPoint.handleIn! - point).distance < 10) {
            deselect();
            return;
          }
          if (_selectedHandle == 'handleOut' &&
              selectedPoint.handleOut != null &&
              (selectedPoint.handleOut! - point).distance < 10) {
            deselect();
            return;
          }
        }
      }
    }

    // Fresh selection attempt
    for (final element in state.reversed) {
      if (element is PenDrawElement) {
        for (int i = 0; i < element.points.length; i++) {
          final p = element.points[i];
          if ((p.anchor - point).distance < 10) {
            _selectedElement = element;
            _selectedPointIndex = i;
            _selectedHandle = 'anchor';
            state = [...state];
            return;
          }
          if (p.handleIn != null && (p.handleIn! - point).distance < 10) {
            _selectedElement = element;
            _selectedPointIndex = i;
            _selectedHandle = 'handleIn';
            state = [...state];
            return;
          }
          if (p.handleOut != null && (p.handleOut! - point).distance < 10) {
            _selectedElement = element;
            _selectedPointIndex = i;
            _selectedHandle = 'handleOut';
            state = [...state];
            return;
          }
        }
      } else if (element.contains(point)) {
        _selectedElement = element;
        _selectedPointIndex = null;
        _selectedHandle = null;
        state = [...state];
        return;
      }
    }

    // If nothing was hit
    deselect();
  }

  void moveSelectedElement(Offset delta) {
    if (_selectedElement == null) return;

    if (_selectedElement is PenDrawElement &&
        _selectedPointIndex != null &&
        _selectedHandle != null) {
      final pen = _selectedElement as PenDrawElement;
      final point = pen.points[_selectedPointIndex!];

      switch (_selectedHandle) {
        case 'anchor':
          point.anchor += delta;
          break;
        case 'handleIn':
          if (point.handleIn != null) {
            point.handleIn = point.handleIn! + delta;
          }
          break;
        case 'handleOut':
          if (point.handleOut != null) {
            point.handleOut = point.handleOut! + delta;
          }
          break;
      }
    } else {
      _selectedElement?.move(delta);
    }

    state = [...state];
  }

  void deselect() {
    _selectedElement = null;
    _selectedPointIndex = null;
    _selectedHandle = null;
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
        points: [PenPoint(anchor: point)],
      );
    } else if (isDoubleTap) {
      if (_currentPenPath!.points.length >= 2) {
        state = [...state, _currentPenPath!];
      }
      _currentPenPath = null;
    } else {
      _currentPenPath!.points.add(PenPoint(anchor: point));
      state = [...state];
    }
  }

  bool _isShapeTool(DrawToolType tool) {
    return tool == DrawToolType.rectangle ||
        tool == DrawToolType.circle ||
        tool == DrawToolType.triangle;
  }
}
