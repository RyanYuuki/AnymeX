import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ListEditorModal extends StatefulWidget {
  final String initialStatus;
  final int initialProgress;
  final double initialScore;
  final String totalEpisodes;
  final Function(String status, int progress, double score) onSave;
  final VoidCallback onDelete;

  const ListEditorModal({
    super.key,
    required this.initialStatus,
    required this.initialProgress,
    required this.initialScore,
    required this.totalEpisodes,
    required this.onSave,
    required this.onDelete,
  });

  @override
  _ListEditorModalState createState() => _ListEditorModalState();

  static void show(
    BuildContext context, {
    required String initialStatus,
    required int initialProgress,
    required double initialScore,
    required String totalEpisodes,
    required Function(String status, int progress, double score) onSave,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).colorScheme.surface,
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return ListEditorModal(
          initialStatus: initialStatus,
          initialProgress: initialProgress,
          initialScore: initialScore,
          totalEpisodes: totalEpisodes,
          onSave: onSave,
          onDelete: onDelete,
        );
      },
    );
  }
}

class _ListEditorModalState extends State<ListEditorModal> {
  late String selectedStatus;
  late int progress;
  late double score;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.initialStatus;
    progress = widget.initialProgress;
    score = widget.initialScore;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 30.0,
          right: 30.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 40.0,
          top: 20.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'List Editor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildStatusDropdown(),
            const SizedBox(height: 20),
            _buildProgressInput(),
            const SizedBox(height: 20),
            _buildScoreInput(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return SizedBox(
      height: 55,
      child: InputDecorator(
        decoration: _getInputDecoration(Icons.playlist_add, 'Status'),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: selectedStatus,
            items: [
              'PLANNING',
              'CURRENT',
              'COMPLETED',
              'REWATCHING',
              'PAUSED',
              'DROPPED',
            ].map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (String? newStatus) {
              setState(() {
                selectedStatus = newStatus!;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgressInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SizedBox(
            height: 55,
            child: TextFormField(
              keyboardType: TextInputType.number,
              decoration: _getInputDecoration(Icons.add, 'Progress',
                  suffixText: '/${widget.totalEpisodes}'),
              initialValue: progress.toString(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (String value) {
                int? newProgress = int.tryParse(value);
                if (newProgress != null && newProgress >= 0) {
                  setState(() {
                    if (widget.totalEpisodes == '?') {
                      progress = newProgress;
                    } else {
                      int totalEp = int.parse(widget.totalEpisodes);
                      progress = newProgress <= totalEp ? newProgress : totalEp;
                    }
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () {
              setState(() {
                if (widget.totalEpisodes == '?' ||
                    progress < int.parse(widget.totalEpisodes)) {
                  progress += 1;
                }
              });
            },
            child: Text('+1',
                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreInput() {
    return SizedBox(
      height: 55,
      child: TextFormField(
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _getInputDecoration(Icons.star, 'Score', suffixText: '/10'),
        initialValue: score.toString(),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
        ],
        onChanged: (String value) {
          double? newScore = double.tryParse(value);
          if (newScore != null) {
            setState(() {
              score = newScore.clamp(1.0, 10.0);
            });
          }
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onDelete();
          },
          style: _getButtonStyle(),
          child: const Text('Delete'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onSave(selectedStatus, progress, score);
          },
          style: _getButtonStyle(),
          child: const Text('Save'),
        ),
      ],
    );
  }

  InputDecoration _getInputDecoration(IconData icon, String label,
      {String? suffixText}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      prefixIcon: Icon(icon),
      suffixText: suffixText,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          width: 1,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          width: 1,
          color: Theme.of(context).colorScheme.primary,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'Poppins-Bold',
      ),
    );
  }

  ButtonStyle _getButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(color: Theme.of(context).colorScheme.inversePrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}
