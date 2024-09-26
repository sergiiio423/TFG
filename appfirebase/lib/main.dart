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
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        // ----------------------------------------------------------
        '/inicio_sesion': (context) => const SignInPage(),
        // ----------------------------------------------------------
        '/inicio_sesion_correo': (context) => const SignInEmail(),
        // ----------------------------------------------------------
        '/crear_hogar': (context) => const CrearHogarPage(),

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
            return const SignInPage();
          }
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}






