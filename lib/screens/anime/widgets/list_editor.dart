import 'dart:async';

import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/common/slider_semantics.dart';
import 'package:anymex/widgets/custom_widgets/anymex_button.dart';
import 'package:anymex/widgets/custom_widgets/anymex_image.dart';
import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ListEditorModal extends StatefulWidget {
  final RxString animeStatus;
  final RxDouble animeScore;
  final RxInt animeProgress;
  final Rx<dynamic> currentAnime;
  final Media media;
  final Function(String, double, String, int, DateTime?, DateTime?) onUpdate;
  final Function(String) onDelete;
  final bool isManga;

  const ListEditorModal({
    super.key,
    required this.animeStatus,
    required this.animeScore,
    required this.animeProgress,
    required this.currentAnime,
    required this.media,
    required this.onUpdate,
    required this.onDelete,
    required this.isManga,
  });

  @override
  State<ListEditorModal> createState() => _ListEditorModalState();
}

class _ListEditorModalState extends State<ListEditorModal>
    with SingleTickerProviderStateMixin {
  late String _localStatus;
  late double _localScore;
  late int _localProgress;
  DateTime? _startedAt;
  DateTime? _completedAt;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  Timer? _repeatTimer;
  Timer? _accelTimer;
  int _repeatMs = 150;

  // (value, label, icon)
  static const _statuses = [
    ('CURRENT',   'Watching',  Icons.play_circle_rounded),
    ('PLANNING',  'Planning',  Icons.bookmark_add_rounded),
    ('COMPLETED', 'Completed', Icons.check_circle_rounded),
    ('PAUSED',    'Paused',    Icons.pause_circle_rounded),
    ('DROPPED',   'Dropped',   Icons.cancel_rounded),
    ('REPEATING', 'Repeating', Icons.repeat_rounded),
  ];

  // Status accent colours — subtle tints so they read on any theme
  static const _statusColors = {
    'CURRENT':   Color(0xFF4CAF50),
    'PLANNING':  Color(0xFF2196F3),
    'COMPLETED': Color(0xFF9C27B0),
    'PAUSED':    Color(0xFFFF9800),
    'DROPPED':   Color(0xFFF44336),
    'REPEATING': Color(0xFF00BCD4),
  };

  @override
  void initState() {
    super.initState();
    _localStatus   = widget.animeStatus.value.isEmpty ? 'CURRENT' : widget.animeStatus.value;
    _localScore    = widget.animeScore.value;
    _localProgress = widget.animeProgress.value;

    final tracked = widget.currentAnime.value;
    if (tracked != null) {
      _startedAt   = tracked.startedAt;
      _completedAt = tracked.completedAt;
    }

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _stopRepeat();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── computed ─────────────────────────────────────────────────────────────────

  int? get _maxTotal {
    final raw = widget.isManga ? widget.media.totalChapters : widget.media.totalEpisodes;
    if (raw == null || raw == '?' || raw == '??' || raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  String get _displayTotal {
    final t = widget.isManga ? widget.media.totalChapters : widget.media.totalEpisodes;
    return (t == null || t.isEmpty) ? '?' : t;
  }

  double get _progressPct {
    final max = _maxTotal;
    if (max == null || max == 0) return 0;
    return (_localProgress / max).clamp(0.0, 1.0);
  }

  Color get _statusAccent =>
      _statusColors[_localStatus] ?? const Color(0xFF4CAF50);

  String _statusLabel(String v) {
    if (v == 'CURRENT') return widget.isManga ? 'Reading' : 'Watching';
    return _statuses.firstWhere((s) => s.$1 == v,
        orElse: () => (v, v, Icons.circle)).$2;
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Not set';
    return '${d.day.toString().padLeft(2, '0')} / '
        '${d.month.toString().padLeft(2, '0')} / ${d.year}';
  }

  // ── interactions ─────────────────────────────────────────────────────────────

  void _setStatus(String next) {
    final prev = _localStatus;
    setState(() {
      _localStatus = next;
      if (next == 'CURRENT'   && _startedAt == null) _startedAt = DateTime.now();
      if (next == 'COMPLETED') {
        _startedAt   ??= DateTime.now();
        _completedAt ??= DateTime.now();
      }
      if (prev == 'COMPLETED' && next != 'COMPLETED') _completedAt = null;
    });
    HapticFeedback.selectionClick();
  }

  void _step(bool up) {
    final max = _maxTotal;
    if (up  && (max == null || _localProgress < max)) {
      setState(() => _localProgress++);
      HapticFeedback.selectionClick();
    } else if (!up && _localProgress > 0) {
      setState(() => _localProgress--);
      HapticFeedback.selectionClick();
    }
  }

  void _startRepeat(bool up) {
    _repeatMs = 150;
    _stopRepeat();
    _scheduleStep(up);
    _accelTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _repeatMs = (_repeatMs * 0.6).clamp(30, 150).toInt();
    });
  }

  void _scheduleStep(bool up) {
    _repeatTimer = Timer(Duration(milliseconds: _repeatMs), () {
      if (!mounted) return;
      _step(up);
      _scheduleStep(up);
    });
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _accelTimer?.cancel();
    _repeatTimer = _accelTimer = null;
    _repeatMs = 150;
  }

  void _typeProgress() {
    final ctrl = TextEditingController(text: '$_localProgress')
      ..selection = TextSelection(baseOffset: 0, extentOffset: '$_localProgress'.length);
    final c = context.colors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.isManga ? Icons.menu_book_rounded : Icons.play_circle_rounded,
                color: c.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Set ${widget.isManga ? 'Chapter' : 'Episode'}',
              style: TextStyle(
                  color: c.onSurface, fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: TextStyle(
              color: c.onSurface, fontSize: 28, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            filled: true,
            fillColor: c.surfaceContainerHighest,
            hintText: '0',
            hintStyle: TextStyle(color: c.onSurfaceVariant),
            suffixText: '/ $_displayTotal',
            suffixStyle: TextStyle(
                color: c.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: c.onSurfaceVariant,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              final val = int.tryParse(ctrl.text);
              if (val != null && val >= 0) {
                final max = _maxTotal;
                setState(() =>
                    _localProgress = max != null ? val.clamp(0, max) : val);
              }
              Navigator.pop(ctx);
            },
            child: Text('Confirm',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: c.onPrimary)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startedAt  ?? DateTime.now())
        : (_completedAt ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) =>
          Theme(data: Theme.of(ctx).copyWith(colorScheme: ctx.colors), child: child!),
    );
    if (picked != null) {
      setState(() => isStart ? _startedAt = picked : _completedAt = picked);
    }
  }

  // ── root ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _handle(c),
              _header(context, c),
              _divider(c),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statusSection(context, c),
                    const SizedBox(height: 20),
                    _progressSection(context, c),
                    const SizedBox(height: 20),
                    _scoreSection(context, c),
                    const SizedBox(height: 20),
                    _datesSection(context, c),
                    const SizedBox(height: 28),
                    _actions(context, c),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── drag handle ──────────────────────────────────────────────────────────────

  Widget _handle(ColorScheme c) => Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: c.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  // ── header ───────────────────────────────────────────────────────────────────

  Widget _header(BuildContext context, ColorScheme c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Poster
          Hero(
            tag: 'editor_poster_${widget.media.id}',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: c.shadow.opaque(0.15, iReallyMeanIt: true),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AnymeXImage(
                  imageUrl: widget.media.poster,
                  width: 56,
                  height: 78,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Title block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.media.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: c.onSurface,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Live status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _statusAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _statusLabel(_localStatus),
                            style: TextStyle(
                              color: _statusAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isManga ? 'Manga' : 'Anime',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: c.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Close
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded,
                    size: 18, color: c.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme c) => Divider(
        height: 1,
        thickness: 1,
        color: c.outlineVariant.opaque(0.5, iReallyMeanIt: true),
      );

  // ── section label ─────────────────────────────────────────────────────────────

  Widget _label(BuildContext context, ColorScheme c, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: c.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
        ),
      );

  // ── status chips ──────────────────────────────────────────────────────────────

  Widget _statusSection(BuildContext context, ColorScheme c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, c, 'Status'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _statuses.map((s) {
              final val      = s.$1;
              final label    = val == 'CURRENT'
                  ? (widget.isManga ? 'Reading' : 'Watching')
                  : s.$2;
              final icon     = s.$3;
              final selected = _localStatus == val;
              final accent   = _statusColors[val] ?? c.primary;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _setStatus(val),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? accent.withValues(alpha: 0.15)
                          : c.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? accent.withValues(alpha: 0.6)
                            : c.outlineVariant.opaque(0.5, iReallyMeanIt: true),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 15,
                          color: selected ? accent : c.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: selected ? accent : c.onSurfaceVariant,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── progress ──────────────────────────────────────────────────────────────────

  Widget _progressSection(BuildContext context, ColorScheme c) {
    final max    = _maxTotal;
    final hasMax = max != null;
    final pct    = _progressPct;
    final unit   = widget.isManga ? 'Chapter' : 'Episode';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, c, unit),
        Container(
          decoration: BoxDecoration(
            color: c.surfaceContainer.opaque(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: c.outlineVariant.opaque(0.5, iReallyMeanIt: true),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Decrement
                  _stepBtn(
                    context, c,
                    icon: Icons.remove_rounded,
                    enabled: _localProgress > 0,
                    filled: false,
                    onTap: () => _step(false),
                    onLongStart: (_) => _startRepeat(false),
                    onLongEnd:   (_) => _stopRepeat(),
                  ),
                  // Counter — tap to type
                  Expanded(
                    child: GestureDetector(
                      onTap: _typeProgress,
                      child: Column(
                        children: [
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(children: [
                              TextSpan(
                                text: '$_localProgress',
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: c.onSurface,
                                    ),
                              ),
                              TextSpan(
                                text: ' / $_displayTotal',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: c.onSurfaceVariant,
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app_rounded,
                                  size: 11,
                                  color: c.onSurfaceVariant
                                      .opaque(0.4, iReallyMeanIt: true)),
                              const SizedBox(width: 3),
                              Text(
                                'tap to enter',
                                style: TextStyle(
                                  color: c.onSurfaceVariant
                                      .opaque(0.4, iReallyMeanIt: true),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (hasMax) ...[
                            const SizedBox(height: 3),
                            Text(
                              '${(pct * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: c.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Increment
                  _stepBtn(
                    context, c,
                    icon: Icons.add_rounded,
                    enabled: !hasMax || _localProgress < max,
                    filled: true,
                    onTap: () => _step(true),
                    onLongStart: (_) => _startRepeat(true),
                    onLongEnd:   (_) => _stopRepeat(),
                  ),
                ],
              ),
              if (hasMax) ...[
                const SizedBox(height: 14),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: c.outlineVariant
                            .opaque(0.3, iReallyMeanIt: true),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: pct,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              c.primary,
                              c.primaryContainer,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepBtn(
    BuildContext context,
    ColorScheme c, {
    required IconData icon,
    required bool enabled,
    required bool filled,
    required VoidCallback onTap,
    required void Function(LongPressStartDetails) onLongStart,
    required void Function(LongPressEndDetails) onLongEnd,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      onLongPressStart: enabled ? onLongStart : null,
      onLongPressEnd:   enabled ? onLongEnd   : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: !enabled
              ? c.surfaceContainerHighest.opaque(0.4, iReallyMeanIt: true)
              : filled
                  ? c.primary
                  : c.primaryContainer.opaque(0.7, iReallyMeanIt: true),
        ),
        child: Icon(
          icon,
          size: 22,
          color: !enabled
              ? c.onSurfaceVariant.opaque(0.3, iReallyMeanIt: true)
              : filled
                  ? c.onPrimary
                  : c.primary,
        ),
      ),
    );
  }

  // ── score ─────────────────────────────────────────────────────────────────────

  Widget _scoreSection(BuildContext context, ColorScheme c) {
    // Map 0–10 to a colour: red → yellow → green
    Color scoreColor() {
      if (_localScore < 4)  return const Color(0xFFF44336);
      if (_localScore < 6)  return const Color(0xFFFF9800);
      if (_localScore < 8)  return const Color(0xFFFFEB3B);
      return const Color(0xFF4CAF50);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _label(context, c, 'Score')),
            // Live pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: scoreColor().withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: scoreColor().withValues(alpha: 0.4), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded,
                      size: 14, color: scoreColor()),
                  const SizedBox(width: 4),
                  Text(
                    _localScore.toStringAsFixed(1),
                    style: TextStyle(
                      color: scoreColor(),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    ' / 10',
                    style: TextStyle(
                      color: scoreColor().withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: c.surfaceContainer.opaque(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: c.outlineVariant.opaque(0.5, iReallyMeanIt: true),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Column(
            children: [
              CustomSlider(
                value: _localScore,
                min: 0.0,
                max: 10.0,
                divisions: 100,
                label: _localScore.toStringAsFixed(1),
                activeColor: scoreColor(),
                inactiveColor:
                    c.outlineVariant.opaque(0.3, iReallyMeanIt: true),
                onChanged: (v) => setState(() => _localScore = v),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Awful',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: c.onSurfaceVariant
                                .opaque(0.5, iReallyMeanIt: true))),
                    Text('Average',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: c.onSurfaceVariant
                                .opaque(0.5, iReallyMeanIt: true))),
                    Text('Masterpiece',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: c.onSurfaceVariant
                                .opaque(0.5, iReallyMeanIt: true))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── dates ─────────────────────────────────────────────────────────────────────

  Widget _datesSection(BuildContext context, ColorScheme c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, c, 'Dates'),
        Row(
          children: [
            Expanded(
              child: _dateTile(context, c,
                  label: 'Started',
                  icon: Icons.play_arrow_rounded,
                  date: _startedAt,
                  onTap: () => _pickDate(isStart: true),
                  onClear: _startedAt != null
                      ? () => setState(() => _startedAt = null)
                      : null),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dateTile(context, c,
                  label: 'Finished',
                  icon: Icons.flag_rounded,
                  date: _completedAt,
                  onTap: () => _pickDate(isStart: false),
                  onClear: _completedAt != null
                      ? () => setState(() => _completedAt = null)
                      : null),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dateTile(
    BuildContext context,
    ColorScheme c, {
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final has = date != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: has
              ? c.primaryContainer.opaque(0.5, iReallyMeanIt: true)
              : c.surfaceContainer.opaque(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: has
                ? c.primary.withValues(alpha: 0.4)
                : c.outlineVariant.opaque(0.5, iReallyMeanIt: true),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: has ? c.primary : c.onSurfaceVariant),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        color: c.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      )),
                  const SizedBox(height: 3),
                  Text(
                    _fmtDate(date),
                    style: TextStyle(
                      color: has
                          ? c.onSurface
                          : c.onSurfaceVariant
                              .opaque(0.4, iReallyMeanIt: true),
                      fontSize: 12,
                      fontWeight: has ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.close_rounded,
                      size: 14,
                      color: c.onSurfaceVariant
                          .opaque(0.5, iReallyMeanIt: true)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── action buttons ────────────────────────────────────────────────────────────

  Widget _actions(BuildContext context, ColorScheme c) {
    return Column(
      children: [
        // Save
        AnymexButton(
          onTap: () {
            Get.back();
            widget.onUpdate(
              widget.media.id,
              _localScore,
              _localStatus,
              _localProgress,
              _startedAt,
              _completedAt,
            );
          },
          height: 54,
          width: double.infinity,
          radius: 16,
          color: c.primary,
          border: BorderSide.none,
          enableGlow: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_rounded, color: c.onPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Save Changes',
                style: TextStyle(
                  color: c.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Delete — subtle so it doesn't compete with Save
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              widget.onDelete(widget.media.id);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 46,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: c.error.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline_rounded,
                      color: c.error.opaque(0.8, iReallyMeanIt: true),
                      size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Remove from List',
                    style: TextStyle(
                      color: c.error.opaque(0.8, iReallyMeanIt: true),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
