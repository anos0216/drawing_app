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

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(drawControllerProvider);
    final drawElements = ref.watch(drawElementsProvider);
    final tool = ref.watch(currentToolProvider);

    final current = controller.currentElement;

    final allElements = [...drawElements];
    if (current != null) allElements.add(current);

    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasSize = constraints.biggest;
        return GestureDetector(
         onPanStart: (details) {
    final tool = ref.read(currentToolProvider);
    final controller = ref.read(drawControllerProvider);

    if (tool == DrawToolType.selection) {
      controller.selectElementAt(details.localPosition);
    } else {
      controller.startDrawing(details.localPosition, context.size!);
    }
  },
  onPanUpdate: (details) {
    final tool = ref.read(currentToolProvider);
    final controller = ref.read(drawControllerProvider);

    if (tool == DrawToolType.selection && controller.selectedElement != null) {
      controller.moveSelectedElement(details.delta);
    } else {
      controller.updateDrawing(details.localPosition);
    }
  },
  onPanEnd: (_) {
    final tool = ref.read(currentToolProvider);
    if (tool != DrawToolType.selection) {
      ref.read(drawControllerProvider).endDrawing();
    }
  },
          onTapDown:
              tool == DrawToolType.pen
                  ? (details) {
                    final local = _clamp(details.localPosition);
                    controller.tapOnCanvas(local);
                  }
                  : null,
          child: CustomPaint(
            size: _canvasSize,
            painter: DrawingPainter(elements: allElements),
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