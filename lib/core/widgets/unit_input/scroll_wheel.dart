import "package:flutter/material.dart";

class ScrollWheel extends StatefulWidget {
  const new({
    super.key,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<ScrollWheel> createState() => _ScrollWheelState();
}

class _ScrollWheelState extends State<ScrollWheel> {
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 140,
      child: ListWheelScrollView.useDelegate(
        controller: _controller,
        itemExtent: 48,
        diameterRatio: 1.6,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: widget.onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            if (index < 0 || index > widget.max) return null;
            final selected = index == widget.value;

            return Center(
              child: Text(
                index.toString().padLeft(2, "0"),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.3),
                ),
                textAlign: .center,
              ),
            );
          },
        ),
      ),
    );
  }
}
