import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/draw_controller.dart';

class ColorPicker extends ConsumerWidget {
  const ColorPicker({super.key});

  static const List<Color> colors = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.pink,
    Colors.indigo
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strokeColor = ref.watch(currentColorProvider);
    final fillColor = ref.watch(fillColorProvider);

    Widget colorBox(Color color, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected ? Border.all(color: Colors.deepPurple, width: 3) : null,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Stroke Color"),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: colors.map((c) => colorBox(c, c == strokeColor, () {
              ref.read(currentColorProvider.notifier).state = c;
            })).toList(),
          ),
        ),
        const SizedBox(height: 8),
        const Text("Fill Color"),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...colors.map((c) => colorBox(c, c == fillColor, () {
                ref.read(fillColorProvider.notifier).state = c;
              })),
              GestureDetector(
                onTap: () => ref.read(fillColorProvider.notifier).state = null,
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Center(child: Icon(Icons.close, size: 18)),
                ),
              )
            ],
          ),
        )
      ],
    );
  }
}
