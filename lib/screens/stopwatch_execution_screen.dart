import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/app_settings.dart';

class StopwatchExecutionScreen extends StatefulWidget {
  final String title;

  const StopwatchExecutionScreen({
    super.key,
    required this.title,
  });

  @override
  State<StopwatchExecutionScreen> createState() =>
      _StopwatchExecutionScreenState();
}

class _StopwatchExecutionScreenState extends State<StopwatchExecutionScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<String> _laps = [];

  void _startStopwatch() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  void _pauseStopwatch() {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {});
  }

  void _resetStopwatch() {
    _stopwatch.reset();
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {
      _laps.clear();
    });
  }

  void _addLap() {
    if (_stopwatch.isRunning) {
      final elapsed = _stopwatch.elapsed;
      String minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
      String seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
      String milliseconds =
          ((elapsed.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');

      setState(() {
        _laps.insert(0, '$minutes:$seconds.$milliseconds');
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appSettings.isDarkMode;
    final elapsed = _stopwatch.elapsed;
    String minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    String milliseconds =
        ((elapsed.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');

    bool isRunning = _stopwatch.isRunning;
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0C101B), const Color(0xFF232018)]
                : [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: textColor,
                          size: 26,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Text(
                      widget.title.toUpperCase(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pantalla digital estilizada
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 28),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF161B2E).withOpacity(0.85)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFFFFC107).withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$minutes:$seconds.$milliseconds',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFFFC107)
                          : const Color(0xFF1A237E),
                      fontSize: 58,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Lista de vueltas
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _laps.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${appSettings.t('lap')} ${_laps.length - index}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            _laps[index],
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Controles inferiores
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? Colors.white12 : Colors.white,
                        foregroundColor: textColor,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(22),
                        elevation: 0,
                      ),
                      onPressed: isRunning
                          ? _addLap
                          : (elapsed.inMilliseconds > 0
                              ? _resetStopwatch
                              : null),
                      child: Icon(
                        isRunning ? Icons.flag_rounded : Icons.refresh_rounded,
                        size: 30,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC107).withOpacity(0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(28),
                        ),
                        onPressed: () {
                          if (isRunning) {
                            _pauseStopwatch();
                          } else {
                            _startStopwatch();
                          }
                        },
                        child: Icon(
                          isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 42,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}