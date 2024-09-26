import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CrearHogarPage extends StatefulWidget {
  const CrearHogarPage({Key? key}) : super(key: key);

  @override
  _CrearHogarPageState createState() => _CrearHogarPageState();
}

class _CrearHogarPageState extends State<CrearHogarPage> {
  final TextEditingController _nombreHogarController = TextEditingController();
  final TextEditingController _miembroController = TextEditingController();
  List<String> miembros = [];
  bool isLoading = true;
  bool hogarExiste = false;

  @override
  void initState() {
    super.initState();
    _verificarHogarExistente();
  }

  Future<void> _verificarHogarExistente() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final User? _user = FirebaseAuth.instance.currentUser;

    if (_user != null) {
      DocumentSnapshot hogarDoc = await _firestore.collection('hogar').doc(_user.uid).get();
      if (hogarDoc.exists) {
        setState(() {
          hogarExiste = true;
        });
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _crearNuevoHogar() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final User? _user = FirebaseAuth.instance.currentUser;

    if (_user != null) {
      await _firestore.collection('hogar').doc(_user.uid).set({
        'uid': _user.uid,
        'nombreHogar': _nombreHogarController.text,
        'miembros': miembros, 
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hogar creado con éxito')),
      );

      // Aquí puedes redirigir a otra página después de crear el hogar
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  void _agregarMiembro() {
    if (_miembroController.text.isNotEmpty) {
      setState(() {
        miembros.add(_miembroController.text);
        _miembroController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (hogarExiste) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Hogar'),
        ),
        body: const Center(
          child: Text('Ya tienes un hogar registrado.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Hogar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crear un nuevo hogar',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nombreHogarController,
              decoration: const InputDecoration(labelText: 'Nombre del hogar'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _miembroController,
              decoration: const InputDecoration(labelText: 'Agregar miembro'),
              onSubmitted: (value) => _agregarMiembro(),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _agregarMiembro,
              child: const Text('Añadir miembro'),
            ),
            const SizedBox(height: 20),
            Text('Miembros del hogar:', style: TextStyle(fontWeight: FontWeight.bold)),
            for (var miembro in miembros)
              ListTile(
                title: Text(miembro),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _crearNuevoHogar,
              child: const Text('Crear Hogar'),
            ),
          ],
        ),
      ),
    );
  }
}
