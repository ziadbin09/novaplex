import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// 4-digit PIN entry dialog. Returns the PIN string, or null if cancelled.
Future<String?> showPinDialog(
  BuildContext context, {
  required String title,
  String? subtitle,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PinDialog(title: title, subtitle: subtitle),
  );
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.length == 4) {
      Navigator.of(context).pop(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: colors.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(widget.title, style: context.text.titleMedium),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.subtitle != null) ...[
            Text(widget.subtitle!,
                style: context.text.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: context.text.titleMedium?.copyWith(letterSpacing: 16),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••',
              hintStyle: context.text.titleMedium?.copyWith(
                letterSpacing: 16,
                color: colors.textSecondary,
              ),
              filled: true,
              fillColor: colors.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) {
              if (v.length == 4) _submit();
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child:
              Text('Cancel', style: TextStyle(color: colors.textSecondary)),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: colors.accentSecondary),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
