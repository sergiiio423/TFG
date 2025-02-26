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
      QuerySnapshot querySnapshot = await _firestore
          .collection('hogar')
          .where('miembros', arrayContains: _user!.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          nombreHogar = querySnapshot.docs.first['nombre'] ?? 'Mi Hogar';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nombreHogar,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSectionTitle('Planificación Semanal'),
                  _buildWeekPlanner(),
                  _buildSectionTitle('Deudas Pendientes'),
                  _buildDebtList(),
                  _buildSectionTitle('Lista de la Compra'),
                  _buildShoppingList(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildWeekPlanner() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      
      child: const Center(child: Text('Calendario aquí')),
    );
  }

  Widget _buildDebtList() {
    return Column(
      children: [
        _buildDebtTile('Cristina', '5,44 €', 'Sergio'),
        _buildDebtTile('Lola', '0,50 €', 'Sergio'),
        _buildDebtTile('Julia', '2,56 €', 'Sergio'),
      ],
    );
  }

  Widget _buildDebtTile(String from, String amount, String to) {
    return ListTile(
      leading: CircleAvatar(child: Text(from[0])),
      title: Text('$from → $to'),
      trailing: Text(amount, style: const TextStyle(color: Colors.teal)),
    );
  }

  Widget _buildShoppingList() {
    return ListTile(
      leading: const Icon(Icons.local_pizza, color: Colors.orange),
      title: const Text('Pizza'),
      trailing: const Text('1'),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.teal,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: ''),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: ''),
      ],
    );
  }
}
