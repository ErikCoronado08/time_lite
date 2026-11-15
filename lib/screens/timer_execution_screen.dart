import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../controllers/app_settings.dart';

class TimerExecutionScreen extends StatefulWidget {
  final String title;
  final int prepareTime;
  final int workTime;
  final int restTime;
  final int rounds;

  const TimerExecutionScreen({
    super.key,
    required this.title,
    required this.prepareTime,
    required this.workTime,
    required this.restTime,
    required this.rounds,
  });

  @override
  State<TimerExecutionScreen> createState() => _TimerExecutionScreenState();
}

class _TimerExecutionScreenState extends State<TimerExecutionScreen> {
  late int _timeLeft;
  late int _phaseTotalTime;
  int _currentRound = 1;
  String _phase = 'PREPARAR';
  Timer? _timer;
  bool _isRunning = false;

  late final AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.prepareTime;
    _phaseTotalTime = widget.prepareTime > 0 ? widget.prepareTime : 1;

    // Mantiene la pantalla encendida durante la rutina
    WakelockPlus.enable();

    // Inicializa el reproductor en el canal multimedia sin robar el foco
    _initAudio();
  }

  Future<void> _initAudio() async {
    final audioContext = AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
    );

    await AudioPlayer.global.setAudioContext(audioContext);
    _audioPlayer = AudioPlayer();
    await _audioPlayer.setAudioContext(audioContext);
  }

  Future<void> _playSound(String fileName) async {
    try {
      await _audioPlayer.play(AssetSource('audio/$fileName'));
    } catch (e) {
      debugPrint('Error al reproducir audio: $e');
    }
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 1) {
          _timeLeft--;
          if (_timeLeft <= 3 && _timeLeft > 0) {
            _playSound('beep.mp3');
          }
        } else {
          _transitionPhase();
        }
      });
    });
  }

  void _transitionPhase() {
    _playSound('start.mp3');

    if (_phase == 'PREPARAR') {
      _phase = 'ENTRENAR';
      _timeLeft = widget.workTime;
      _phaseTotalTime = widget.workTime > 0 ? widget.workTime : 1;
    } else if (_phase == 'ENTRENAR') {
      if (_currentRound >= widget.rounds) {
        _phase = 'FIN';
        _timeLeft = 0;
        _phaseTotalTime = 1;
        _timer?.cancel();
        _isRunning = false;
        WakelockPlus.disable();
      } else {
        _phase = 'DESCANSAR';
        _timeLeft = widget.restTime;
        _phaseTotalTime = widget.restTime > 0 ? widget.restTime : 1;
      }
    } else if (_phase == 'DESCANSAR') {
      _phase = 'ENTRENAR';
      _currentRound++;
      _timeLeft = widget.workTime;
      _phaseTotalTime = widget.workTime > 0 ? widget.workTime : 1;
    }
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  List<Color> _getGradientColors() {
    switch (_phase) {
      case 'PREPARAR':
        return [const Color(0xFFFFA000), const Color(0xFFFF6F00)];
      case 'ENTRENAR':
        return [const Color(0xFF1B5E20), const Color(0xFF4CAF50)];
      case 'DESCANSAR':
        return [const Color(0xFFB71C1C), const Color(0xFFE53935)];
      case 'FIN':
        return [const Color(0xFF0D47A1), const Color(0xFF00ACC1)];
      default:
        return [const Color(0xFF0C101B), const Color(0xFF1B2340)];
    }
  }

  Color _getAccentColor() {
    switch (_phase) {
      case 'PREPARAR':
        return Colors.amberAccent;
      case 'ENTRENAR':
        return const Color(0xFF8FFF00);
      case 'DESCANSAR':
        return const Color(0xFFFF8A80);
      case 'FIN':
        return const Color(0xFF00E5FF);
      default:
        return const Color(0xFF8FFF00);
    }
  }

  String _getPhaseLabel() {
    switch (_phase) {
      case 'PREPARAR':
        return appSettings.t('phase_prepare');
      case 'ENTRENAR':
        return appSettings.t('phase_train');
      case 'DESCANSAR':
        return appSettings.t('phase_rest');
      case 'FIN':
        return appSettings.t('completed');
      default:
        return _phase;
    }
  }

  @override
  Widget build(BuildContext context) {
    String minutes = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    String seconds = (_timeLeft % 60).toString().padLeft(2, '0');
    double progress = _phase == 'FIN'
        ? 1.0
        : (_timeLeft / _phaseTotalTime).clamp(0.0, 1.0);
    final accent = _getAccentColor();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradientColors(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Text(
                      widget.title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getPhaseLabel(),
                      style: TextStyle(
                        color: accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 265,
                        height: 265,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 14,
                          backgroundColor: Colors.white.withOpacity(0.18),
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$minutes:$seconds',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          if (_phase != 'FIN' && _phase != 'PREPARAR')
                            Text(
                              '${appSettings.t('round_upper')} $_currentRound / ${widget.rounds}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 48.0),
                child: GestureDetector(
                  onTap: _phase == 'FIN'
                      ? () => Navigator.pop(context)
                      : (_isRunning ? _pauseTimer : _startTimer),
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      _phase == 'FIN'
                          ? Icons.check_rounded
                          : (_isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded),
                      color: _getGradientColors().first,
                      size: 46,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}