import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class CrearHogarScreen extends StatefulWidget {
  const CrearHogarScreen({super.key});

  @override
  _CrearHogarScreenState createState() => _CrearHogarScreenState();
}

class _CrearHogarScreenState extends State<CrearHogarScreen> {
  final TextEditingController _nombreHogarController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String generarCodigoHogar() {
    Random random = Random();
    return List.generate(6, (index) => random.nextInt(10).toString()).join();
  }

  void crearHogar() async {
    String nombreHogar = _nombreHogarController.text.trim();
    String userId = _auth.currentUser!.uid;

    if (nombreHogar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa un nombre para el hogar')),
      );
      return;
    }

    String codigoHogar = generarCodigoHogar();

    await _firestore.collection('hogar').add({
      'nombre': nombreHogar,
      'codigo': codigoHogar,
      'miembros': [userId], // Guarda el ID del usuario en la lista de miembros
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hogar creado con éxito. Código: $codigoHogar')),
    );

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFAF5),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Crea tu hogar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF52A090),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreHogarController,
              decoration: InputDecoration(
                hintText: 'Nombre del hogar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: crearHogar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF52A090),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Crear tu hogar',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
