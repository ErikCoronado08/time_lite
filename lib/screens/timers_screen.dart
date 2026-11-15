import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/app_settings.dart';
import 'auth_screen.dart';
import 'new_timer_screen.dart';
import 'timer_execution_screen.dart';
import 'stopwatch_execution_screen.dart';
import 'running_screen.dart';
import 'settings_screen.dart';

class TimersScreen extends StatefulWidget {
  const TimersScreen({super.key});

  @override
  State<TimersScreen> createState() => _TimersScreenState();
}

class _TimersScreenState extends State<TimersScreen> {
  late Future<List<dynamic>> _future;
  late final StreamSubscription<AuthState> _authSubscription;
  final int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshTimers();

    // Detecta automáticamente cuando el usuario inicia o cierra sesión
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        _refreshTimers();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  List<dynamic> _getDefaultTimers() {
    final isEs = appSettings.languageCode == 'es';
    return [
      {
        'id': 'default_tabata',
        'is_default': true,
        'name': 'TABATA HIIT',
        'type': 'tabata',
        'total_duration_formatted': '04:00',
        'color_hex': '0xFF8FFF00',
        'prepare_time': 10,
        'work_time': 20,
        'rest_time': 10,
        'rounds': 8,
      },
      {
        'id': 'default_rounds',
        'is_default': true,
        'name': isEs ? 'RONDAS BOXEO' : 'BOXING ROUNDS',
        'type': 'rondas',
        'total_duration_formatted': '09:00',
        'color_hex': '0xFF00E5FF',
        'prepare_time': 10,
        'work_time': 120,
        'rest_time': 60,
        'rounds': 3,
      },
      {
        'id': 'default_stopwatch',
        'is_default': true,
        'name': isEs ? 'CRONÓMETRO LIBRE' : 'OPEN STOPWATCH',
        'type': 'cronómetro',
        'total_duration_formatted': '00:00',
        'color_hex': '0xFFFFC107',
        'prepare_time': 0,
        'work_time': 0,
        'rest_time': 0,
        'rounds': 1,
      },
    ];
  }

