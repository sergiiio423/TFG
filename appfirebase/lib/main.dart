import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'registro.dart';
import 'inicio_sesion.dart';
import 'inicio_sesion_correo.dart';
import 'principal.dart';
import 'crear_hogar.dart';
import  'welcome.dart';
import 'conectar.dart';
import 'calendar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    String user = "";
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        // ----------------------------------------------------------
        '/inicio_sesion': (context) => const SignInEmail(),
        // ----------------------------------------------------------
        '/crear_hogar': (context) => const CrearHogarScreen(),
        // ----------------------------------------------------------
        '/home': (context) => const HomePage(),
        // ----------------------------------------------------------
        '/registro': (context) => const RegistrationPage(),
        // ----------------------------------------------------------
        '/conectar': (context) => const ConnectHomeScreen(),
        // ----------------------------------------------------------
        '/bienvenida': (context) =>  WelcomeScreen(),
        // ----------------------------------------------------------
        '/calendario': (context) =>  CalendarioScreen(),

      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData && snapshot.data!.emailVerified) {
            return const HomePage();
          } else {
            return  WelcomeScreen();
          }
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}






