import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/app_settings.dart';

class NewTimerScreen extends StatefulWidget {
  final String timerType;
  final Map<String, dynamic>? timerToEdit;

  const NewTimerScreen({
    super.key,
    required this.timerType,
    this.timerToEdit,
  });

  @override
  State<NewTimerScreen> createState() => _NewTimerScreenState();
}

class _NewTimerScreenState extends State<NewTimerScreen> {
  late TextEditingController _nameController;
  int _prepareTime = 10;
  int _workTime = 20;
  int _restTime = 10;
  int _rounds = 8;
  int _lapTime = 10;
  bool _isLoading = false;

  final List<dynamic> _seriesList = [
    {'work': 40, 'rest': 20, 'rounds': 10}
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.timerToEdit;
    String typeUpper = widget.timerType.toUpperCase();
    bool isCustom =
        typeUpper.contains('PERSONALIZADO') || typeUpper.contains('CUSTOM');
    bool isRounds = typeUpper == 'RONDAS' || typeUpper == 'ROUNDS';

    _nameController = TextEditingController(
      text: edit != null
          ? edit['name']
          : (isCustom ? appSettings.t('new_custom_default') : typeUpper),
    );

    _prepareTime = edit != null ? (edit['prepare_time'] ?? 10) : 10;
    _workTime = edit != null
        ? (edit['work_time'] ?? (isRounds ? 30 : 20))
        : (isRounds ? 30 : 20);
    _restTime = edit != null
        ? (edit['rest_time'] ?? (isRounds ? 15 : 10))
        : (isRounds ? 15 : 10);
    _rounds = edit != null
        ? (edit['rounds'] ?? (isRounds ? 4 : 8))
        : (isRounds ? 4 : 8);
    _lapTime = edit != null ? (edit['lap_time'] ?? 10) : 10;

    if (isCustom && edit != null) {
      _seriesList[0] = {
        'work': _workTime,
        'rest': _restTime,
        'rounds': _rounds,
      };
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatFullHms(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _saveTimer() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appSettings.t('login_required_title'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String typeUpper = widget.timerType.toUpperCase();
      bool isStopwatch =
          typeUpper.contains('CRONÓMETRO') || typeUpper.contains('STOPWATCH');
      bool isCustom =
          typeUpper.contains('PERSONALIZADO') || typeUpper.contains('CUSTOM');
      bool isRounds = typeUpper == 'RONDAS' || typeUpper == 'ROUNDS';

      int totalSeconds = 0;

      if (isStopwatch) {
        totalSeconds = 0;
      } else if (isCustom) {
        for (var serie in _seriesList) {
          int work = (serie['work'] as num).toInt();
          int rest = (serie['rest'] as num).toInt();
          int rounds = (serie['rounds'] as num).toInt();
          totalSeconds += ((work + rest) * rounds);
        }
        _workTime = (_seriesList.first['work'] as num).toInt();
        _restTime = (_seriesList.first['rest'] as num).toInt();
        _rounds = (_seriesList.first['rounds'] as num).toInt();
      } else {
        totalSeconds = (_workTime + _restTime) * _rounds;
      }

      String formattedTime =
          totalSeconds == 0 ? '00:00' : _formatDuration(totalSeconds);

      String colorHex = '0xFF8FFF00';
      String normalizedType = 'tabata';
      if (isRounds) {
        colorHex = '0xFF00E5FF';
        normalizedType = 'rondas';
      }
      if (isStopwatch) {
        colorHex = '0xFFFFC107';
        normalizedType = 'cronómetro';
      }
      if (isCustom) {
        colorHex = '0xFFFF9800';
        normalizedType = 'temporizador personalizado';
      }

      final data = {
        'user_id': user.id,
        'name':
            _nameController.text.isNotEmpty ? _nameController.text : typeUpper,
        'type': normalizedType,
        'total_duration_formatted': formattedTime,
        'color_hex': colorHex,
        'prepare_time': _prepareTime,
        'work_time': _workTime,
        'rest_time': _restTime,
        'rounds': _rounds,
        'lap_time': _lapTime,
      };

      if (widget.timerToEdit != null) {
        await Supabase.instance.client
            .from('timers')
            .update(data)
            .eq('id', widget.timerToEdit!['id'])
            .eq('user_id', user.id);
      } else {
        await Supabase.instance.client.from('timers').insert(data);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${appSettings.t('save_error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTimePickerDialog(
    String title,
    int currentSeconds,
    Function(int) onSaved, {
    int minSeconds = 0,
  }) {
    final isDark = appSettings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);
    final accentColor =
        isDark ? const Color(0xFF8FFF00) : const Color(0xFF3F51B5);

    int selectedSeconds =
        currentSeconds < minSeconds ? minSeconds : currentSeconds;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF161B2E) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            title: Text(
              '${appSettings.t('edit')} $title',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF222944)
                        : const Color(0xFFF3F4FA),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: accentColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _formatFullHms(selectedSeconds),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  width: 300,
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: isDark ? Brightness.dark : Brightness.light,
                      textTheme: CupertinoTextThemeData(
                        pickerTextStyle: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hms,
                      initialTimerDuration: Duration(seconds: selectedSeconds),
                      onTimerDurationChanged: (Duration newDuration) {
                        setDialogState(() {
                          selectedSeconds = newDuration.inSeconds < minSeconds
                              ? minSeconds
                              : newDuration.inSeconds;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text(
                  appSettings.t('cancel'),
                  style: const TextStyle(color: Colors.grey),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8FFF00),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  final finalSeconds = selectedSeconds < minSeconds
                      ? minSeconds
                      : selectedSeconds;
                  onSaved(finalSeconds);
                  Navigator.pop(context);
                },
                child: Text(
                  appSettings.t('save'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRoundsDialog(
    String title,
    int currentValue,
    Function(int) onSaved,
  ) {
    final isDark = appSettings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);
    final accentColor =
        isDark ? const Color(0xFF8FFF00) : const Color(0xFF3F51B5);

    final valueController =
        TextEditingController(text: currentValue.toString());
    valueController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: valueController.text.length,
    );

    void submitValue() {
      final parsed = int.tryParse(valueController.text.trim());
      final finalValue = (parsed == null || parsed < 1) ? 1 : parsed;
      onSaved(finalValue);
      Navigator.pop(context);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          '${appSettings.t('edit')} $title',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              appSettings.t('enter_number_hint'),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              onSubmitted: (_) => submitValue(),
              style: TextStyle(
                color: textColor,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                suffixText: appSettings.t('rounds_unit'),
                suffixStyle: TextStyle(
                  color: accentColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF222944) : const Color(0xFFF3F4FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: accentColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: accentColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              appSettings.t('cancel'),
              style: const TextStyle(color: Colors.grey),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8FFF00),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: submitValue,
            child: Text(
              appSettings.t('save'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appSettings.isDarkMode;
    final cardColor =
        isDark ? const Color(0xFF161B2E).withOpacity(0.85) : Colors.white;
    final borderColor =
        isDark ? Colors.white12 : Colors.black.withOpacity(0.05);
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);

    String typeUpper = widget.timerType.toUpperCase();
    bool isStopwatch =
        typeUpper.contains('CRONÓMETRO') || typeUpper.contains('STOPWATCH');
    bool isPersonalizado =
        typeUpper.contains('PERSONALIZADO') || typeUpper.contains('CUSTOM');
    bool isRounds = typeUpper == 'RONDAS' || typeUpper == 'ROUNDS';

    Color themeColor = const Color(0xFF8FFF00);
    if (isRounds) themeColor = const Color(0xFF00E5FF);
    if (isStopwatch) themeColor = const Color(0xFFFFC107);
    if (isPersonalizado) themeColor = Colors.orangeAccent;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_rounded, color: textColor, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.timerToEdit != null
              ? appSettings.t('edit_timer')
              : '${appSettings.t('new_prefix')} $typeUpper',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Color(0xFF8FFF00),
                        strokeWidth: 2,
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8FFF00), Color(0xFF00E5FF)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.check_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                        onPressed: _saveTimer,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0C101B), const Color(0xFF1B2340)]
                : [const Color(0xFFF3F2F7), const Color(0xFFE2E6F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              Text(
                appSettings.t('name_label'),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: widget.timerType,
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: themeColor, width: 2),
                    ),
                    child: Icon(Icons.bolt_rounded, color: themeColor),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Prepárate
              _buildCardContainer(
                isDark: isDark,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.hourglass_bottom_rounded,
                        color: Colors.amber,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appSettings.t('prepare'),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            appSettings.t('prepare_desc'),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDuration(_prepareTime),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  _showTimePickerDialog(
                    appSettings.t('prepare'),
                    _prepareTime,
                    (val) => setState(() => _prepareTime = val),
                    minSeconds: 0,
                  );
                },
              ),
              const SizedBox(height: 16),

              if (isStopwatch) ...[
                _buildCardContainer(
                  isDark: isDark,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Colors.amber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appSettings.t('lap_time'),
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              appSettings.t('lap_desc'),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatDuration(_lapTime),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  onTap: () {
                    _showTimePickerDialog(
                      appSettings.t('lap_time'),
                      _lapTime,
                      (val) => setState(() => _lapTime = val),
                      minSeconds: 1,
                    );
                  },
                ),
              ] else if (isPersonalizado) ...[
                ..._seriesList.asMap().entries.map((entry) {
                  int index = entry.key;
                  var serie = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${appSettings.t('series')} ${index + 1}',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF00E5FF)
                                    : const Color(0xFF3F51B5),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_horiz_rounded,
                                color: Colors.grey,
                              ),
                              color: isDark
                                  ? const Color(0xFF1E253E)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              onSelected: (value) {
                                setState(() {
                                  if (value == 'duplicar') {
                                    _seriesList.insert(
                                      index + 1,
                                      Map<String, dynamic>.from(serie),
                                    );
                                  } else if (value == 'eliminar' &&
                                      _seriesList.length > 1) {
                                    _seriesList.removeAt(index);
                                  }
                                });
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'duplicar',
                                  child: Text(
                                    appSettings.t('duplicate_series'),
                                    style: TextStyle(color: textColor),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'eliminar',
                                  child: Text(
                                    appSettings.t('delete_series'),
                                    style:
                                        const TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _thausRow(
                          appSettings.t('train'),
                          _formatDuration((serie['work'] as num).toInt()),
                          const Color(0xFF8FFF00),
                          textColor,
                          () {
                            _showTimePickerDialog(
                              '${appSettings.t('train')} ${appSettings.t('series')} ${index + 1}',
                              (serie['work'] as num).toInt(),
                              (val) => setState(
                                () => _seriesList[index]['work'] = val,
                              ),
                              minSeconds: 1,
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _thausRow(
                          appSettings.t('rest'),
                          _formatDuration((serie['rest'] as num).toInt()),
                          Colors.redAccent,
                          textColor,
                          () {
                            _showTimePickerDialog(
                              '${appSettings.t('rest')} ${appSettings.t('series')} ${index + 1}',
                              (serie['rest'] as num).toInt(),
                              (val) => setState(
                                () => _seriesList[index]['rest'] = val,
                              ),
                              minSeconds: 0,
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _thausRow(
                          appSettings.t('rounds_upper'),
                          '${(serie['rounds'] as num).toInt()}',
                          const Color(0xFF00E5FF),
                          textColor,
                          () {
                            _showRoundsDialog(
                              '${appSettings.t('rounds_upper')} ${appSettings.t('series')} ${index + 1}',
                              (serie['rounds'] as num).toInt(),
                              (val) => setState(
                                () => _seriesList[index]['rounds'] = val,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
                InkWell(
                  onTap: () {
                    setState(() {
                      _seriesList.add({'work': 30, 'rest': 15, 'rounds': 4});
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: isDark
                              ? const Color(0xFF8FFF00)
                              : const Color(0xFF3F51B5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          appSettings.t('add_series'),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${appSettings.t('series')} 1',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF00E5FF)
                              : const Color(0xFF3F51B5),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _thausRow(
                        appSettings.t('train'),
                        _formatDuration(_workTime),
                        const Color(0xFF8FFF00),
                        textColor,
                        () {
                          _showTimePickerDialog(
                            appSettings.t('train'),
                            _workTime,
                            (val) => setState(() => _workTime = val),
                            minSeconds: 1,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _thausRow(
                        appSettings.t('rest'),
                        _formatDuration(_restTime),
                        Colors.redAccent,
                        textColor,
                        () {
                          _showTimePickerDialog(
                            appSettings.t('rest'),
                            _restTime,
                            (val) => setState(() => _restTime = val),
                            minSeconds: 0,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _thausRow(
                        appSettings.t('rounds_upper'),
                        '$_rounds',
                        const Color(0xFF00E5FF),
                        textColor,
                        () {
                          _showRoundsDialog(
                            appSettings.t('rounds_dialog'),
                            _rounds,
                            (val) => setState(() => _rounds = val),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContainer({
    required Widget child,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
              isDark ? const Color(0xFF161B2E).withOpacity(0.85) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _thausRow(
    String title,
    String value,
    Color dotColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}