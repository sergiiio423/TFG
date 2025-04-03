import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'perfil.dart';
import 'lista_compra.dart';
import 'tareas_screen.dart';
import 'gastos.dart';
import 'calendar.dart';

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
  List<Map<String, dynamic>> deudas = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _obtenerNombreHogar(),
      _obtenerProductosUsuario(),
      _obtenerDeudasPendientes(),
    ]);
    setState(() => _isLoading = false);
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
                    'cantidad': doc['cantidad'],
                    'comprado': doc['comprado'] ?? false,
                  })
              .toList();
        });
      }
    }
  }

  Future<void> _obtenerDeudasPendientes() async {
    if (_user != null) {
      QuerySnapshot deudasSnapshot = await _firestore
          .collection('deudas')
          .where('deudor', isEqualTo: _user!.uid)
          .where('pagada', isEqualTo: false)
          .limit(3)
          .get();

      List<Future<DocumentSnapshot>> usuariosFutures = deudasSnapshot.docs
          .map((doc) =>
              _firestore.collection('usuarios').doc(doc['acreedor']).get())
          .toList();

      List<DocumentSnapshot> usuarios = await Future.wait(usuariosFutures);

      setState(() {
        deudas = deudasSnapshot.docs.asMap().entries.map((entry) {
          int index = entry.key;
          var doc = entry.value;
          var usuario = usuarios[index];
          return {
            'id': doc.id,
            'monto': doc['monto'],
            'descripcion': doc['descripcion'],
            'nombreAcreedor': usuario['nombre'] ?? 'Usuario',
            'fecha': (doc['fecha'] as Timestamp).toDate(),
          };
        }).toList();
      });
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
      case 2:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => GastosScreen(),
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
          children: [
            // Encabezado
            _buildAppBar(),

            // Contenido principal
            Expanded(
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Resumen rápido
                          _buildQuickSummary(),
                          const SizedBox(height: 24),

                          // Planificación semanal
                          _buildWeekSection(),
                          const SizedBox(height: 24),

                          // Deudas pendientes
                          _buildDebtsSection(),
                          const SizedBox(height: 24),

                          // Lista de compra
                          _buildShoppingListSection(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            nombreHogar,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 24, color: Colors.teal),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
      ),
    );
  }

  Widget _buildQuickSummary() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.task,
            title: 'Tareas pendientes',
            value: '5',
            color: Colors.orange.shade100,
            iconColor: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.shopping_cart,
            title: 'Productos por comprar',
            value: productos.length.toString(),
            color: Colors.teal.shade100,
            iconColor: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: iconColor),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Planificación Semanal',
          actionText: 'Ver calendario',
          onAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CalendarioScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildWeekPlanner(),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionText,
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWeekPlanner() {
    final hoy = DateTime.now();
    final startOfWeek = hoy.subtract(Duration(days: hoy.weekday - 1));
    final semanaActual =
        List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                semanaActual.map((fecha) => _buildDiaItem(fecha)).toList(),
          ),
          const SizedBox(height: 16),
          _buildWeekStats(),
        ],
      ),
    );
  }

  Widget _buildDiaItem(DateTime fecha) {
    final isToday = DateUtils.isSameDay(fecha, DateTime.now());
    final dayName = _obtenerDiaCorto(fecha.weekday);
    final dayNumber = fecha.day;

    return Column(
      children: [
        Text(
          dayName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isToday ? Colors.teal : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isToday ? Colors.teal : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekStats() {
    return Row(
      children: [
        _buildStatItem(
          value: '3',
          label: 'Tareas',
          color: Colors.orange.shade100,
          textColor: Colors.orange,
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          value: '2',
          label: 'Eventos',
          color: Colors.teal.shade100,
          textColor: Colors.teal,
        ),
        const SizedBox(width: 12),
        _buildStatItem(
          value: '1',
          label: 'Cumpleaños',
          color: Colors.pink.shade100,
          textColor: Colors.pink,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Deudas Pendientes',
          actionText: deudas.isNotEmpty ? 'Ver todas' : null,
          onAction: () {
            // Navegar a pantalla de deudas
          },
        ),
        const SizedBox(height: 12),
        deudas.isEmpty
            ? _buildEmptyState(
                icon: Icons.money_off,
                message: 'No tienes deudas pendientes',
                color: Colors.green.shade100,
                iconColor: Colors.green,
              )
            : Column(
                children: deudas.map((deuda) => _buildDebtTile(deuda)).toList(),
              ),
      ],
    );
  }

  Widget _buildDebtTile(Map<String, dynamic> deuda) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.money, color: Colors.red.shade400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debes a ${deuda['nombreAcreedor']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deuda['descripcion'] ?? 'Sin descripción',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM').format(deuda['fecha']),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${deuda['monto']} €',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Lista de la Compra',
          actionText: productos.isNotEmpty ? 'Ver lista completa' : null,
          onAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ListaScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        productos.isEmpty
            ? _buildEmptyState(
                icon: Icons.shopping_cart,
                message: 'No hay productos en tu lista',
                color: Colors.blue.shade100,
                iconColor: Colors.blue,
              )
            : Column(
                children: productos
                    .map((producto) => _buildProductTile(producto))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildProductTile(Map<String, dynamic> producto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                producto['icono'],
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              producto['nombre'],
              style: TextStyle(
                fontSize: 16,
                decoration: producto['comprado']
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: producto['comprado'] ? Colors.grey : Colors.black87,
              ),
            ),
          ),
          Text(
            '${producto['cantidad']}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: producto['comprado'] ? Colors.grey : Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(width: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
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
            spreadRadius: 2,
          ),
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

  String _obtenerDiaCorto(int weekday) {
    const dias = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];
    return dias[weekday - 1];
  }
}
