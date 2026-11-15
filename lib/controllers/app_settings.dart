import 'package:flutter/material.dart';

class AppSettings extends ChangeNotifier {
  bool _isDarkMode = true;
  String _languageCode = 'es'; // 'es' o 'en'
  double _soundVolume = 1.0; // 0.0 a 1.0

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  String get languageCode => _languageCode;
  String get languageName => _languageCode == 'es' ? 'Español' : 'English';
  double get soundVolume => _soundVolume;

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  void setLanguage(String code) {
    _languageCode = code;
    notifyListeners();
  }

  void setSoundVolume(double volume) {
    _soundVolume = volume.clamp(0.0, 1.0);
    notifyListeners();
  }

  static const Map<String, Map<String, String>> _translations = {
    'es': {
      // TimersScreen
      'my_timers': 'MIS TEMPORIZADORES',
      'default_timers': 'TEMPORIZADORES PREDETERMINADOS',
      'guest_athlete': 'Invitado',
      'no_timers_yet': 'Aún no tienes temporizadores',
      'no_timers_desc': 'Toca el botón + para crear tu primera rutina personalizada.',
      'login_required_title': 'Inicia sesión para personalizar',
      'login_required_desc':
          'Crea una cuenta o inicia sesión para guardar, editar y sincronizar tus propios temporizadores.',
      'tab_timers': 'Mis temporizadores',
      'tab_run': 'Plantillas / Correr',
      'tab_settings': 'Ajustes',
      'add_timer': 'AÑADIR TEMPORIZADOR',
      'tabata_desc': '20 s trabajo, 10 s descanso — HIIT clásico',
      'rounds': 'RONDAS',
      'rounds_desc': 'Bloques repetidos de trabajo y descanso',
      'stopwatch': 'CRONÓMETRO',
      'stopwatch_desc': 'Cuenta progresiva sin límite',
      'custom_timer': 'TEMPORIZADOR PERSONALIZADO',
      'custom_desc': 'Crea tus propios intervalos',
      'edit': 'Editar',
      'duplicate': 'Duplicar',
      'delete': 'Eliminar',
      'copy': 'Copia',

      // SettingsScreen & AuthScreen
      'settings': 'AJUSTES',
      'account': 'CUENTA',
      'not_logged_in': 'No has iniciado sesión',
      'login_subtitle': 'Toca para iniciar sesión o registrarte',
      'edit_profile_hint': 'Toca para editar tu nombre de perfil',
      'preferences': 'PREFERENCIAS',
      'language': 'Idioma',
      'select_language': 'Seleccionar Idioma',
      'dark_mode': 'Modo Oscuro',
      'sound_volume': 'Volumen de sonidos',
      'test_sound': 'Probar',
      'logout': 'CERRAR SESIÓN',
      'logout_success': 'Sesión cerrada correctamente',
      'edit_profile': 'Editar Perfil',
      'full_name': 'Nombre completo',
      'cancel': 'CANCELAR',
      'save': 'GUARDAR',
      'profile_updated': 'Perfil actualizado correctamente',
      'login': 'INICIAR SESIÓN',
      'register': 'CREAR CUENTA',
      'email': 'Correo electrónico',
      'password': 'Contraseña',
      'no_account': '¿No tienes cuenta? Regístrate aquí',
      'has_account': '¿Ya tienes cuenta? Inicia sesión',
      'welcome': '¡Bienvenido a Time Lite!',
      'account_created': 'Cuenta creada. ¡Ya puedes iniciar sesión!',

      // NewTimerScreen
      'edit_timer': 'EDITAR TEMPORIZADOR',
      'new_prefix': 'NUEVO',
      'new_custom_default': 'NUEVO TEMPORIZADOR',
      'name_label': 'NOMBRE',
      'stopwatch_info': 'Cronómetro progresivo sin límite con avisos de vuelta.',
      'optimized_for': 'Configuración optimizada para',
      'prepare': 'PREPÁRATE',
      'prepare_desc': 'Cuenta regresiva antes de empezar',
      'prepare_dialog': 'Tiempo de Preparación (s)',
      'lap_time': 'TIEMPO DE VUELTA',
      'lap_desc': 'Sonará en cada vuelta',
      'lap_dialog': 'Tiempo de Vuelta (s)',
      'series': 'SERIE',
      'duplicate_series': 'Duplicar serie',
      'delete_series': 'Eliminar serie',
      'add_series': 'AÑADIR SERIE',
      'train': 'ENTRENAR',
      'rest': 'DESCANSAR',
      'rounds_upper': 'RONDAS',
      'train_dialog': 'Tiempo de Entrenamiento (s)',
      'rest_dialog': 'Tiempo de Descanso (s)',
      'rounds_dialog': 'Número de Rondas',
      'enter_number_hint': 'Escribe la cantidad directamente',
      'seconds_unit': 'segundos',
      'rounds_unit': 'rondas',
      'save_error': 'Error al guardar',

      // RunningScreen & ShareRunScreen
      'run_mode': 'MODO CORRE (STRAVA)',
      'distance': 'DISTANCIA',
      'time': 'TIEMPO',
      'stop_run': 'TERMINAR CARRERA',
      'start_run': 'COMENZAR A CORRER',
      'workout_finished': '¡ENTRENAMIENTO FINALIZADO!',
      'distance_label': 'Distancia',
      'time_label': 'Tiempo',
      'calories_label': 'Calorías',
      'pace_label': 'Ritmo',
      'close': 'CERRAR',
      'share': 'COMPARTIR',
      'share_run_1': '¡He corrido',
      'share_run_2': 'en',
      'share_run_3': 'usando Time Lite! 🔥 Entrenando duro.',
      'share_studio': 'COMPARTIR ACTIVIDAD',
      'tpl_transparent': 'Sticker PNG',
      'tpl_neon': 'Neón Dark',
      'tpl_photo': 'Con Foto',
      'tpl_light': 'Minimal',
      'pick_photo': 'Galería',
      'take_photo': 'Cámara',
      'transparent_hint': 'Fondo transparente: ideal para pegar sobre tus Stories',
      'share_instagram': 'COMPARTIR EN INSTAGRAM / REDES',
      'generating_image': 'Generando imagen...',

      // TimerExecutionScreen & StopwatchExecutionScreen
      'phase_prepare': 'PREPARAR',
      'phase_train': 'ENTRENAR',
      'phase_rest': 'DESCANSAR',
      'completed': '¡COMPLETADO!',
      'round_upper': 'RONDA',
      'lap': 'Vuelta',
    },
    'en': {
      // TimersScreen
      'my_timers': 'MY TIMERS',
      'default_timers': 'DEFAULT TIMERS',
      'guest_athlete': 'Guest',
      'no_timers_yet': 'No timers created yet',
      'no_timers_desc': 'Tap the + button to build your first custom workout timer.',
      'login_required_title': 'Sign in to customize',
      'login_required_desc':
          'Create an account or sign in to save, edit, and sync your own custom timers.',
      'tab_timers': 'My timers',
      'tab_run': 'Templates / Run',
      'tab_settings': 'Settings',
      'add_timer': 'ADD TIMER',
      'tabata_desc': '20s work, 10s rest — Classic HIIT',
      'rounds': 'ROUNDS',
      'rounds_desc': 'Repeated blocks of work and rest',
      'stopwatch': 'STOPWATCH',
      'stopwatch_desc': 'Unlimited count-up timer',
      'custom_timer': 'CUSTOM TIMER',
      'custom_desc': 'Create your own intervals',
      'edit': 'Edit',
      'duplicate': 'Duplicate',
      'delete': 'Delete',
      'copy': 'Copy',

      // SettingsScreen & AuthScreen
      'settings': 'SETTINGS',
      'account': 'ACCOUNT',
      'not_logged_in': 'Not logged in',
      'login_subtitle': 'Tap to sign in or create an account',
      'edit_profile_hint': 'Tap to edit your profile name',
      'preferences': 'PREFERENCES',
      'language': 'Language',
      'select_language': 'Select Language',
      'dark_mode': 'Dark Mode',
      'sound_volume': 'Sound volume',
      'test_sound': 'Test',
      'logout': 'SIGN OUT',
      'logout_success': 'Signed out successfully',
      'edit_profile': 'Edit Profile',
      'full_name': 'Full name',
      'cancel': 'CANCEL',
      'save': 'SAVE',
      'profile_updated': 'Profile updated successfully',
      'login': 'SIGN IN',
      'register': 'CREATE ACCOUNT',
      'email': 'Email address',
      'password': 'Password',
      'no_account': "Don't have an account? Sign up",
      'has_account': 'Already have an account? Sign in',
      'welcome': 'Welcome to Time Lite!',
      'account_created': 'Account created. You can sign in now!',

      // NewTimerScreen
      'edit_timer': 'EDIT TIMER',
      'new_prefix': 'NEW',
      'new_custom_default': 'NEW TIMER',
      'name_label': 'NAME',
      'stopwatch_info': 'Unlimited count-up stopwatch with lap alerts.',
      'optimized_for': 'Optimized configuration for',
      'prepare': 'PREPARE',
      'prepare_desc': 'Countdown before starting',
      'prepare_dialog': 'Preparation Time (s)',
      'lap_time': 'LAP TIME',
      'lap_desc': 'Sounds on every lap',
      'lap_dialog': 'Lap Time (s)',
      'series': 'SET',
      'duplicate_series': 'Duplicate set',
      'delete_series': 'Delete set',
      'add_series': 'ADD SET',
      'train': 'TRAIN',
      'rest': 'REST',
      'rounds_upper': 'ROUNDS',
      'train_dialog': 'Training Time (s)',
      'rest_dialog': 'Rest Time (s)',
      'rounds_dialog': 'Number of Rounds',
      'enter_number_hint': 'Type the exact number directly',
      'seconds_unit': 'seconds',
      'rounds_unit': 'rounds',
      'save_error': 'Error saving',

      // RunningScreen & ShareRunScreen
      'run_mode': 'RUN MODE (STRAVA)',
      'distance': 'DISTANCE',
      'time': 'TIME',
      'stop_run': 'FINISH RUN',
      'start_run': 'START RUNNING',
      'workout_finished': 'WORKOUT FINISHED!',
      'distance_label': 'Distance',
      'time_label': 'Time',
      'calories_label': 'Calories',
      'pace_label': 'Pace',
      'close': 'CLOSE',
      'share': 'SHARE',
      'share_run_1': 'I just ran',
      'share_run_2': 'in',
      'share_run_3': 'using Time Lite! 🔥 Training hard.',
      'share_studio': 'SHARE ACTIVITY',
      'tpl_transparent': 'PNG Sticker',
      'tpl_neon': 'Neon Dark',
      'tpl_photo': 'Photo Overlay',
      'tpl_light': 'Minimal',
      'pick_photo': 'Gallery',
      'take_photo': 'Camera',
      'transparent_hint': 'Transparent background: paste right onto your Stories',
      'share_instagram': 'SHARE TO INSTAGRAM / SOCIAL',
      'generating_image': 'Generating image...',

      // TimerExecutionScreen & StopwatchExecutionScreen
      'phase_prepare': 'PREPARE',
      'phase_train': 'TRAIN',
      'phase_rest': 'REST',
      'completed': 'COMPLETED!',
      'round_upper': 'ROUND',
      'lap': 'Lap',
    },
  };

  String t(String key) {
    return _translations[_languageCode]?[key] ?? key;
  }
}

final AppSettings appSettings = AppSettings();