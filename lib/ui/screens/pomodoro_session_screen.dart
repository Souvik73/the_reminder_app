import 'dart:async';

import 'package:flutter/material.dart';

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isWorkPhase ? 'Focus time' : 'Rest',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _formatDuration(_remaining),
                style: theme.textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 48,
                    color: Colors.white,
                    onPressed: _togglePause,
                    icon: Icon(
                      _isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                    ),
                  ),
                  const SizedBox(width: 32),
                  IconButton(
                    iconSize: 48,
                    color: Colors.white70,
                    onPressed: _closeSession,
                    icon: const Icon(Icons.close_rounded),
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
