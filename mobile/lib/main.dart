import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/firebase_init.dart';
import 'core/services/api_service.dart';
import 'features/auth/presentation/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);

  // Initialize Firebase services with retry logic (max 3 attempts)
  try {
    await FirebaseInitService.instance.initialize(maxRetries: 3);
  } catch (e) {
    // If Firebase initialization fails after retries, show error screen
    runApp(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: FirebaseErrorScreen(error: e.toString()),
        ),
      ),
    );
    return;
  }

  // Load stored backend API tokens
  await ApiService.instance.loadTokens();

  runApp(
    const ProviderScope(
      child: YaaroMobileApp(),
    ),
  );
}

/// Error screen displayed when Firebase initialization fails after all retries.
class FirebaseErrorScreen extends StatelessWidget {
  const FirebaseErrorScreen({required this.error, super.key});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050506),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFFF4F6D),
                  size: 64,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Initialization Failed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'The app could not start because a required service failed to initialize. '
                  'Please check your internet connection and try again.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Restart the app by calling main again
                    main();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4F6D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ThemeScope extends InheritedWidget {
  const ThemeScope({
    required this.themeMode,
    required this.changeTheme,
    required super.child,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> changeTheme;

  static ThemeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope is missing.');
    return scope!;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) =>
      themeMode != oldWidget.themeMode;
}

class YaaroMobileApp extends StatefulWidget {
  const YaaroMobileApp({super.key});

  static bool isDark = true;

  @override
  State<YaaroMobileApp> createState() => _YaaroMobileAppState();
}

class _YaaroMobileAppState extends State<YaaroMobileApp>
    with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadThemeMode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (_themeMode == ThemeMode.system) {
      setState(() {
        _updateIsDark(ThemeMode.system);
      });
    }
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    if (saved != null) {
      ThemeMode mode = ThemeMode.dark;
      if (saved == 'light') {
        mode = ThemeMode.light;
      } else if (saved == 'system') {
        mode = ThemeMode.system;
      }
      if (mounted) {
        setState(() {
          _themeMode = mode;
          _updateIsDark(mode);
        });
      }
    } else {
      _updateIsDark(ThemeMode.dark);
    }
  }

  void _updateIsDark(ThemeMode mode) {
    if (mode == ThemeMode.system) {
      final brightness = PlatformDispatcher.instance.platformBrightness;
      YaaroMobileApp.isDark = brightness == Brightness.dark;
    } else {
      YaaroMobileApp.isDark = mode == ThemeMode.dark;
    }
  }

  Future<void> _changeTheme(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
      _updateIsDark(mode);
    });
    String val = 'dark';
    if (mode == ThemeMode.light) {
      val = 'light';
    } else if (mode == ThemeMode.system) {
      val = 'system';
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', val);
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      themeMode: _themeMode,
      changeTheme: _changeTheme,
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'YaaRo0',
            debugShowCheckedModeBanner: false,
            themeMode: _themeMode,
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF9FAFB),
              textTheme: ThemeData.light().textTheme.apply(
                    bodyColor: const Color(0xFF111216),
                    displayColor: const Color(0xFF111216),
                  ),
              iconTheme: const IconThemeData(color: Color(0xFF111216)),
              dividerTheme: const DividerThemeData(color: Color(0x1F000000)),
              colorScheme: ColorScheme.fromSeed(
                seedColor: YaaroColors.rose,
                brightness: Brightness.light,
                primary: YaaroColors.rose,
                secondary: YaaroColors.teal,
                surface: Colors.white,
                onSurface: const Color(0xFF111216),
              ),
              fontFamily: 'Roboto',
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: YaaroColors.black,
              textTheme: ThemeData.dark().textTheme.apply(
                    bodyColor: Colors.white,
                    displayColor: Colors.white,
                  ),
              iconTheme: const IconThemeData(color: Colors.white),
              dividerTheme: const DividerThemeData(color: Color(0x2EFFFFFF)),
              colorScheme: ColorScheme.fromSeed(
                seedColor: YaaroColors.rose,
                brightness: Brightness.dark,
                primary: YaaroColors.rose,
                secondary: YaaroColors.teal,
                surface: YaaroColors.surface,
                onSurface: Colors.white,
              ),
              fontFamily: 'Roboto',
              useMaterial3: true,
            ),
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class YaaroColors {
  static const black = Color(0xFF050506);
  static const surface = Color(0xFF111216);
  static const surfaceAlt = Color(0xFF191A20);
  static const rose = Color(0xFFFF4F6D);
  static const saffron = Color(0xFFFFB84D);
  static const teal = Color(0xFF31D0B2);

  static const muted = CupertinoDynamicColor.withBrightness(
    color: Color(0x99000000),
    darkColor: Color(0xB8FFFFFF),
  );

  static const line = CupertinoDynamicColor.withBrightness(
    color: Color(0x1F000000),
    darkColor: Color(0x2EFFFFFF),
  );

  static bool isDarkFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color textFor(BuildContext context) =>
      isDarkFor(context) ? Colors.white : const Color(0xFF111216);

  static Color mutedFor(BuildContext context) =>
      isDarkFor(context) ? const Color(0xB8FFFFFF) : const Color(0x99000000);

  static Color lineFor(BuildContext context) =>
      isDarkFor(context) ? const Color(0x2EFFFFFF) : const Color(0x1F000000);

  static Color panelFor(BuildContext context) => isDarkFor(context)
      ? surface.withOpacity(0.88)
      : Colors.white.withOpacity(0.92);

  static Color surfaceAltFor(BuildContext context) =>
      isDarkFor(context) ? surfaceAlt : const Color(0xFFF3F4F6);
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.focusNode,
    this.hasError = false,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      focusNode: focusNode,
      onChanged: onChanged,
      style: TextStyle(
        color: YaaroColors.textFor(context),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: hasError ? YaaroColors.rose : YaaroColors.mutedFor(context),
          fontSize: 14,
        ),
        floatingLabelStyle: TextStyle(
          color:
              hasError ? YaaroColors.rose : YaaroColors.rose.withOpacity(0.9),
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: hasError
            ? Colors.red.withOpacity(0.08)
            : (isDark
                ? Colors.white.withOpacity(0.045)
                : Colors.black.withOpacity(0.035)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? YaaroColors.rose : YaaroColors.lineFor(context),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? YaaroColors.rose : YaaroColors.lineFor(context),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color:
                hasError ? YaaroColors.rose : YaaroColors.rose.withOpacity(0.9),
            width: 2.0,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}
