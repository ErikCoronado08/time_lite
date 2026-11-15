import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/app_settings.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa correo y contraseña')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appSettings.t('welcome'))),
          );
          Navigator.pop(context, true);
        }
      } else {
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': name.isNotEmpty ? name : email.split('@')[0]},
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appSettings.t('account_created'))),
          );
          if (Supabase.instance.client.auth.currentUser != null) {
            Navigator.pop(context, true);
          } else {
            setState(() => _isLogin = true);
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: \$e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appSettings.isDarkMode;
    final cardBg = isDark ? const Color(0xFF161B2E) : Colors.white;
    final inputBg = isDark ? const Color(0xFF222944) : const Color(0xFFF0F2F8);
    final textStyle = TextStyle(color: isDark ? Colors.white : Colors.black87);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0C101B), const Color(0xFF1B2340)]
                : [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo de alta fidelidad fitness
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8FFF00).withOpacity(0.12),
                      shape: BoxShape.circle,
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: const Color(0xFF8FFF00).withOpacity(0.2),
                                blurRadius: 40,
                                spreadRadius: 5,
                              )
                            ]
                          : [],
                    ),
                    child: const Icon(
                      Icons.electric_bolt_rounded,
                      size: 64,
                      color: Color(0xFF8FFF00),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'TIME LITE',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: isDark ? Colors.white : const Color(0xFF1A237E),
                    ),
                  ),
                  Text(
                    'FITNESS TRACKER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF3F51B5),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Caja principal de inicio de sesion (Glassmorphism card)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: cardBg.withOpacity(isDark ? 0.85 : 1.0),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLogin
                              ? appSettings.t('login').toUpperCase()
                              : appSettings.t('register').toUpperCase(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Input de Nombre
                        if (!_isLogin) ...[
                          TextField(
                            controller: _nameController,
                            style: textStyle,
                            decoration: InputDecoration(
                              labelText: appSettings.t('full_name'),
                              labelStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                              prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                              filled: true,
                              fillColor: inputBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Input de Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: textStyle,
                          decoration: InputDecoration(
                            labelText: appSettings.t('email'),
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                            prefixIcon: const Icon(Icons.alternate_email_rounded, color: Colors.grey),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Input de Contrasena
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: textStyle,
                          decoration: InputDecoration(
                            labelText: appSettings.t('password'),
                            labelStyle: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            filled: true,
                            fillColor: inputBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Boton de Accion con degradado de energia
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8FFF00), Color(0xFF00E5FF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8FFF00).withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : Text(
                                    (_isLogin ? appSettings.t('login') : appSettings.t('register')).toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: Colors.black,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Boton inferior de cambio de pestana
                  TextButton(
                    onPressed: () {
                      setState(() => _isLogin = !_isLogin);
                    },
                    child: Text(
                      _isLogin ? appSettings.t('no_account') : appSettings.t('has_account'),
                      style: TextStyle(
                        color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF3F51B5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}