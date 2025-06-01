import 'package:flutter/material.dart';
import '../widgets/tool_sidebar.dart';
import '../widgets/canvas_area.dart';
import '../widgets/color_picker.dart';

class DrawingScreen extends StatelessWidget {
  const DrawingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  const ToolSidebar(),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: const CanvasArea(),
                    ),
                  ),
                ],
              ),
            ),

            const ColorPicker(),
          ],
        ),
      ),
    );
  }
}
