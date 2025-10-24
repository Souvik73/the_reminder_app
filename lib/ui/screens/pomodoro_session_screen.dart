import 'dart:async';

import 'package:flutter/material.dart';
import 'package:the_reminder_app/ui/theme/app_colors.dart';
import 'package:the_reminder_app/ui/widgets/gradient_page_shell.dart';

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
  late Duration _restRemaining;
  bool _isPaused = false;
  bool _isWorkPhase = true;

  @override
  void initState() {
    super.initState();
    _remaining = widget.workDuration;
    _restRemaining = widget.restDuration;
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
            _remaining = _restRemaining;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientPageShell(
      icon: _isWorkPhase ? Icons.timer_rounded : Icons.self_improvement,
      title: _isWorkPhase ? 'Focus Session' : 'Rest Interval',
      subtitle: _isWorkPhase
          ? 'Stay focused and keep the momentum going'
          : 'Take a breath before the next focus block',
      actions: [
        IconButton(
          onPressed: _closeSession,
          icon: const Icon(Icons.close_rounded),
          color: Colors.white,
        ),
      ],
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 26,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isWorkPhase ? 'Focus time' : 'Rest break',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _formatDuration(_remaining),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _togglePause,
                    icon: Icon(
                      _isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                    ),
                    label: Text(_isPaused ? 'Resume' : 'Pause'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: _closeSession,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('End'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
