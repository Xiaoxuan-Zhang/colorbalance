import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/rust/frb_generated.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    // Match navigation bar to the new grey background
    systemNavigationBarColor: Color(0xFF1A1A1A),
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
        // CHANGED: From Deep Charcoal (#0F0F0F) to Soft Dark Gray (#1A1A1A)
        // This allows shadows to be visible and reduces eye strain.
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          // Surface is slightly lighter than background for contrast
          surface: Color(0xFF2C2C2C), 
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