import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';

/// Numeric PIN pad with dots. Supports physical keyboard input.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.onCompleted,
    this.length = 4,
    this.maxLength = 8,
    this.error,
    this.busy = false,
  });

  /// Called when user presses OK or reaches [length] digits (auto-submit).
  final Future<void> Function(String pin) onCompleted;
  final int length;
  final int maxLength;
  final String? error;
  final bool busy;

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> {
  String _pin = '';
  final _focus = FocusNode();

  void clear() => setState(() => _pin = '');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pin.length < 4 || widget.busy) return;
    final p = _pin;
    await widget.onCompleted(p);
    if (mounted) setState(() => _pin = '');
  }

  void _press(String d) {
    if (widget.busy) return;
    if (_pin.length >= widget.maxLength) return;
    setState(() => _pin += d);
  }

  void _back() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return KeyboardListener(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (e) {
        if (e is! KeyDownEvent) return;
        final ch = e.character;
        if (ch != null && RegExp(r'^\d$').hasMatch(ch)) {
          _press(ch);
        } else if (e.logicalKey == LogicalKeyboardKey.backspace) {
          _back();
        } else if (e.logicalKey == LogicalKeyboardKey.enter ||
            e.logicalKey == LogicalKeyboardKey.numpadEnter) {
          _submit();
        }
      },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          height: 28,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pin.length < widget.length ? widget.length : _pin.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? t.colorScheme.primary : Colors.transparent,
                  border: Border.all(color: t.colorScheme.outline, width: 1.5),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 28,
          child: widget.error == null
              ? null
              : Center(
                  child: Text(widget.error!,
                      style: TextStyle(color: t.colorScheme.error, fontWeight: FontWeight.w500))),
        ),
        const SizedBox(height: 8),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['<', '0', 'ok'],
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final k in row)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: SizedBox(
                    width: 76,
                    height: 64,
                    child: switch (k) {
                      '<' => Tooltip(
                          message: context.l10n.coreErase,
                          child: OutlinedButton(
                              onPressed: _back,
                              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                              child: const Icon(Icons.backspace_outlined)),
                        ),
                      'ok' => FilledButton(
                          onPressed: _pin.length >= 4 && !widget.busy ? _submit : null,
                          style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                          child: widget.busy
                              ? const SizedBox(
                                  width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.arrow_forward)),
                      _ => OutlinedButton(
                          onPressed: () => _press(k),
                          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                          child: Text(k, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500))),
                    },
                  ),
                ),
            ],
          ),
      ]),
    );
  }
}
