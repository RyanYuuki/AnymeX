import 'package:anymex/controllers/profile/profile_manager.dart';
import 'package:anymex/models/Service/app_profile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotLockDialog extends StatefulWidget {
  final AppProfile profile;
  const ForgotLockDialog({super.key, required this.profile});

  @override
  State<ForgotLockDialog> createState() => _ForgotLockDialogState();
}

class _ForgotLockDialogState extends State<ForgotLockDialog> {
  final _answerController = TextEditingController();
  bool _isError = false;
  String _errorMessage = '';
  bool _isLoading = false;
  int _selectedQuestionIndex = 0;

  List<String> get _questions => widget.profile.securityQuestionTexts;

  @override
  void initState() {
    super.initState();
    if (_questions.isEmpty) return;
    _selectedQuestionIndex = 0;
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_questions.isEmpty) {
      return AlertDialog(
        backgroundColor: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('No Recovery Questions'),
        content: const Text('This profile has no recovery questions set.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }

    final currentQuestion = _questions[_selectedQuestionIndex];
    final hasMultiple = _questions.length > 1;

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded,
                  color: Colors.orange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Recovery',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasMultiple
                ? 'Pick a question and answer it to remove the lock from "${widget.profile.name}"'
                : 'Answer correctly to remove the lock from "${widget.profile.name}"',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasMultiple) ...[
            DropdownButtonFormField<int>(
              value: _selectedQuestionIndex,
              isExpanded: true,
              isDense: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.surface,
                prefixIcon: Icon(Icons.quiz_rounded,
                    size: 18, color: colorScheme.primary),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _questions.asMap().entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    'Q${entry.key + 1}: ${entry.value}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedQuestionIndex = val;
                    _isError = false;
                    _errorMessage = '';
                    _answerController.clear();
                  });
                }
              },
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.15),
                ),
              ),
              child: Text(
                currentQuestion,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
          if (hasMultiple) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.15),
                ),
              ),
              child: Text(
                currentQuestion,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _answerController,
            autofocus: true,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Your answer',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: _isError
                    ? const BorderSide(color: Colors.red, width: 2)
                    : BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {
              _isError = false;
              _errorMessage = '';
            }),
          ),
          if (_isError) ...[
            const SizedBox(height: 8),
            Text(_errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 8),
          Text(
            'The lock will be removed. You can set a new one later.',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              _isLoading ? null : () => Navigator.pop(context, false),
          child: Text('Cancel',
              style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7))),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () {
                  final answer = _answerController.text.trim();
                  if (answer.isEmpty) {
                    setState(() {
                      _isError = true;
                      _errorMessage = 'Please enter your answer';
                    });
                    return;
                  }
                  setState(() => _isLoading = true);
                  final manager = Get.find<ProfileManager>();
                  if (manager.verifySecurityAnswer(
                      widget.profile.id, answer)) {
                    manager.bypassLock(widget.profile.id);
                    Navigator.pop(context, true);
                  } else {
                    setState(() {
                      _isError = true;
                      _errorMessage = 'Wrong answer. Try again.';
                      _isLoading = false;
                    });
                    _answerController.clear();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Verify & Remove Lock',
                  style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
