import 'dart:async';

import 'package:flutter/material.dart';
import 'package:the_reminder_app/ui/theme/app_colors.dart';
import 'package:the_reminder_app/ui/theme/app_gradients.dart';
import 'package:the_reminder_app/ui/widgets/ad_banner.dart';

class PomodoroSessionScreen extends StatefulWidget {
  final Duration workDuration;
  final Duration restDuration;

  const PomodoroSessionScreen({
    super.key,
    required this.workDuration,
    required this.restDuration,
  });

  @override
  State<PomodoroSessionScreen> createState() => _PomodoroSessionScreenState();
}

class _PomodoroSessionScreenState extends State<PomodoroSessionScreen> {
  Timer? _timer;
  late Duration _remaining;
  bool _isPaused = false;
  bool _isWorkPhase = true;

  @override
  void initState() {
    super.initState();
    _remaining = widget.workDuration;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      setState(() {
        if (_remaining > Duration.zero) {
          _remaining -= const Duration(seconds: 1);
        } else {
          if (_isWorkPhase && widget.restDuration > Duration.zero) {
            _isWorkPhase = false;
            _remaining = widget.restDuration;
          } else {
            timer.cancel();
            if (mounted) Navigator.of(context).pop();
          }
        }
      });
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _closeSession() {
    _timer?.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double _phaseProgress() {
    final totalSeconds = (_isWorkPhase
            ? widget.workDuration.inSeconds
            : widget.restDuration.inSeconds)
        .clamp(1, 1000000000)
        .toDouble();
    final completed = totalSeconds - _remaining.inSeconds;
    final progress = completed / totalSeconds;
    return progress.clamp(0.0, 1.0).toDouble();
  }

  Color _phaseColor() {
    return _isWorkPhase ? AppColors.primary : AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _isWorkPhase ? 'Deep focus mode' : 'Reset and breathe';
    final workLabel = '${widget.workDuration.inMinutes}m Focus';
    final restLabel = '${widget.restDuration.inMinutes}m Rest';
    final progress = _phaseProgress();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 380;
              final horizontal = isCompact ? 16.0 : 24.0;
              final ringSize = isCompact ? 190.0 : 230.0;

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 36, horizontal, 36),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pomodoro Session',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      workLabel,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      restLabel,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _closeSession,
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: isCompact ? 12 : 20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(horizontal, isCompact ? 18 : 28, horizontal, isCompact ? 24 : 32),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Container(
                              padding: EdgeInsets.all(isCompact ? 18 : 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.cardShadow,
                                    blurRadius: 30,
                                    offset: Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      _PhaseChip(
                                        label: 'Work',
                                        value: workLabel,
                                        isActive: _isWorkPhase,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      _PhaseChip(
                                        label: 'Break',
                                        value: restLabel,
                                        isActive: !_isWorkPhase,
                                        color: AppColors.accent,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isCompact ? 24 : 36),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: ringSize,
                                        height: ringSize,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey[200],
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: ringSize,
                                        height: ringSize,
                                        child: CircularProgressIndicator(
                                          value: progress,
                                          strokeWidth: 14,
                                          strokeCap: StrokeCap.round,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            _phaseColor(),
                                          ),
                                          backgroundColor: Colors.transparent,
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatDuration(_remaining),
                                            style: theme.textTheme.displayMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 4,
                                              color: const Color(0xFF111827),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isCompact ? 36 : 48),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _togglePause,
                                          icon: Icon(
                                            _isPaused
                                                ? Icons.play_arrow_rounded
                                                : Icons.pause_rounded,
                                          ),
                                          label: Text(_isPaused ? 'Resume' : 'Pause'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _phaseColor(),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _closeSession,
                                          icon: const Icon(Icons.stop_rounded),
                                          label: const Text('End'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.secondary,
                                            side: const BorderSide(color: AppColors.secondary),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isCompact ? 36 : 48),
                                  const AdBanner(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({
    required this.label,
    required this.value,
    required this.isActive,
    required this.color,
  });

  final String label;
  final String value;
  final bool isActive;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.12) : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color : Colors.grey.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.6,
                    color: isActive ? color : Colors.grey[600],
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
