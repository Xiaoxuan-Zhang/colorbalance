import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set transparent status bar for immersive design
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0F0F0F),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Color Balance',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F), // Atelier Charcoal
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37), // Muted Gold
          surface: Color(0xFF1E1E1E),
          onSurface: Color(0xFFEEEEEE),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'serif', 
            fontSize: 48,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.5,
            color: Color(0xFFEEEEEE),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}