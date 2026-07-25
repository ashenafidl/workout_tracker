import "package:flutter/material.dart";
import "package:workout_tracker/core/widgets/unit_input/scroll_wheel.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_config.dart";
import "package:workout_tracker/core/widgets/unit_input/unit_input_result.dart";
import "package:workout_tracker/utils/format_time.dart";

class UnitInputSheet extends StatefulWidget {
  const UnitInputSheet({
    super.key,
    required this.title,
    required this.config,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final UnitInputConfig config;

  @override
  State<UnitInputSheet> createState() => _UnitInputSheetState();
}

class _UnitInputSheetState extends State<UnitInputSheet> {
  // Current raw values — only one is active depending on config type.
  late int _intValue;
  late Duration _duration;

  bool _isEditing = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    switch (widget.config) {
      case final IntegerInputConfig c:
        _intValue = c.initialValue;
      case final DurationInputConfig c:
        _duration = c.initialDuration;
    }
    _controller = TextEditingController(text: _displayValue());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─── Display ─────────────────────────────────────────────────────────────

  String _displayValue() {
    return switch (widget.config) {
      IntegerInputConfig() => "$_intValue",
      DurationInputConfig() => formatDuration(_duration),
    };
  }

  String _unitLabel() {
    return switch (widget.config) {
      final IntegerInputConfig c => c.label ?? "",
      DurationInputConfig() => "",
    };
  }

  // ─── Stepper logic ───────────────────────────────────────────────────────
  void _increment() {
    setState(() {
      switch (widget.config) {
        case final IntegerInputConfig c:
          _intValue += c.step;
        case final DurationInputConfig c:
          _duration += Duration(seconds: c.stepSeconds);
      }
    });
  }

  void _decrement() {
    setState(() {
      switch (widget.config) {
        case final IntegerInputConfig c:
          if (_intValue - c.step >= c.min) _intValue -= c.step;
        case final DurationInputConfig c:
          final next = _duration - Duration(seconds: c.stepSeconds);
          if (next.inSeconds >= 0) _duration = next;
      }
    });
  }

  bool get _canDecrement {
    return switch (widget.config) {
      final IntegerInputConfig c => _intValue - c.step >= c.min,
      final DurationInputConfig c =>
        (_duration - Duration(seconds: c.stepSeconds)).inSeconds >= 0,
    };
  }

  // ─── Inline keyboard edit ────────────────────────────────────────────────

  // Duration uses two separate fields (mm:ss) so keyboard edit is disabled for it.
  bool get _supportsKeyboardEdit => widget.config is! DurationInputConfig;

  void _startEditing() {
    if (!_supportsKeyboardEdit) return;

    _controller.text = _displayValue();
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
    setState(() => _isEditing = true);
  }

  void _commitEdit() {
    switch (widget.config) {
      case final IntegerInputConfig c:
        final v = int.tryParse(_controller.text);
        if (v != null && v >= c.min) _intValue = v;
      case DurationInputConfig():
        break;
    }
    setState(() => _isEditing = false);
  }

  // ─── Result ──────────────────────────────────────────────────────────────

  UnitInputResult _buildResult() {
    return switch (widget.config) {
      IntegerInputConfig() => IntegerInputResult(_intValue),
      DurationInputConfig() => DurationInputResult(_duration),
    };
  }

  // ─── Duration picker (mm:ss scroll wheels) ───────────────────────────────

  Widget _buildDurationPicker() {
    return Row(
      mainAxisAlignment: .center,
      children: [
        ScrollWheel(
          value: _duration.inMinutes,
          max: 99,
          label: "min",
          onChanged: (m) {
            setState(() {
              _duration = Duration(
                minutes: m,
                seconds: _duration.inSeconds % 60,
              );
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(":", style: Theme.of(context).textTheme.displaySmall),
        ),
        ScrollWheel(
          value: _duration.inSeconds % 60,
          max: 59,
          label: "sec",
          onChanged: (s) {
            setState(() {
              _duration = Duration(minutes: _duration.inMinutes, seconds: s);
            });
          },
        ),
      ],
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isDuration = widget.config is DurationInputConfig;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + keyboardInset),
        child: Column(
          mainAxisSize: .min,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: .center,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 32),

            if (isDuration)
              _buildDurationPicker()
            else
              Row(
                mainAxisAlignment: .center,
                children: [
                  IconButton(
                    onPressed: _canDecrement ? _decrement : null,
                    icon: const Icon(Icons.remove_rounded),
                    iconSize: 36,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(64, 64),
                    ),
                  ),
                  GestureDetector(
                    onTap: _startEditing,
                    child: SizedBox(
                      width: 140,
                      child: _isEditing
                          ? TextField(
                              controller: _controller,
                              autofocus: true,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textAlign: .center,
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(fontWeight: .bold),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: (_) => _commitEdit(),
                              onTapOutside: (_) => _commitEdit(),
                            )
                          : Column(
                              mainAxisSize: .min,
                              children: [
                                Text(
                                  _displayValue(),
                                  textAlign: .center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(fontWeight: .bold),
                                ),
                                if (_unitLabel().isNotEmpty)
                                  Text(
                                    _unitLabel(),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                  IconButton(
                    onPressed: _increment,
                    icon: const Icon(Icons.add_rounded),
                    iconSize: 36,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(64, 64),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 32),

            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_isEditing) _commitEdit();
                  Navigator.pop(context, _buildResult());
                },
                child: const Text("Done"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
