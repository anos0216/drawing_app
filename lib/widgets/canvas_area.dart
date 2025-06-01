import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/draw_controller.dart';
import '../models/draw_tool.dart';
import 'drawing_painter.dart';

class CanvasArea extends ConsumerStatefulWidget {
  const CanvasArea({super.key});

  @override
  ConsumerState<CanvasArea> createState() => _CanvasAreaState();
}

class _CanvasAreaState extends ConsumerState<CanvasArea> {
  late Size _canvasSize;
  Offset? _lastPanPosition;

  @override
  Widget build(BuildContext context) {
    final drawElements = ref.watch(drawElementsProvider);
    final currentTool = ref.watch(currentToolProvider);
    final controller = ref.read(drawControllerProvider); // read to avoid rebuild on controller change
    final currentElement = controller.currentElement;

    final allElements = [...drawElements];
    if (currentElement != null) {
      allElements.add(currentElement);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasSize = constraints.biggest;

        return GestureDetector(
          onPanStart: (details) {
            final local = _clamp(details.localPosition);
            _lastPanPosition = local;

            if (currentTool == DrawToolType.selection) {
              controller.startDragAt(local);
            } else {
              controller.startDrawing(local, _canvasSize);
            }
          },
          onPanUpdate: (details) {
            final local = _clamp(details.localPosition);
            final delta = local - (_lastPanPosition ?? local);
            _lastPanPosition = local;

            if (currentTool == DrawToolType.selection && controller.selectedElement != null) {
              controller.dragTo(local, delta);
            } else {
              controller.updateDrawing(local);
            }
          },
          onPanEnd: (_) {
            _lastPanPosition = null;

            if (currentTool == DrawToolType.selection) {
              controller.endDrag();
            } else {
              controller.endDrawing();
            }
          },
          onTapDown: currentTool == DrawToolType.pen
              ? (details) {
                  final local = _clamp(details.localPosition);
                  controller.tapOnCanvas(local);
                }
              : null,
          child: CustomPaint(
            size: _canvasSize,
            painter: DrawingPainter(
              elements: allElements,
              selectedElement: controller.selectedElement,
            ),
          ),
        );
      },
    );
  }

  Offset _clamp(Offset point) {
    return Offset(
      point.dx.clamp(0.0, _canvasSize.width),
      point.dy.clamp(0.0, _canvasSize.height),
    );
  }
}
