import 'package:aurora/components/common/custom_tile_ui.dart';
import 'package:flutter/material.dart';

class TileWithSlider extends StatefulWidget {
  const TileWithSlider({
    super.key,
    required this.sliderValue,
    required this.onChanged,
    required this.title,
    required this.description,
    required this.icon,
    required this.min,
    required this.max,
    this.divisions,
    this.iconSize,
  });
  final String title;
  final String description;
  final double sliderValue;
  final ValueChanged<double> onChanged;
  final IconData icon;
  final double min;
  final double max;
  final int? divisions;
  final double? iconSize;

  @override
  State<TileWithSlider> createState() => _TileWithSliderState();
}

class _TileWithSliderState extends State<TileWithSlider> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTileUi(
          icon: widget.icon,
          title: widget.title,
          description: widget.description,
          size: widget.iconSize ?? 30,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Text(widget.sliderValue.floor().toString(),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
              ),
              Expanded(
                child: Slider(
                  value: widget.sliderValue,
                  onChanged: (newValue) => widget.onChanged(newValue),
                  min: widget.min,
                  max: widget.max,
                  label: widget.sliderValue.floor().toString(),
                  divisions: widget.divisions ?? (widget.max * 10).toInt(),
                ),
              ),
              SizedBox(
                width: 20,
                child: Text(widget.max.floor().toString(),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
