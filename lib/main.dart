import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'controllers/app_settings.dart';
import 'screens/timers_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gsgbmugjxhfoisvvxwrn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdzZ2JtdWdqeGhmb2lzdnZ4d3JuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI5MzAwMTMsImV4cCI6MjEwODUwNjAxM30.w2lp-7NBXzmFblGzbLNeaP7-VlG0DGpXF-Xzo-LS6lg',
  );

  runApp(const TimeLiteApp());
}

class TimeLiteApp extends StatelessWidget {
  const TimeLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) {
        final isDark = appSettings.isDarkMode;
        return MaterialApp(
          title: 'Time Lite',
          debugShowCheckedModeBanner: false,
          themeMode: appSettings.themeMode,
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: const Color(0xFFF3F2F7),
            primaryColor: const Color(0xFF6200EE),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black87),
              titleTextStyle: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF0C101B),
            primaryColor: const Color(0xFF8FFF00),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          home: const TimersScreen(),
        );
      },
    );
  }
}