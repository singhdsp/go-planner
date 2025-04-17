import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_planner/firebase_options.dart';
import 'package:go_planner/providers/user_provider.dart';
import 'package:go_planner/screens/home_screen.dart';
import 'package:go_planner/screens/onboarding_screen.dart';
import 'package:go_planner/screens/splash_screen.dart';
import 'package:go_planner/services/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  void _completeSplash() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return MaterialApp(
      title: 'GoPlanner',
      theme: themeProvider.currentTheme,
      home: _showSplash
          ? SplashScreen(onComplete: _completeSplash)
          : userProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildAppFlow(userProvider),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _buildAppFlow(UserProvider userProvider) {
    // If user is already logged in, go directly to home
    if (userProvider.isLoggedIn) {
      return const HomeScreen();
    }
    
    // Otherwise show onboarding -> auth
    return const OnboardingScreen();
  }
}