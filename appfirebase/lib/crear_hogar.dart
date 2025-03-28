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
  bool _isLoading = false;

  String generarCodigoHogar() {
    final random = Random();
    return List.generate(6, (index) => random.nextInt(10).toString()).join();
  }

  Future<void> crearHogar() async {
    if (_isLoading) return;
    
    final nombreHogar = _nombreHogarController.text.trim();
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildCustomSnackBar('Usuario no autenticado', Icons.error_outline_rounded),
      );
      return;
    }

    if (nombreHogar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildCustomSnackBar('Ingresa un nombre para el hogar', Icons.warning_rounded),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final codigoHogar = generarCodigoHogar();
      
      await _firestore.collection('hogar').add({
        'nombre': nombreHogar,
        'codigo': codigoHogar,
        'miembros': [userId],
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        _buildCustomSnackBar('Hogar creado exitosamente', Icons.check_circle_rounded),
      );

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildCustomSnackBar('Error al crear el hogar', Icons.error_outline_rounded),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  SnackBar _buildCustomSnackBar(String text, IconData icon) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
      backgroundColor: const Color(0xFF52A090),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          minimum: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              _buildHeaderSection(),
              const SizedBox(height: 40),
              _buildFormSection(),
              const Spacer(),
              _buildActionButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crear nuevo hogar',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.teal,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Comienza una nueva experiencia colaborativa con tu familia o compañeros',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nombreHogarController,
          decoration: InputDecoration(
            labelText: 'Nombre del hogar',
            labelStyle: TextStyle(
              color: Colors.teal,
            ),
            hintText: 'Ej: Casa familiar, Piso compartido...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: Icon(Icons.home_rounded, color: Colors.teal),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF52A090), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
          ),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[800],
          ),
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton.icon(
      icon: _isLoading
          ? Container(
              width: 24,
              height: 24,
              padding: const EdgeInsets.all(2),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : const Icon(Icons.add_home_rounded, size: 24),
      label: Text(
        _isLoading ? 'Creando hogar...' : 'Crear hogar',
        style: const TextStyle(
          fontSize: 16,
          letterSpacing: 0.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF52A090),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      onPressed: crearHogar,
    );
  }
}