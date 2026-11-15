import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import '../controllers/app_settings.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AudioPlayer _previewPlayer;

  @override
  void initState() {
    super.initState();
    _initPreviewAudio();
  }

  Future<void> _initPreviewAudio() async {
    final audioContext = AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.alarm,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
    );
    _previewPlayer = AudioPlayer();
    await _previewPlayer.setAudioContext(audioContext);
  }

  Future<void> _playTestSound() async {
    try {
      await _previewPlayer.setVolume(appSettings.soundVolume);
      await _previewPlayer.play(AssetSource('audio/beep.mp3'));
    } catch (e) {
      debugPrint('Error al probar sonido: $e');
    }
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  void _showLanguageDialog() {
    final isDark = appSettings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          appSettings.t('select_language'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Español', style: TextStyle(color: textColor)),
              trailing: appSettings.languageCode == 'es'
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF8FFF00),
                    )
                  : null,
              onTap: () {
                appSettings.setLanguage('es');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('English', style: TextStyle(color: textColor)),
              trailing: appSettings.languageCode == 'en'
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF8FFF00),
                    )
                  : null,
              onTap: () {
                appSettings.setLanguage('en');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(User user) {
    final isDark = appSettings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);
    final currentName = user.userMetadata?['full_name']?.toString() ?? '';
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          appSettings.t('edit_profile'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
        ),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: appSettings.t('full_name'),
            filled: true,
            fillColor:
                isDark ? const Color(0xFF222944) : const Color(0xFFF3F4FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
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
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(data: {'full_name': newName}),
                );
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(appSettings.t('profile_updated'))),
                  );
                }
              }
            },
            child: Text(
              appSettings.t('save'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAuthAction(User? user) async {
    if (user != null) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appSettings.t('logout_success'))),
        );
        setState(() {});
      }
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
      if (result == true && mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) {
        final user = Supabase.instance.client.auth.currentUser;
        final isDark = appSettings.isDarkMode;
        final cardColor =
            isDark ? const Color(0xFF161B2E).withOpacity(0.85) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF1A237E);
        final displayName = user?.userMetadata?['full_name']?.toString() ??
            user?.email ??
            appSettings.t('not_logged_in');
        final volumePercent = (appSettings.soundVolume * 100).round();

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              appSettings.t('settings'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            centerTitle: true,
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
                    appSettings.t('account'),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF8FFF00), Color(0xFF00E5FF)],
                          ),
                        ),
                        child: CircleAvatar(
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
                      title: Text(
                        displayName,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        user != null
                            ? '${user.email}\n${appSettings.t('edit_profile_hint')}'
                            : appSettings.t('login_subtitle'),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      isThreeLine: user != null,
                      trailing: Icon(
                        user != null
                            ? Icons.edit_rounded
                            : Icons.chevron_right_rounded,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        if (user != null) {
                          _showEditProfileDialog(user);
                        } else {
                          _handleAuthAction(null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    appSettings.t('preferences'),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.language_rounded,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                          title: Text(
                            appSettings.t('language'),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                appSettings.languageName,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          onTap: _showLanguageDialog,
                        ),
                        Divider(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                          height: 1,
                        ),
                        SwitchListTile(
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8FFF00).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isDark
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              color: isDark
                                  ? const Color(0xFF8FFF00)
                                  : const Color(0xFF3F51B5),
                            ),
                          ),
                          title: Text(
                            appSettings.t('dark_mode'),
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          activeColor: const Color(0xFF8FFF00),
                          value: isDark,
                          onChanged: (bool value) =>
                              appSettings.toggleTheme(value),
                        ),
                        Divider(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                          height: 1,
                        ),
                        // Control de volumen independiente
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      volumePercent == 0
                                          ? Icons.volume_off_rounded
                                          : Icons.volume_up_rounded,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      appSettings.t('sound_volume'),
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$volumePercent%',
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF8FFF00)
                                          : const Color(0xFF3F51B5),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: _playTestSound,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF8FFF00)
                                                .withOpacity(0.15)
                                            : const Color(0xFF3F51B5)
                                                .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.play_arrow_rounded,
                                            size: 16,
                                            color: isDark
                                                ? const Color(0xFF8FFF00)
                                                : const Color(0xFF3F51B5),
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            appSettings.t('test_sound'),
                                            style: TextStyle(
                                              color: isDark
                                                  ? const Color(0xFF8FFF00)
                                                  : const Color(0xFF3F51B5),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: isDark
                                      ? const Color(0xFF8FFF00)
                                      : const Color(0xFF3F51B5),
                                  inactiveTrackColor: isDark
                                      ? Colors.white12
                                      : Colors.grey.shade300,
                                  thumbColor: isDark
                                      ? const Color(0xFF8FFF00)
                                      : const Color(0xFF3F51B5),
                                  overlayColor:
                                      const Color(0xFF8FFF00).withOpacity(0.2),
                                ),
                                child: Slider(
                                  value: appSettings.soundVolume,
                                  min: 0.0,
                                  max: 1.0,
                                  divisions: 20,
                                  onChanged: (value) {
                                    appSettings.setSoundVolume(value);
                                  },
                                  onChangeEnd: (_) => _playTestSound(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  if (user != null)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.15),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => _handleAuthAction(user),
                      child: Text(
                        appSettings.t('logout'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}