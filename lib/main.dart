import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/passenger/views/login_s.dart';
import 'features/passenger/views/passenger_home_s.dart';

void main() async {
  // Flutter Widgets binding Initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase Initialized
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Go',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A2B4C)),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // A progress indicator is displayed while the connection is loading.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Redirecting the user directly to the Passenger Home Screen if they are already logged in.
          if (snapshot.hasData) {
            return const PassengerHomeScreen();
          }

          // Displaying the login screen if not logged in.
          return const LoginScreen();
        },
      ),
    );
  }
}