  Future<List<dynamic>> _fetchTimers() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return _getDefaultTimers();
    }

    final response = await Supabase.instance.client
        .from('timers')
        .select()
        .eq('user_id', user.id)
        .order('id', ascending: false);

    return response;
  }

  void _refreshTimers() {
    setState(() {
      _future = _fetchTimers();
    });
  }

  void _promptLoginDialog() {
    final isDark = appSettings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          appSettings.t('login_required_title'),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        content: Text(
          appSettings.t('login_required_desc'),
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              appSettings.t('cancel'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8FFF00),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final loggedIn = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
              if (loggedIn == true && mounted) {
                _refreshTimers();
              }
            },
            child: Text(
              appSettings.t('login'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) {
        final isDark = appSettings.isDarkMode;
        final user = Supabase.instance.client.auth.currentUser;
        final userName = user != null
            ? (user.userMetadata?['full_name']?.toString() ??
                user.email?.split('@')[0] ??
                'Atleta')
            : appSettings.t('guest_athlete');
        final textColor = isDark ? Colors.white : const Color(0xFF1A237E);

        return Scaffold(
          extendBody: true,
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
              bottom: false,
              child: Column(
                children: [
                  // Cabecera fitness con saludo y acceso rápido a perfil
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                            if (mounted) _refreshTimers();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF8FFF00), Color(0xFF00E5FF)],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: isDark
                                  ? const Color(0xFF161B2E)
                                  : Colors.white,
                              child: Icon(
                                user != null
                                    ? Icons.person_rounded
                                    : Icons.person_outline_rounded,
                                color: isDark
                                    ? const Color(0xFF8FFF00)
                                    : const Color(0xFF3F51B5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hola, $userName',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                user != null
                                    ? appSettings.t('my_timers')
                                    : appSettings.t('default_timers'),
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF00E5FF)
                                      : const Color(0xFF5C6BC0),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: textColor,
                            ),
                            onPressed: _refreshTimers,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lista de temporizadores (propios o predeterminados)
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF8FFF00),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'Error: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          );
                        }

                        final timers = user == null
                            ? _getDefaultTimers()
                            : (snapshot.data ?? []);

                        if (user != null && timers.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8FFF00)
                                          .withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.timer_outlined,
                                      size: 48,
                                      color: Color(0xFF8FFF00),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    appSettings.t('no_timers_yet'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    appSettings.t('no_timers_desc'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                          itemCount: timers.length,
                          itemBuilder: (context, index) {
                            final timer =
                                Map<String, dynamic>.from(timers[index] as Map);
                            Color cardColor = Color(
                              int.parse(timer['color_hex'] ?? '0xFF4CAF50'),
                            );
                            bool isStopwatch = (timer['type'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains('cronómetro');

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14.0),
                              child: GestureDetector(
                                onTap: () {
                                  if (isStopwatch) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            StopwatchExecutionScreen(
                                          title: timer['name'] ?? 'CRONÓMETRO',
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TimerExecutionScreen(
                                          title: timer['name'] ?? 'TABATA',
                                          prepareTime:
                                              timer['prepare_time'] ?? 10,
                                          workTime: timer['work_time'] ?? 20,
                                          restTime: timer['rest_time'] ?? 10,
                                          rounds: timer['rounds'] ?? 8,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: _buildTimerCard(
                                  timer,
                                  cardColor,
                                  isDark,
                                  isStopwatch: isStopwatch,
                                  isDefault: timer['is_default'] == true ||
                                      user == null,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF8FFF00), Color(0xFF00E5FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8FFF00).withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child:
                  const Icon(Icons.add_rounded, color: Colors.black, size: 32),
              onPressed: () {
                if (Supabase.instance.client.auth.currentUser == null) {
                  _promptLoginDialog();
                } else {
                  _showAddTimerBottomSheet(context);
                }
              },
            ),
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF161B2E).withOpacity(0.95)
                  : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor:
                    isDark ? const Color(0xFF8FFF00) : const Color(0xFF3F51B5),
                unselectedItemColor: Colors.grey,
                currentIndex: _currentIndex,
                onTap: (index) async {
                  if (index == 1) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RunningScreen(),
                      ),
                    );
                  } else if (index == 2) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                    if (mounted) _refreshTimers();
                  }
                },
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.bolt_rounded),
                    label: appSettings.t('tab_timers'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.directions_run_rounded),
                    label: appSettings.t('tab_run'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.tune_rounded),
                    label: appSettings.t('tab_settings'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerCard(
    Map<String, dynamic> timer,
    Color color,
    bool isDark, {
    bool isStopwatch = false,
    bool isDefault = false,
  }) {
    String time = timer['total_duration_formatted'] ?? '00:00';
    String title = timer['name'] ?? 'Sin nombre';
    final cardBg =
        isDark ? const Color(0xFF161B2E).withOpacity(0.85) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isStopwatch ? Icons.timer_outlined : Icons.fitness_center_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isStopwatch
                            ? appSettings.t('stopwatch')
                            : '$time  •  ${timer['rounds'] ?? 8} ${appSettings.t('rounds_upper')}',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isDefault)
            Icon(
              Icons.play_circle_fill_rounded,
              color: color,
              size: 30,
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
              color: isDark ? const Color(0xFF1E253E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              onSelected: (value) async {
                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) {
                  _promptLoginDialog();
                  return;
                }

                if (value == 'eliminar') {
                  await Supabase.instance.client
                      .from('timers')
                      .delete()
                      .eq('id', timer['id'])
                      .eq('user_id', user.id);
                  _refreshTimers();
                } else if (value == 'duplicar') {
                  final duplicatedData = Map<String, dynamic>.from(timer);
                  duplicatedData.remove('id');
                  duplicatedData.remove('created_at');
                  duplicatedData['user_id'] = user.id;
                  duplicatedData['name'] =
                      '${timer['name']} (${appSettings.t('copy')})';
                  await Supabase.instance.client
                      .from('timers')
                      .insert(duplicatedData);
                  _refreshTimers();
                } else if (value == 'editar') {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewTimerScreen(
                        timerType: timer['type'] ?? 'TABATA',
                        timerToEdit: timer,
                      ),
                    ),
                  );
                  if (result == true) _refreshTimers();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: isDark
                            ? const Color(0xFF8FFF00)
                            : const Color(0xFF3F51B5),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        appSettings.t('edit'),
                        style: TextStyle(color: textColor),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'duplicar',
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, color: textColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        appSettings.t('duplicate'),
                        style: TextStyle(color: textColor),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        appSettings.t('delete'),
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showAddTimerBottomSheet(BuildContext context) {
    final isDark = appSettings.isDarkMode;
    final sheetBg = isDark ? const Color(0xFF161B2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                appSettings.t('add_timer'),
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 18),
              _buildAddOption(
                context,
                Icons.flash_on_rounded,
                const Color(0xFF8FFF00),
                'TABATA',
                appSettings.t('tabata_desc'),
                isDark,
              ),
              _buildAddOption(
                context,
                Icons.sync_rounded,
                const Color(0xFF00E5FF),
                appSettings.t('rounds'),
                appSettings.t('rounds_desc'),
                isDark,
              ),
              _buildAddOption(
                context,
                Icons.timer_outlined,
                const Color(0xFFFFC107),
                appSettings.t('stopwatch'),
                appSettings.t('stopwatch_desc'),
                isDark,
              ),
              _buildAddOption(
                context,
                Icons.tune_rounded,
                Colors.orangeAccent,
                appSettings.t('custom_timer'),
                appSettings.t('custom_desc'),
                isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddOption(
    BuildContext context,
    IconData icon,
    Color color,
    String title,
    String subtitle,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222944) : const Color(0xFFF3F4FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A237E),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () async {
          Navigator.pop(context);
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewTimerScreen(timerType: title),
            ),
          );
          if (result == true) _refreshTimers();
        },
      ),
    );
  }
}