import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'lista_compra.dart';
import 'principal.dart';
import 'perfil.dart';
import 'calendar.dart';

class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key});

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  late DateTime _fechaSeleccionada;
  late List<DateTime> _semanaActual;
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _firestore = FirebaseFirestore.instance;

  int _currentIndex = 1;
  String nombreHogar = 'Tareas';

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = DateTime.now();
    _semanaActual = _generarSemana(_fechaSeleccionada);
  }

  List<DateTime> _generarSemana(DateTime fecha) {
    final startOfWeek = fecha.subtract(Duration(days: fecha.weekday - 1));
    return List.generate(6, (index) => startOfWeek.add(Duration(days: index)));
  }

  int _obtenerSemanaMes(DateTime fecha) {
    DateTime fechaAjustada = fecha;

    if (fecha.day > 28) {
      int diasEnProximoMes = 0;
      for (int i = 0; i < 7; i++) {
        DateTime diaSemana = fecha
            .subtract(Duration(days: fecha.weekday - 1))
            .add(Duration(days: i));
        if (diaSemana.month != fecha.month) {
          diasEnProximoMes++;
        }
      }

      if (diasEnProximoMes >= 4) {
        fechaAjustada = fecha.add(Duration(days: 7 - fecha.weekday + 1));
      }
    }

    final firstDay = DateTime(fechaAjustada.year, fechaAjustada.month, 1);
    return ((fechaAjustada.difference(firstDay).inDays + firstDay.weekday) / 7)
        .ceil();
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
                    'Mis Tareas',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.calendar_month, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CalendarioScreen(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person,
                              size: 24, color: Colors.teal),
                        ),
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
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlanificacionSemanal(),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        "Tareas Semanales",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                    ),
                    _buildListaTareas(),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        "Tareas de Hoy",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54),
                      ),
                    ),
                    _buildListaTareasHoy(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildPlanificacionSemanal() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _semanaActual.map((fecha) => _buildDiaItem(fecha)).toList(),
        ),
      ),
    );
  }

  Widget _buildDiaItem(DateTime fecha) {
    final isSelected = fecha.day == _fechaSeleccionada.day;
    return GestureDetector(
      onTap: () {
        setState(() {
          _fechaSeleccionada = fecha;
          _semanaActual =
              _generarSemana(fecha); // Actualizar la semana completa
        });
      },
      child: Column(
        children: [
          Text(
            _obtenerDiaCorto(fecha.weekday),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.teal : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${fecha.day}",
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _obtenerDiaCorto(int weekday) {
    const dias = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa'];
    return dias[weekday - 1];
  }

  bool _esSemanaCambioDeMes(DateTime fecha) {
    final ultimoDiaMes = DateTime(fecha.year, fecha.month + 1, 0);
    final diferenciaDias = ultimoDiaMes.difference(fecha).inDays;
    return diferenciaDias < 7;
  }

  Widget _buildListaTareas() {
    final semanaActual = _obtenerSemanaMes(_fechaSeleccionada);
    final mesActual = _fechaSeleccionada.month;
    final anoActual = _fechaSeleccionada.year;

    final hoy = DateTime.now();
    final esSemanaCambioMes = _esSemanaCambioDeMes(hoy);

    // Stream base para el mes actual
    final streamMesActual = _firestore
        .collection('tareas')
        .where('mes', isEqualTo: mesActual)
        .where('año', isEqualTo: anoActual)
        .where('tipo', isEqualTo: 'semanal')
        .snapshots();

    // Stream para el mes siguiente (si la semana cruza el mes)
    final streamMesSiguiente = esSemanaCambioMes
        ? _firestore
            .collection('tareas')
            .where('mes', isEqualTo: mesActual == 12 ? 1 : mesActual + 1)
            .where('año',
                isEqualTo: mesActual == 12 ? anoActual + 1 : anoActual)
            .where('tipo', isEqualTo: 'semanal')
            .snapshots()
        : null;

    return StreamBuilder<QuerySnapshot>(
      stream: streamMesActual,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        List<DocumentSnapshot> tareasSemanaActual =
            snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final estaAsignado =
              (data['asignados'] as List?)?.contains(userId) ?? false;
          final semanas = List<int>.from(data['semanas'] ?? []);

          return estaAsignado && semanas.contains(semanaActual);
        }).toList();

        if (streamMesSiguiente == null) {
          return _mostrarListaTareas(tareasSemanaActual);
        }

        return StreamBuilder<QuerySnapshot>(
          stream: streamMesSiguiente,
          builder: (context, snapshotSiguiente) {
            if (snapshotSiguiente.hasData) {
              final tareasMesSiguiente =
                  snapshotSiguiente.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final estaAsignado =
                    (data['asignados'] as List?)?.contains(userId) ?? false;
                final semanas = List<int>.from(data['semanas'] ?? []);

                return estaAsignado && semanas.contains(1);
              }).toList();

              tareasSemanaActual.addAll(tareasMesSiguiente);
            }

            return _mostrarListaTareas(tareasSemanaActual);
          },
        );
      },
    );
  }

  Widget _mostrarListaTareas(List<DocumentSnapshot> tareas) {
    if (tareas.isEmpty) {
      return _buildMensajeSinTareas("No hay tareas para esta semana");
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ...tareas.map((doc) => _buildTareaCard(doc)).toList(),
      ],
    );
  }

  Widget _buildMensajeSinTareas(String mensaje) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text(
          mensaje,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildListaTareasHoy() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('tareas').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();

        final tasks = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final esCreador = data['usuarioId'] == userId;
          final estaAsignado =
              (data['asignados'] as List?)?.contains(userId) ?? false;

          if (!esCreador && !estaAsignado) return false;

          if (data['tipo'] == 'puntual') {
            final fecha = (data['fecha'] as Timestamp).toDate();
            return DateUtils.isSameDay(fecha, _fechaSeleccionada);
          }
          return false;
        }).toList();

        if (tasks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                "No hay tareas para el día seleccionado",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          );
        }

        return Column(
          children: tasks.map((doc) => _buildTareaCard(doc)).toList(),
        );
      },
    );
  }

  Widget _buildTareaCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final completada = data['completada'] ?? false;
    final esCreador = data['usuarioId'] == userId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () {
          _mostrarDetallesTarea(data);
        },
        child: Container(
          decoration: BoxDecoration(
            color: completada ? Colors.teal : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 5,
                  offset: const Offset(2, 2))
            ],
          ),
          child: ListTile(
            leading: IconButton(
              icon: Icon(
                completada ? Icons.check_circle : Icons.radio_button_unchecked,
                color: completada ? Colors.white : Colors.teal,
              ),
              onPressed: () => _actualizarEstadoTarea(doc.id, !completada),
            ),
            title: Row(
              children: [
                if (!esCreador)
                  const Icon(Icons.person, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['titulo'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: completada ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['descripcion'],
                  style: TextStyle(
                      color: completada ? Colors.white70 : Colors.black54),
                ),
                if (data['asignados'] != null)
                  Wrap(
                    spacing: 4,
                    children: (data['asignados'] as List)
                        .map<Widget>((uid) => FutureBuilder<DocumentSnapshot>(
                              future: _firestore
                                  .collection('usuarios')
                                  .doc(uid)
                                  .get(),
                              builder: (context, snapshot) {
                                final nombre = snapshot.hasData
                                    ? snapshot.data!['nombre'] ?? 'Usuario'
                                    : '...';
                                return Chip(
                                  label: Text(nombre),
                                  backgroundColor: Colors.orange.shade100,
                                  visualDensity: VisualDensity.compact,
                                );
                              },
                            ))
                        .toList(),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: completada ? Colors.white : Colors.black54,
              ),
              color: Colors.white,
              onSelected: (value) {
                if (value == 'editar') {
                  _mostrarModalEditarTarea(doc);
                } else if (value == 'eliminar') {
                  _mostrarDialogoConfirmacionEliminar(doc.id);
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'editar',
                  child: Row(
                    children: const [
                      Icon(Icons.edit, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'eliminar',
                  child: Row(
                    children: const [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetallesTarea(Map<String, dynamic> data) {
    final fecha =
        data['fecha'] != null ? (data['fecha'] as Timestamp).toDate() : null;
    final fechaCreacion = data['fechaCreacion'] != null
        ? (data['fechaCreacion'] as Timestamp).toDate()
        : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                data['titulo'] ?? 'Sin título',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildDetalleItem(
              icon: Icons.description,
              label: 'Descripción:',
              value: data['descripcion'] ?? 'Sin descripción',
            ),
            _buildDetalleItem(
              icon: Icons.calendar_today,
              label: 'Tipo:',
              value:
                  data['tipo'] == 'puntual' ? 'Tarea puntual' : 'Tarea semanal',
            ),
            if (data['tipo'] == 'puntual' && fecha != null)
              _buildDetalleItem(
                icon: Icons.date_range,
                label: 'Fecha:',
                value: DateFormat('dd/MM/yyyy').format(fecha),
              ),
            if (data['tipo'] == 'semanal')
              _buildDetalleItem(
                icon: Icons.calendar_view_week,
                label: 'Semanas:',
                value: (data['semanas'] as List?)?.join(', ') ?? '',
              ),
            _buildDetalleItem(
              icon: Icons.calendar_month,
              label: 'Periodo:',
              value: '${_obtenerNombreMes(data['mes'])} ${data['año']}',
            ),
            FutureBuilder<DocumentSnapshot>(
              future: _firestore
                  .collection('usuarios')
                  .doc(data['usuarioId'])
                  .get(),
              builder: (context, snapshot) {
                final creador = snapshot.hasData
                    ? snapshot.data!['nombre'] ?? 'Usuario desconocido'
                    : 'Cargando...';
                return _buildDetalleItem(
                  icon: Icons.person,
                  label: 'Creado por:',
                  value: creador,
                );
              },
            ),
            if (fechaCreacion != null)
              _buildDetalleItem(
                icon: Icons.timer,
                label: 'Fecha creación:',
                value: DateFormat('dd/MM/yyyy').format(fechaCreacion),
              ),
            if (data['asignados'] != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Asignada a:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (data['asignados'] as List).map<Widget>((uid) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('usuarios').doc(uid).get(),
                    builder: (context, snapshot) {
                      final nombre = snapshot.hasData
                          ? snapshot.data!['nombre'] ?? 'Usuario'
                          : '...';
                      return Chip(
                        label: Text(nombre),
                        backgroundColor: Colors.orange.shade100,
                      );
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _obtenerNombreMes(int mes) {
    final meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    return meses[mes - 1];
  }

  void _mostrarDialogoConfirmacionEliminar(String taskId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          backgroundColor: Colors.white,
          content:
              const Text('¿Estás seguro de que quieres eliminar esta tarea?'),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('Cancelar', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            TextButton(
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.orange)),
              onPressed: () {
                _eliminarTarea(taskId); // Llama al método de eliminación
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarTarea(String taskId) async {
    try {
      await _firestore.collection('tareas').doc(taskId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarea eliminada exitosamente')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar tarea: ${e.toString()}')),
      );
    }
  }

  void _mostrarModalEditarTarea(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => EditarTareaForm(
        tareaId: doc.id,
        tituloInicial: data['titulo'],
        descripcionInicial: data['descripcion'],
        tipoInicial: data['tipo'],
        fechaInicial: data['tipo'] == 'puntual'
            ? (data['fecha'] as Timestamp).toDate()
            : null,
        semanasIniciales: List<int>.from(data['semanas'] ?? []),
        asignadosIniciales: List<String>.from(data['asignados'] ?? []),
        mesInicial: data['mes'],
        anoInicial: data['año'],
        userId: userId,
        onTaskUpdated: () => setState(() {}),
      ),
    );
  }

  Future<void> _actualizarEstadoTarea(String taskId, bool completada) async {
    await _firestore
        .collection('tareas')
        .doc(taskId)
        .update({'completada': completada});
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _mostrarModalCrearTarea,
      backgroundColor: Colors.orange,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _mostrarModalCrearTarea() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => CrearTareaForm(
        userId: userId,
        onTaskCreated: () => setState(() {}),
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
}

class CrearTareaForm extends StatefulWidget {
  final String userId;
  final VoidCallback onTaskCreated;

  const CrearTareaForm(
      {super.key, required this.userId, required this.onTaskCreated});

  @override
  State<CrearTareaForm> createState() => _CrearTareaFormState();
}

class _CrearTareaFormState extends State<CrearTareaForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  DateTime? _fechaSeleccionada;
  List<int> _semanasSeleccionadas = [];
  List<String> _miembrosSeleccionados = [];
  bool _esSemanal = false;
  List<String> _miembrosHogar = [];
  int _mesSeleccionado = DateTime.now().month;
  int _anoSeleccionado = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _cargarMiembrosHogar();
    _verificarSemanaCambioMes();
  }

  void _verificarSemanaCambioMes() {
    final hoy = DateTime.now();
    final ultimoDiaMes = DateTime(hoy.year, hoy.month + 1, 0);
    final diferenciaDias = ultimoDiaMes.day - hoy.day;

    if (diferenciaDias <= 3) {
      setState(() {
        if (hoy.month == 12) {
          _mesSeleccionado = 1;
          _anoSeleccionado = hoy.year + 1;
        } else {
          _mesSeleccionado = hoy.month + 1;
          _anoSeleccionado = hoy.year;
        }
      });
    }
  }

  Future<void> _cargarMiembrosHogar() async {
    final hogarSnapshot = await FirebaseFirestore.instance
        .collection('hogar')
        .where('miembros', arrayContains: widget.userId)
        .limit(1)
        .get();

    if (hogarSnapshot.docs.isNotEmpty) {
      setState(() {
        _miembrosHogar =
            List<String>.from(hogarSnapshot.docs.first['miembros']);
      });
    }
  }

  Future<void> _seleccionarFecha() async {
    await initializeDateFormatting('es_ES', null);

    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (fecha != null) {
      setState(() => _fechaSeleccionada = fecha);
    }
  }

  void _toggleSemana(int semana) {
    setState(() {
      if (_semanasSeleccionadas.contains(semana)) {
        _semanasSeleccionadas.remove(semana);
      } else {
        _semanasSeleccionadas.add(semana);
      }
    });
  }

  Future<void> _crearTarea() async {
    if (!_formKey.currentState!.validate()) return; // Validar formulario

    if (!_esSemanal && _fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona una fecha para tareas puntuales')),
      );
      return;
    }

    if (_esSemanal && _semanasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una semana')),
      );
      return;
    }

    final taskData = {
      'titulo': _tituloController.text,
      'descripcion': _descripcionController.text,
      'completada': false,
      'usuarioId': widget.userId,
      'tipo': _esSemanal ? 'semanal' : 'puntual',
      'fechaCreacion': Timestamp.now(),
      'mes': _esSemanal ? _mesSeleccionado : _fechaSeleccionada!.month,
      'año': _esSemanal ? _anoSeleccionado : _fechaSeleccionada!.year,
      'asignados': _miembrosSeleccionados,
    };

    if (_esSemanal) {
      taskData['semanas'] = _semanasSeleccionadas;
    } else {
      taskData['fecha'] = Timestamp.fromDate(_fechaSeleccionada!);
    }

    try {
      await FirebaseFirestore.instance.collection('tareas').add(taskData);
      widget.onTaskCreated();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear tarea: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meses = DateFormat.MMMM('es').dateSymbols.MONTHS;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Nueva Tarea',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _tituloController,
              decoration: InputDecoration(
                labelText: 'Título',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                prefixIcon: const Icon(Icons.title, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
              ),
              validator: (value) => value!.isEmpty ? 'Ingrese un título' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _descripcionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.teal),
                ),
                prefixIcon: const Icon(Icons.description, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Tipo de tarea:',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Puntual'),
                  selected: !_esSemanal,
                  selectedColor: Colors.orange,
                  backgroundColor: Colors.white,
                  onSelected: (val) => setState(() => _esSemanal = !val),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Semanal'),
                  selected: _esSemanal,
                  selectedColor: Colors.orange,
                  backgroundColor: Colors.white,
                  onSelected: (val) => setState(() => _esSemanal = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!_esSemanal)
              InkWell(
                onTap: _seleccionarFecha,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha',
                    labelStyle: const TextStyle(color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.teal),
                    ),
                    prefixIcon:
                        const Icon(Icons.calendar_today, color: Colors.teal),
                    filled: true,
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Colors.teal, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _fechaSeleccionada != null
                            ? DateFormat('dd/MM/yyyy')
                                .format(_fechaSeleccionada!)
                            : 'Seleccionar fecha',
                        style: const TextStyle(color: Colors.black),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.teal),
                    ],
                  ),
                ),
              ),
            if (_esSemanal) ...[
              const SizedBox(height: 20),
              const Text(
                'Mes para las tareas semanales:',
                style: TextStyle(fontSize: 16, color: Colors.teal),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _mesSeleccionado,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: List.generate(12, (index) {
                  final mesNumero = index + 1;
                  return DropdownMenuItem<int>(
                    value: mesNumero,
                    child: Text(
                      '${meses[index]} ${_anoSeleccionado}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    _mesSeleccionado = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Semanas del mes:',
                style: TextStyle(fontSize: 16, color: Colors.teal),
              ),
              Wrap(
                spacing: 8,
                children: List.generate(5, (index) {
                  final semana = index + 1;
                  return FilterChip(
                    label: Text('Semana $semana'),
                    selected: _semanasSeleccionadas.contains(semana),
                    selectedColor: Colors.orange,
                    backgroundColor: Colors.white,
                    onSelected: (val) => _toggleSemana(semana),
                  );
                }),
              ),
              const SizedBox(height: 10),
              const Text(
                'Asignar a miembros:',
                style: TextStyle(fontSize: 16, color: Colors.teal),
              ),
              Wrap(
                spacing: 8,
                children: _miembrosHogar.map((miembro) {
                  return FilterChip(
                    label: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(miembro)
                          .get(),
                      builder: (context, snapshot) {
                        final nombre = snapshot.hasData
                            ? snapshot.data!['nombre'] ?? 'Usuario'
                            : '...';
                        return Text(nombre);
                      },
                    ),
                    selected: _miembrosSeleccionados.contains(miembro),
                    selectedColor: Colors.orange,
                    backgroundColor: Colors.white,
                    onSelected: (val) => setState(() {
                      if (val) {
                        _miembrosSeleccionados.add(miembro);
                      } else {
                        _miembrosSeleccionados.remove(miembro);
                      }
                    }),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _crearTarea,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Crear Tarea',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class EditarTareaForm extends StatefulWidget {
  final String tareaId;
  final String tituloInicial;
  final String descripcionInicial;
  final String tipoInicial;
  final DateTime? fechaInicial;
  final List<int> semanasIniciales;
  final List<String> asignadosIniciales;
  final int mesInicial;
  final int anoInicial;
  final String userId;
  final VoidCallback onTaskUpdated;

  const EditarTareaForm({
    super.key,
    required this.tareaId,
    required this.tituloInicial,
    required this.descripcionInicial,
    required this.tipoInicial,
    this.fechaInicial,
    required this.semanasIniciales,
    required this.asignadosIniciales,
    required this.mesInicial,
    required this.anoInicial,
    required this.userId,
    required this.onTaskUpdated,
  });

  @override
  State<EditarTareaForm> createState() => _EditarTareaFormState();
}

class _EditarTareaFormState extends State<EditarTareaForm> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final TextEditingController _tituloController;
  late final TextEditingController _descripcionController;

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (fecha != null) {
      setState(() => _fechaSeleccionada = fecha);
    }
  }

  DateTime? _fechaSeleccionada;
  List<int> _semanasSeleccionadas = [];
  List<String> _miembrosSeleccionados = [];
  bool _esSemanal = false;
  List<String> _miembrosHogar = [];
  int _mesSeleccionado = DateTime.now().month;
  int _anoSeleccionado = DateTime.now().year;

  void _toggleSemana(int semana) {
    setState(() {
      if (_semanasSeleccionadas.contains(semana)) {
        _semanasSeleccionadas.remove(semana);
      } else {
        _semanasSeleccionadas.add(semana);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.tituloInicial);
    _descripcionController =
        TextEditingController(text: widget.descripcionInicial);
    _esSemanal = widget.tipoInicial == 'semanal';
    _fechaSeleccionada = widget.fechaInicial;
    _semanasSeleccionadas = widget.semanasIniciales;
    _miembrosSeleccionados = widget.asignadosIniciales;
    _mesSeleccionado = widget.mesInicial;
    _anoSeleccionado = widget.anoInicial;
    _cargarMiembrosHogar();
  }

  Future<void> _cargarMiembrosHogar() async {
    final hogarSnapshot = await FirebaseFirestore.instance
        .collection('hogar')
        .where('miembros', arrayContains: widget.userId)
        .limit(1)
        .get();

    if (hogarSnapshot.docs.isNotEmpty) {
      setState(() {
        _miembrosHogar =
            List<String>.from(hogarSnapshot.docs.first['miembros']);
      });
    }
  }

  Future<void> _actualizarTarea() async {
    if (!_formKey.currentState!.validate()) return; // Validar formulario

    if (!_esSemanal && _fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona una fecha para tareas puntuales')),
      );
      return;
    }

    if (_esSemanal && _semanasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una semana')),
      );
      return;
    }

    final taskData = {
      'titulo': _tituloController.text,
      'descripcion': _descripcionController.text,
      'tipo': _esSemanal ? 'semanal' : 'puntual',
      'mes': _esSemanal ? _mesSeleccionado : _fechaSeleccionada!.month,
      'año': _esSemanal ? _anoSeleccionado : _fechaSeleccionada!.year,
      'asignados': _miembrosSeleccionados,
      'fechaActualizacion': Timestamp.now(), // Añadir campo de actualización
    };

    if (_esSemanal) {
      taskData['semanas'] = _semanasSeleccionadas;
    } else {
      taskData['fecha'] = Timestamp.fromDate(_fechaSeleccionada!);
    }

    try {
      await _firestore
          .collection('tareas')
          .doc(widget.tareaId)
          .update(taskData);
      widget.onTaskUpdated();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meses = DateFormat.MMMM('es').dateSymbols.MONTHS;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Editar Tarea',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _tituloController,
              decoration: InputDecoration(
                labelText: 'Título',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                prefixIcon: const Icon(Icons.title, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
              ),
              validator: (value) => value!.isEmpty ? 'Ingrese un título' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _descripcionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.teal),
                ),
                prefixIcon: const Icon(Icons.description, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Tipo de tarea:',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Puntual'),
                  selected: !_esSemanal,
                  selectedColor: Colors.orange,
                  backgroundColor: Colors.white,
                  onSelected: (val) => setState(() => _esSemanal = !val),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Semanal'),
                  selected: _esSemanal,
                  selectedColor: Colors.orange,
                  backgroundColor: Colors.white,
                  onSelected: (val) => setState(() => _esSemanal = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!_esSemanal)
              InkWell(
                onTap: _seleccionarFecha,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha',
                    labelStyle: const TextStyle(color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.teal),
                    ),
                    prefixIcon:
                        const Icon(Icons.calendar_today, color: Colors.teal),
                    filled: true,
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide:
                          const BorderSide(color: Colors.teal, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _fechaSeleccionada != null
                            ? DateFormat('dd/MM/yyyy')
                                .format(_fechaSeleccionada!)
                            : 'Seleccionar fecha',
                        style: const TextStyle(color: Colors.black),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.teal),
                    ],
                  ),
                ),
              ),
            if (_esSemanal) ...[
              const SizedBox(height: 20),
              const Text(
                'Mes para las tareas semanales:',
                style: TextStyle(fontSize: 16, color: Colors.teal),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _mesSeleccionado,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: List.generate(12, (index) {
                  final mesNumero = index + 1;
                  return DropdownMenuItem<int>(
                    value: mesNumero,
                    child: Text(
                      '${meses[index]} ${_anoSeleccionado}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _mesSeleccionado = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Semanas del mes:',
                style: TextStyle(fontSize: 16, color: Colors.teal),
              ),
              Wrap(
                spacing: 8,
                children: List.generate(5, (index) {
                  final semana = index + 1;
                  return FilterChip(
                    label: Text('Semana $semana'),
                    selected: _semanasSeleccionadas.contains(semana),
                    selectedColor: Colors.orange,
                    backgroundColor: Colors.white,
                    onSelected: (val) => _toggleSemana(semana),
                  );
                }),
              ),
              const SizedBox(height: 10),
              const Text(
                'Asignar a miembros:',
                style: TextStyle(fontSize: 16, color: Colors.teal),
              ),
              Wrap(
                spacing: 8,
                children: _miembrosHogar.map((miembro) {
                  return FilterChip(
                    label: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(miembro)
                          .get(),
                      builder: (context, snapshot) {
                        final nombre = snapshot.hasData
                            ? snapshot.data!['nombre'] ?? 'Usuario'
                            : '...';
                        return Text(nombre);
                      },
                    ),
                    selected: _miembrosSeleccionados.contains(miembro),
                    selectedColor: Colors.orange,
                    backgroundColor: Colors.white,
                    onSelected: (val) => setState(() {
                      if (val) {
                        _miembrosSeleccionados.add(miembro);
                      } else {
                        _miembrosSeleccionados.remove(miembro);
                      }
                    }),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _actualizarTarea,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Actualizar Tarea',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
