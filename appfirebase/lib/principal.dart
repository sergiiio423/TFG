import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'perfil.dart';
import 'calendar.dart';
import 'lista_compra.dart';
import 'navigation_bar.dart';
import 'gastos.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String nombreHogar = 'Inicio';
  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> deudas = [];
  Map<String, String> _nombresUsuarios = {};
  final int _currentIndex = 0;
  bool _isLoading = true;
  int tareasPendientes = 0;
  int tareasHoy = 0;
  int tareasSemana = 0;
  double totalDeudas = 0.0;
  String? _hogarId;
  StreamSubscription? _tareasSubscription;
  StreamSubscription? _deudasSubscription;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadInitialData();
    _setupTareasListener();
    _setupDeudasListener();
    _cargarNombresUsuarios();
  }

  @override
  void dispose() {
    _tareasSubscription?.cancel();
    _deudasSubscription?.cancel();
    super.dispose();
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

  Future<void> _cargarNombresUsuarios() async {
    final usuarios = await _firestore.collection('usuarios').get();
    setState(() {
      _nombresUsuarios = {
        for (var doc in usuarios.docs) doc.id: doc['nombre'] ?? 'Usuario'
      };
    });
  }

void _setupTareasListener() {
  _tareasSubscription?.cancel();

  final hoy = DateTime.now();
  final semanaActual = ((hoy.day) ~/ 7) + 1;

  _tareasSubscription = _firestore
      .collection('tareas')
      .where('asignados', arrayContains: _user?.uid ?? '')
      .where('completada', isEqualTo: false)
      .snapshots()
      .listen((snapshot) {
    int hoyCount = 0;
    int semanaCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final fecha = data['fecha'] as Timestamp?;

      if (data['tipo'] == 'puntual') {
        if (fecha != null && DateUtils.isSameDay(fecha.toDate(), DateTime.now())) {
          hoyCount++;
        }
      } else {
        final semanas = data['semanas'] as List<dynamic>?;
        if (semanas?.contains(semanaActual) == true &&
            data['mes'] == hoy.month &&
            data['año'] == hoy.year) {
          semanaCount++;
        }
      }
    }

    if (mounted) {
      setState(() {
        tareasHoy = hoyCount;
        tareasSemana = semanaCount;
        tareasPendientes = hoyCount + semanaCount;
      });
    }
  });
}

  void _setupDeudasListener() {
    _deudasSubscription?.cancel();

    _deudasSubscription = _firestore
        .collection('deudas')
        .where('pagado', isEqualTo: false)
        .where('hogarId', isEqualTo: _hogarId)
        .snapshots()
        .listen((snapshot) {
      List<Map<String, dynamic>> deudasTemp = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        deudasTemp.add({
          'id': doc.id,
          'monto': data['monto'],
          'deudor': data['deudor'],
          'acreedor': data['acreedor'],
          'creadoEn': (data['creadoEn'] as Timestamp).toDate(),
          'ultimaActualizacion':
              (data['ultimaActualizacion'] as Timestamp).toDate(),
        });
      }

      if (mounted) {
        setState(() {
          deudas = deudasTemp;
        });
      }
    });
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
          _hogarId = querySnapshot.docs.first.id;
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
    if (_user != null && _hogarId != null) {
      QuerySnapshot deudasSnapshot = await _firestore
          .collection('deudas')
          .where('pagado', isEqualTo: false)
          .where('hogarId', isEqualTo: _hogarId)
          .limit(3)
          .get();

      // Obtener nombres de acreedores y deudores
      List<String> usuariosIds = [];
      for (var doc in deudasSnapshot.docs) {
        usuariosIds.add(doc['deudor']);
        usuariosIds.add(doc['acreedor']);
      }
      usuariosIds = usuariosIds.toSet().toList();

      List<Future<DocumentSnapshot>> usuariosFutures = usuariosIds
          .map((id) => _firestore.collection('usuarios').doc(id).get())
          .toList();

      List<DocumentSnapshot> usuarios = await Future.wait(usuariosFutures);
      Map<String, String> nombresUsuarios = {};
      for (var usuario in usuarios) {
        nombresUsuarios[usuario.id] = usuario['nombre'] ?? 'Usuario';
      }

      setState(() {
        deudas = deudasSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'monto': doc['monto'],
            'deudor': doc['deudor'],
            'acreedor': doc['acreedor'],
            'nombreDeudor': nombresUsuarios[doc['deudor']],
            'nombreAcreedor': nombresUsuarios[doc['acreedor']],
            'creadoEn': (doc['creadoEn'] as Timestamp).toDate(),
            'ultimaActualizacion':
                (doc['ultimaActualizacion'] as Timestamp).toDate(),
          };
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuickSummary(),
                          const SizedBox(height: 24),
                          _buildWeekSection(),
                          const SizedBox(height: 24),
                          _buildDebtsSection(),
                          const SizedBox(height: 24),
                          _buildShoppingListSection(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        context: context,
      ),
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
    // Calcular el balance del usuario
    double balance = 0.0;

    // Sumar todas las deudas donde el usuario es el acreedor (le deben dinero)
    final deudasAFavor =
        deudas.where((d) => d['acreedor'] == _user?.uid).toList();
    final totalAFavor = deudasAFavor.fold(
        0.0, (sum, deuda) => sum + (deuda['monto'] as num).toDouble());

    // Sumar todas las deudas donde el usuario es el deudor (debe dinero)
    final deudasEnContra =
        deudas.where((d) => d['deudor'] == _user?.uid).toList();
    final totalEnContra = deudasEnContra.fold(
        0.0, (sum, deuda) => sum + (deuda['monto'] as num).toDouble());

    balance = totalAFavor - totalEnContra;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.task,
            title: 'Tareas pendientes',
            value: tareasPendientes.toString(),
            color: Colors.orange.shade100,
            iconColor: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: balance >= 0 ? Icons.arrow_downward : Icons.arrow_upward,
            title: balance >= 0 ? 'Te deben' : 'Debes',
            value: '${balance.abs().toStringAsFixed(2)} €',
            color: balance >= 0 ? Colors.green.shade100 : Colors.red.shade100,
            iconColor: balance >= 0 ? Colors.green : Colors.red,
          ),
        )
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
  return Column(
    children: [
      Row(
        children: [
          _buildStatItem(
            value: tareasHoy.toString(),
            label: 'Tareas hoy',
            color: Colors.orange.shade100,
            textColor: Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildStatItem(
            value: tareasSemana.toString(),
            label: 'Tareas semanales',
            color: Colors.teal.shade100,
            textColor: Colors.teal,
          ),
        ],
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => GastosScreen()),
            );
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
    final currentUserId = _user?.uid;
    final esDeudor = deuda['deudor'] == currentUserId;
    final esAcreedor = deuda['acreedor'] == currentUserId;

    // Verificar si el usuario está involucrado en esta deuda
    if (!esDeudor && !esAcreedor) {
      return const SizedBox.shrink(); // No mostrar deudas no relacionadas
    }

    // Obtener nombres de usuarios desde el mapa precargado
    final nombreDeudor = _nombresUsuarios[deuda['deudor']] ?? 'Usuario';
    final nombreAcreedor = _nombresUsuarios[deuda['acreedor']] ?? 'Usuario';

    // Determinar el texto según el rol del usuario
    String textoDeuda;
    Color colorFondo;
    Color colorIcono;
    IconData icono;
    Color colorTexto;

    if (esDeudor) {
      textoDeuda = 'Debes a $nombreAcreedor';
      colorFondo = Colors.red.shade100;
      colorIcono = Colors.red.shade400;
      icono = Icons.money_off;
      colorTexto = Colors.red;
    } else {
      textoDeuda = '$nombreDeudor te debe';
      colorFondo = Colors.green.shade100;
      colorIcono = Colors.green.shade400;
      icono = Icons.attach_money;
      colorTexto = Colors.green;
    }

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
              color: colorFondo,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: colorIcono),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  textoDeuda,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Creada: ${DateFormat('dd MMM yyyy').format(deuda['creadoEn'])}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Últ. actualización: ${DateFormat('dd MMM').format(deuda['ultimaActualizacion'])}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(deuda['monto'] as num).toStringAsFixed(2)} €',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorTexto,
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

  String _obtenerDiaCorto(int weekday) {
    const dias = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];
    return dias[weekday - 1];
  }
}
