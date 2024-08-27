import 'package:flutter/material.dart';

class SwitchTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool? defaultValue;
  final VoidCallback? onTap;

  const SwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.defaultValue,
    this.onTap,
  });

  @override
  _SwitchTileState createState() => _SwitchTileState();
}

class _SwitchTileState extends State<SwitchTile> {
  late bool _isSwitched;

  @override
  void initState() {
    super.initState();
    _isSwitched =
        widget.defaultValue ?? false; 
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Row(
          children: [
            Icon(widget.icon,
                size: 30, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isSwitched,
              onChanged: (value) {
                setState(() {
                  _isSwitched = value;
                });
              },
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveThumbColor:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              inactiveTrackColor:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
