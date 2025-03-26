import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'perfil.dart';
import 'lista_compra.dart';
import 'tareas_screen.dart';
import 'gastos.dart' ; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  String nombreHogar = 'Inicio';
  List<Map<String, dynamic>> productos = [];
  int _currentIndex = 0; // Índice inicial para Home

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _obtenerNombreHogar();
    _obtenerProductosUsuario();
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

  Future<void> _obtenerProductosUsuario() async {
    if (_user != null) {
      QuerySnapshot listaSnapshot = await _firestore
          .collection('lista')
          .where('usuario', arrayContains: _user!.uid)
          .get();

      List<String> listaIds = listaSnapshot.docs.map((doc) => doc.id).toList();

      if (listaIds.isNotEmpty) {
        QuerySnapshot productoSnapshot = await _firestore
            .collection('producto')
            .where('listaId', whereIn: listaIds)
            .limit(5)
            .get();

        setState(() {
          productos = productoSnapshot.docs
              .map((doc) => {
                    'nombre': doc['nombre'],
                    'icono': doc['icono'],
                    'cantidad': doc['cantidad']
                  })
              .toList();
        });
      }
    }
  }

  void _onBottomNavTapped(BuildContext context, int index) {
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomePage(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const TareasScreen(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ListaScreen(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProfileScreen()),
                      );
                    },
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

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: Colors.teal,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2)
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontSize: 10, height: 1.5),
          unselectedLabelStyle: const TextStyle(fontSize: 10, height: 1.5),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.5),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.teal,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
            _buildNavItem(Icons.home, 'Inicio'),
            _buildNavItem(Icons.list_alt, 'Tareas'),
            _buildNavItem(Icons.wallet, 'Gastos'),
            _buildNavItem(Icons.shopping_basket, 'Compra'),
          ],
          onTap: (index) => _onBottomNavTapped(context, index),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 28),
      ),
      label: label,
      activeIcon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.2),
        ),
        child: Icon(icon, size: 28),
      ),
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
    final hoy = DateTime.now();
    final startOfWeek = hoy.subtract(Duration(days: hoy.weekday - 1));
    final semanaActual =
        List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return GestureDetector(
      onTap: () {
      
        Navigator.pushNamed(context, '/calendario');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
           color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: semanaActual.map((fecha) => _buildDiaItem(fecha)).toList(),
        ),
      ),
    );
  }

  Widget _buildDiaItem(DateTime fecha) {
    final isToday = DateUtils.isSameDay(fecha, DateTime.now());

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isToday ? Colors.orange.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: Colors.orange, width: 2) : null,
      ),
      child: Column(
        children: [
          Text(
            _obtenerDiaCorto(fecha.weekday),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.orange : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${fecha.day}",
            style: TextStyle(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday ? Colors.orange : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _obtenerDiaCorto(int weekday) {
    const dias = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];
    return dias[weekday - 1];
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
    return Column(
      children: productos
          .map(
            (producto) => Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: Text(producto['icono'],
                    style: const TextStyle(fontSize: 24)),
                title: Text(producto['nombre']),
                trailing: Text(producto['cantidad'].toString(),
                    style: const TextStyle(
                        color: Colors.teal, fontWeight: FontWeight.bold)),
              ),
            ),
          )
          .toList(),
    );
  }
}
