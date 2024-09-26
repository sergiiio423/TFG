import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'registro.dart';
import 'inicio_sesion.dart';

class SignInEmail extends StatefulWidget {
  const SignInEmail({super.key});

  @override
  _SignInEmailState createState() => _SignInEmailState();
}

class _SignInEmailState extends State<SignInEmail> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signIn() async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!userCredential.user!.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please verify your email before logging in.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // Centrar verticalmente
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Extender los widgets a lo ancho
            children: <Widget>[
              Image.asset('assets/correo.png', width: 50, height: 50),
              const SizedBox(height: 10),
              const Text(
                'Inicia sesión con correo electrónico ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Arial',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ingresa tu dirección de correo electrónico y contraseña y te enviaremos un correo de confirmación.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Arial',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signIn,
                child: const Text('Iniciar sesión',
                style: TextStyle(color: Colors.black),),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
