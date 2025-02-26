import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInEmail extends StatefulWidget {
  const SignInEmail({super.key});

  @override
  _SignInEmailState createState() => _SignInEmailState();
}

class _SignInEmailState extends State<SignInEmail> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  Future<void> _signIn() async {
    setState(() {
      _errorMessage = '';
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        _showEmailNotVerifiedDialog(user);
      } else {
        await _checkUserHogar(user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'No hay una cuenta registrada con este correo.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'La contraseña es incorrecta.';
        } else {
          _errorMessage = 'Error al iniciar sesión. Inténtalo de nuevo.';
        }
      });
    }
  }

  Future<void> _checkUserHogar(String userId) async {
    final QuerySnapshot hogarQuery = await FirebaseFirestore.instance
        .collection('hogar')
        .where('miembros', arrayContains: userId)
        .limit(1)
        .get();

    if (hogarQuery.docs.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home'); // Pantalla principal
    } else {
      Navigator.pushReplacementNamed(context, '/conectar'); // Conectar hogar
    }
  }

  void _showEmailNotVerifiedDialog(User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/no-confirmado.png',
                height: 100,
              ),
              const SizedBox(height: 16),
              const Text(
                'Correo no verificado',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Por favor verifica tu correo electrónico antes de iniciar sesión.',
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.pushNamed(context, '/inicio_sesion_correo');
              },
            ),
            TextButton(
              child: const Text('Reenviar correo de verificación'),
              onPressed: () async {
                await user.sendEmailVerification();
                Navigator.pushNamed(context, '/inicio_sesion_correo');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Correo de verificación reenviado.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'assets/fondo.png', // Asegúrate de colocar esta imagen en assets
              fit: BoxFit.cover,
            ),
          ),
          // Contenido encima del fondo
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Accede aquí',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '¡Bienvenido de nuevo, te hemos echado de menos!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8), // Hacerlo más visible
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Contraseña',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {},
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(color: Colors.teal, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Iniciar sesión',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/registro');
                      },
                      child: const Text(
                        '¿No tienes cuenta? Regístrate ahora',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
