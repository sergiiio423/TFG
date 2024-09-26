import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  String nombreHogar = 'Inicio';

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _obtenerNombreHogar();
  }

  Future<void> _obtenerNombreHogar() async {
    if (_user != null) {
      DocumentSnapshot docSnapshot =
          await _firestore.collection('hogar').doc(_user!.uid).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        setState(() {
          nombreHogar =
              (docSnapshot.data() as Map<String, dynamic>)['nombreHogar'] ??
                  'Mi Hogar';
        });
      }
    }
  }

  Future<bool> _isHogarEmpty() async {
    DocumentSnapshot docSnapshot =
        await _firestore.collection('hogar').doc(_user!.uid).get();

    return !docSnapshot.exists ||
        !docSnapshot.data().toString().contains('miembros');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nombreHogar, style: const TextStyle(fontSize: 25 , fontFamily: 'Arial') ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: _isHogarEmpty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los datos.'));
          }

          final isHogarEmpty = snapshot.data ?? true;

          return Center(
            child:
                isHogarEmpty ? _buildCreateHogarOption() : _buildHogarMembers(),
          );
        },
      ),
    );
  }

  Widget _buildCreateHogarOption() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'No tienes un hogar creado.',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/crear_hogar');
          },
          child: const Text('Crear nuevo hogar'),
        ),
      ],
    );
  }

  Widget _buildHogarMembers() {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('hogar').doc(_user!.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return const Text('Error al cargar los miembros del hogar.');
        }

        final hogarData = snapshot.data?.data() as Map<String, dynamic>?;
        final List<dynamic> miembros = hogarData?['miembros'] ?? [];

        if (miembros.isEmpty) {
          return const Text('Tu hogar no tiene miembros.');
        }

        return ListView.builder(
          itemCount: miembros.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(miembros[index].toString()),
            );
          },
        );
      },
    );
  }
}
