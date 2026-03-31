import 'package:adminmrz/payment/paymentprovider.dart';
import 'package:adminmrz/users/userprovider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:provider/provider.dart';
import 'adminchat/chatprovider.dart';
import 'adminchat/services/MatchedProfileService.dart';
import 'adminchat/services/callmanager.dart';
import 'auth/dashboard.dart';
import 'auth/login.dart';
import 'auth/service.dart';
import 'core/theme_provider.dart';
import 'document/docprovider/docservice.dart';
import 'firebase_options.dart';
import 'package/packageProvider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:js' as js;
import 'dart:html' as html;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(PathUrlStrategy());




    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );



  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => DocumentsProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (_) => PackageProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
        ChangeNotifierProvider(create: (context) => MatchedProfileProvider()),
        ChangeNotifierProvider(create: (_) => CallManager()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'Admin Panel',
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: const Color(0xFFF1F5F9),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              surface: Colors.white,
              onSurface: Color(0xFF334155),
              outlineVariant: Color(0xFFE2E8F0),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              centerTitle: true,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: const Color(0xFF0D1117),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              surface: Color(0xFF1E293B),
              onSurface: Color(0xFFCBD5E1),
              outlineVariant: Color(0xFF334155),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E293B),
              foregroundColor: Color(0xFFCBD5E1),
              elevation: 0,
              centerTitle: true,
            ),
          ),
          debugShowCheckedModeBanner: false,
          home: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return authProvider.isAuthenticated
                  ? const DashboardPage()
                  : const LoginPage();
            },
          ),
        ),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Initialization Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (kIsWeb) {
                      html.window.location.reload();
                    }
                  },
                  child: const Text('Refresh Page'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}