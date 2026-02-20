import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PinInputTheme { light, dark }

class PinInputWidget extends StatefulWidget {
  final Function(String) onCompleted;
  final int length;
  final PinInputTheme theme;

  const PinInputWidget({
    super.key,
    required this.onCompleted,
    this.length = 6,
    this.theme = PinInputTheme.light,
  });

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  final List<String> _pinValues = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.length; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
      _pinValues.add('');
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onPinChanged(int index, String value) {
    if (value.length > 1) {
      value = value.substring(value.length - 1);
    }

    setState(() {
      _pinValues[index] = value;
    });

    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Check if all fields are filled
    if (_pinValues.every((v) => v.isNotEmpty)) {
      final pin = _pinValues.join();
      widget.onCompleted(pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme == PinInputTheme.dark;
    final borderColor = isDark ? const Color(0xFF8E8E93) : null;
    final fillColor = isDark ? const Color(0xFF2C2C2E) : null;
    final textColor = isDark ? const Color(0xFFE5E5EA) : null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.length,
        (index) => Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            obscureText: true,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: isDark,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: borderColor ?? Theme.of(context).colorScheme.outline,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF0A84FF) : Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) => _onPinChanged(index, value),
          ),
        ),
      ),
    );
  }
}
