import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_colors.dart';

class QuantityStepper extends StatefulWidget {
  final int value;
  final int min;
  final int max;
  final double size;
  final ValueChanged<int> onChanged;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.size = 40,
  });

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        _controller.text != widget.value.toString()) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _emitValue(int value) {
    final safeValue = value.clamp(widget.min, widget.max);
    if (safeValue != widget.value) {
      widget.onChanged(safeValue);
    }
  }

  void _applyText(String rawValue) {
    final cleaned = rawValue.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) {
      _emitValue(widget.min);
      _controller.text = widget.min.toString();
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      return;
    }

    final parsed = int.tryParse(cleaned);
    if (parsed == null) {
      _emitValue(widget.min);
      _controller.text = widget.min.toString();
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      return;
    }

    final finalValue = parsed.clamp(widget.min, widget.max);
    _emitValue(finalValue);
    _controller.text = finalValue.toString();
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove,
          size: widget.size,
          enabled: widget.value > widget.min,
          onTap: () => _emitValue(widget.value - 1),
        ),
        SizedBox(
          width: widget.size + 24,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            maxLength: 3,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: _applyText,
            onSubmitted: _applyText,
          ),
        ),
        _StepButton(
          icon: Icons.add,
          size: widget.size,
          enabled: widget.value < widget.max,
          onTap: () => _emitValue(widget.value + 1),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.size,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.panelBorder),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.textDark : AppColors.panelBorder,
        ),
      ),
    );
  }
}
