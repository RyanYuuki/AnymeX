import 'package:flutter/material.dart';

class SchemeVariantDialog extends StatefulWidget {
  final String selectedVariant;
  final Function(String) onVariantSelected;

  const SchemeVariantDialog({super.key, 
    required this.selectedVariant,
    required this.onVariantSelected,
  });

  @override
  _SchemeVariantDialogState createState() => _SchemeVariantDialogState();
}

class _SchemeVariantDialogState extends State<SchemeVariantDialog> {
  late String _currentVariant;

  @override
  void initState() {
    super.initState();
    _currentVariant = widget.selectedVariant;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Palette!'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            _buildVariantTile('monochrome'),
            _buildVariantTile('neutral'),
            _buildVariantTile('vibrant'),
            _buildVariantTile('tonalSpot'),
            _buildVariantTile('content'),
            _buildVariantTile('expressive'),
            _buildVariantTile('fidelity'),
            _buildVariantTile('fruitsalad'),
            _buildVariantTile('rainbow'),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.onPrimaryFixed
          ),
          onPressed: () {
            widget.onVariantSelected(_currentVariant);
            Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildVariantTile(String variant) {
    return RadioListTile<String>(
      title: Text(variant),
      value: variant,
      groupValue: _currentVariant,
      onChanged: (String? value) {
        if (value != null) {
          setState(() {
            _currentVariant = value;
          });
        }
      },
    );
  }
}
