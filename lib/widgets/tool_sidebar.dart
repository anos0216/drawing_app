import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/draw_tool.dart';
import '../controller/draw_controller.dart';

class ToolSidebar extends ConsumerWidget {
  const ToolSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTool = ref.watch(currentToolProvider);
    final strokeWidth = ref.watch(strokeWidthProvider);

    return Container(
      width: 60,
      color: Colors.grey[200],
      child: Column(
        children: [
          // Tool Buttons
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: DrawToolType.values.map((tool) {
                  final isActive = currentTool == tool;
                  return IconButton(
                    icon: Icon(
                      _getIconForTool(tool),
                      color: isActive ? Colors.deepPurple : Colors.black,
                    ),
                    onPressed: () {
                      ref.read(currentToolProvider.notifier).state = tool;
                    },
                    tooltip: tool.name,
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(),

          // Stroke Width Slider
          RotatedBox(
            quarterTurns: -1,
            child: Slider(
              min: 1,
              max: 20,
              value: strokeWidth,
              onChanged: (value) {
                ref.read(strokeWidthProvider.notifier).state = value;
              },
              activeColor: Colors.deepPurple,
              inactiveColor: Colors.grey,
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  IconData _getIconForTool(DrawToolType tool) {
    switch (tool) {
      case DrawToolType.pencil:
        return Icons.create;
      case DrawToolType.brush:
        return Icons.brush;
      case DrawToolType.pen:
        return Icons.edit;
      case DrawToolType.rectangle:
        return Icons.crop_square;
      case DrawToolType.circle:
        return Icons.circle;
      case DrawToolType.triangle:
        return Icons.change_history;
      case DrawToolType.polygon:
        return Icons.hexagon;
      case DrawToolType.selection:
        return Icons.select_all;
      case DrawToolType.eraser:
        return Icons.delete;
    }
  }
}
