import 'package:appfirebase/navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'perfil.dart';
import 'calendar.dart';

class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key});

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> with SingleTickerProviderStateMixin {
  late DateTime _fechaSeleccionada;
  late List<DateTime> _semanaActual;
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final int _currentIndex = 1;
  String nombreHogar = 'Tareas';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = DateTime.now();
    _semanaActual = _generarSemana(_fechaSeleccionada);
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      )
    );
    
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simular carga
    setState(() => _isLoading = false);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<DateTime>_generarSemana(DateTime fecha) {
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
      appBar: _buildAppBar(),
      body: _isLoading 
          ? _buildLoadingIndicator()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: _buildMainContent(),
            ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: _currentIndex, context: context),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      title: const Text(
        'Mis Tareas',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.teal,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.calendar_month, color: Colors.teal, size: 26),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) =>  CalendarioScreen()),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>  ProfileScreen()),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.teal,
                size: 20,
              ),
             
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            strokeWidth: 2,
          ),
          SizedBox(height: 16),
          Text(
            'Cargando tareas...',
            style: TextStyle(color: Colors.teal),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Column(
        children: [
          _buildWeekSelector(),
          Expanded(
            child: RefreshIndicator(
              color: Colors.teal,
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTaskSections(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.teal),
            onPressed: () => _navigateWeek(-1),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _semanaActual.map((fecha) => _buildDayItem(fecha)).toList(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.teal),
            onPressed: () => _navigateWeek(1),
          ),
        ],
      ),
    );
  }

  Widget _buildDayItem(DateTime fecha) {
    final isSelected = fecha.day == _fechaSeleccionada.day;
    final isToday = DateUtils.isSameDay(fecha, DateTime.now());
    
    return GestureDetector(
      onTap: () => setState(() {
        _fechaSeleccionada = fecha;
        _semanaActual = _generarSemana(fecha);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : (isToday ? Colors.orange.shade100 : null),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              _getShortWeekday(fecha.weekday),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${fecha.day}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: "Tareas Semanales",
          subtitle: "Semana ${_obtenerSemanaMes(_fechaSeleccionada)}",
          icon: Icons.calendar_view_week,
        ),
        _buildWeeklyTasksList(),
        
        _buildSectionHeader(
          title: "Tareas de Hoy",
          subtitle: DateFormat('EEEE, d MMMM', 'es_ES').format(_fechaSeleccionada),
          icon: Icons.today,
        ),
        _buildDailyTasksList(),
        
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, required String subtitle, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.teal),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTasksList() {
    final semanaActual = _obtenerSemanaMes(_fechaSeleccionada);
    final mesActual = _fechaSeleccionada.month;
    final anoActual = _fechaSeleccionada.year;
    final esSemanaCambioMes = _esSemanaCambioDeMes(DateTime.now());

    final streamMesActual = _firestore
        .collection('tareas')
        .where('mes', isEqualTo: mesActual)
        .where('año', isEqualTo: anoActual)
        .where('tipo', isEqualTo: 'semanal')
        .snapshots();

    final streamMesSiguiente = esSemanaCambioMes
        ? _firestore
            .collection('tareas')
            .where('mes', isEqualTo: mesActual == 12 ? 1 : mesActual + 1)
            .where('año', isEqualTo: mesActual == 12 ? anoActual + 1 : anoActual)
            .where('tipo', isEqualTo: 'semanal')
            .snapshots()
        : null;

    return StreamBuilder<QuerySnapshot>(
      stream: streamMesActual,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        List<DocumentSnapshot> tareasSemanaActual = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final estaAsignado = (data['asignados'] as List?)?.contains(userId) ?? false;
          final semanas = List<int>.from(data['semanas'] ?? []);
          return estaAsignado && semanas.contains(semanaActual);
        }).toList();

        if (streamMesSiguiente == null) {
          return _buildTasksList(tareasSemanaActual, emptyMessage: "No hay tareas para esta semana");
        }

        return StreamBuilder<QuerySnapshot>(
          stream: streamMesSiguiente,
          builder: (context, snapshotSiguiente) {
            if (snapshotSiguiente.hasData) {
              final tareasMesSiguiente = snapshotSiguiente.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final estaAsignado = (data['asignados'] as List?)?.contains(userId) ?? false;
                final semanas = List<int>.from(data['semanas'] ?? []);
                return estaAsignado && semanas.contains(1);
              }).toList();

              tareasSemanaActual.addAll(tareasMesSiguiente);
            }

            return _buildTasksList(tareasSemanaActual, emptyMessage: "No hay tareas para esta semana");
          },
        );
      },
    );
  }

  Widget _buildDailyTasksList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('tareas').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();

        final tasks = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final esCreador = data['usuarioId'] == userId;
          final estaAsignado = (data['asignados'] as List?)?.contains(userId) ?? false;

          if (!esCreador && !estaAsignado) return false;

          if (data['tipo'] == 'puntual') {
            final fecha = (data['fecha'] as Timestamp).toDate();
            return DateUtils.isSameDay(fecha, _fechaSeleccionada);
          }
          return false;
        }).toList();

        return _buildTasksList(tasks, emptyMessage: "No hay tareas para hoy");
      },
    );
  }

  Widget _buildTasksList(List<DocumentSnapshot> tasks, {required String emptyMessage}) {
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.assignment_outlined, size: 50, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text(
                emptyMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tasks.length,
        itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
      ),
    );
  }

  Widget _buildTaskCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final completada = data['completada'] ?? false;
    final esCreador = data['usuarioId'] == userId;
    final prioridad = (data['prioridad'] as int?) ?? 2; // 1=Alta, 2=Media, 3=Baja

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: completada 
              ? Colors.teal.withOpacity(0.3)
              : _getPriorityColor(prioridad).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _mostrarDetallesTarea(data),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox circular
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _actualizarEstadoTarea(doc.id, !completada),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: completada ? Colors.teal : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: completada ? Colors.teal : Colors.transparent,
                  ),
                  child: completada
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Contenido de la tarea
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!esCreador)
                          Icon(Icons.person_outline, size: 14, color: Colors.orange),
                        if (!esCreador) const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data['titulo'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: completada ? Colors.grey : Colors.black87,
                              decoration: completada ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      data['descripcion'] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: completada ? Colors.grey.shade500 : Colors.grey.shade700,
                        decoration: completada ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    if (data['asignados'] != null)
                      SizedBox(
                        height: 28,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: (data['asignados'] as List).map<Widget>((uid) {
                            return FutureBuilder<DocumentSnapshot>(
                              future: _firestore.collection('usuarios').doc(uid).get(),
                              builder: (context, snapshot) {
                                final nombre = snapshot.hasData
                                    ? (snapshot.data!['nombre'] as String?)?.split(' ').first ?? 'Usuario'
                                    : '...';
                                return Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    nombre,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Menú de opciones
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
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
                        Icon(Icons.edit, color: Colors.teal, size: 20),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'eliminar',
                    child: Row(
                      children: const [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Eliminar'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.green;
      default: return Colors.grey;
    }
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _mostrarModalCrearTarea,
      backgroundColor: Colors.orange,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }



  // Métodos auxiliares
  String _getShortWeekday(int weekday) {
    const dias = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa'];
    return dias[weekday - 1];
  }

  bool _esSemanaCambioDeMes(DateTime fecha) {
    final ultimoDiaMes = DateTime(fecha.year, fecha.month + 1, 0);
    final diferenciaDias = ultimoDiaMes.difference(fecha).inDays;
    return diferenciaDias < 7;
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {});
  }

  void _navigateWeek(int direction) {
    setState(() {
      _fechaSeleccionada = _fechaSeleccionada.add(Duration(days: 7 * direction));
      _semanaActual = _generarSemana(_fechaSeleccionada);
    });
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

  static Widget _buildDetalleItem({
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
                  style: TextStyle(color: Color.fromARGB(255, 255, 152, 0))),
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

}

class CrearTareaForm extends StatefulWidget {
  final String userId;
  final VoidCallback onTaskCreated;

  const CrearTareaForm({
    super.key,
    required this.userId,
    required this.onTaskCreated,
  });

  @override
  State<CrearTareaForm> createState() => _CrearTareaFormState();
}

class _CrearTareaFormState extends State<CrearTareaForm> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  DateTime? _fechaSeleccionada;
  List<int> _semanasSeleccionadas = [];
  List<String> _miembrosSeleccionados = [];
  bool _esSemanal = false;
  List<String> _miembrosHogar = [];
  int _mesSeleccionado = DateTime.now().month;
  int _anoSeleccionado = DateTime.now().year;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarMiembrosHogar();
    _verificarSemanaCambioMes();
  }

  Future<void> _cargarMiembrosHogar() async {
    final hogarSnapshot = await FirebaseFirestore.instance
        .collection('hogar')
        .where('miembros', arrayContains: widget.userId)
        .limit(1)
        .get();

    if (hogarSnapshot.docs.isNotEmpty) {
      setState(() {
        _miembrosHogar = List<String>.from(hogarSnapshot.docs.first['miembros']);
        // Auto-seleccionar al usuario actual
        _miembrosSeleccionados.add(widget.userId);
      });
    }
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

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal,
              ),
            ),
          ),
          child: child!,
        );
      },
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
    if (!_formKey.currentState!.validate()) return;

    // Validaciones
    if (!_esSemanal && _fechaSeleccionada == null) {
      _mostrarError('Selecciona una fecha para tareas puntuales');
      return;
    }

    if (_esSemanal && _semanasSeleccionadas.isEmpty) {
      _mostrarError('Selecciona al menos una semana');
      return;
    }

    if (_esSemanal && _miembrosSeleccionados.isEmpty) {
      _mostrarError('Asigna la tarea a al menos un miembro');
      return;
    }

    setState(() => _isLoading = true);

    try {
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

      await FirebaseFirestore.instance.collection('tareas').add(taskData);
      
      widget.onTaskCreated();
      Navigator.pop(context);
    } catch (e) {
      _mostrarError('Error al crear tarea: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meses = DateFormat.MMMM('es').dateSymbols.MONTHS;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Nueva Tarea',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 48), // Para balancear el espacio
                  ],
                ),

                const SizedBox(height: 16),

                // Campo Título
                TextFormField(
                  controller: _tituloController,
                  decoration: InputDecoration(
                    labelText: 'Título de la tarea',
                    labelStyle: const TextStyle(color: Colors.grey),
                    floatingLabelStyle: const TextStyle(color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.title, color: Colors.teal),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 16),
                  validator: (value) =>
                      value!.isEmpty ? 'Este campo es obligatorio' : null,
                ),

                const SizedBox(height: 16),

                // Campo Descripción
                TextFormField(
                  controller: _descripcionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    floatingLabelStyle: const TextStyle(color: Colors.teal),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.description, color: Colors.teal),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 20),

                // Selector de Tipo de Tarea
                const Text(
                  'Tipo de tarea',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTaskTypeOption(
                        'Puntual',
                        Icons.calendar_today,
                        !_esSemanal,
                        () => setState(() => _esSemanal = false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTaskTypeOption(
                        'Semanal',
                        Icons.calendar_view_week,
                        _esSemanal,
                        () => setState(() => _esSemanal = true),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Contenido dinámico según tipo de tarea
                if (!_esSemanal) ...[
                  // Selector de fecha para tareas puntuales
                  InkWell(
                    onTap: _seleccionarFecha,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha',
                        labelStyle: const TextStyle(color: Colors.grey),
                        floatingLabelStyle: const TextStyle(color: Colors.teal),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.teal, width: 2),
                        ),
                        prefixIcon: const Icon(
                          Icons.event, color: Colors.teal),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _fechaSeleccionada != null
                                ? DateFormat('EEE, d MMM y', 'es_ES')
                                    .format(_fechaSeleccionada!)
                                : 'Seleccionar fecha',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Selector de mes para tareas semanales
                  const Text(
                    'Mes para las tareas semanales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _mesSeleccionado,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: List.generate(12, (index) {
                      final mesNumero = index + 1;
                      return DropdownMenuItem<int>(
                        value: mesNumero,
                        child: Text(
                          '${meses[index]} $_anoSeleccionado',
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _mesSeleccionado = value);
                      }
                    },
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),

                  const SizedBox(height: 20),

                  // Selector de semanas
                  const Text(
                    'Semanas del mes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(5, (index) {
                      final semana = index + 1;
                      return ChoiceChip(
                        label: Text('Semana $semana'),
                        selected: _semanasSeleccionadas.contains(semana),
                        selectedColor: Colors.teal,
                        backgroundColor: Colors.grey.shade100,
                        labelStyle: TextStyle(
                          color: _semanasSeleccionadas.contains(semana)
                              ? Colors.white
                              : Colors.black87,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onSelected: (selected) => _toggleSemana(semana),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // Selector de miembros
                  const Text(
                    'Asignar a miembros',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_miembrosHogar.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Cargando miembros...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Column(
                      children: _miembrosHogar.map((miembroId) {
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(miembroId)
                              .get(),
                          builder: (context, snapshot) {
                            final nombre = snapshot.hasData
                                ? snapshot.data!['nombre'] ?? 'Usuario'
                                : '...';
                            final esUsuarioActual = miembroId == widget.userId;
                            
                            return CheckboxListTile(
                              title: Text(
                                esUsuarioActual ? '$nombre (Tú)' : nombre,
                                style: const TextStyle(fontSize: 15),
                              ),
                              value: _miembrosSeleccionados.contains(miembroId),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _miembrosSeleccionados.add(miembroId);
                                  } else {
                                    _miembrosSeleccionados.remove(miembroId);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              activeColor: Colors.teal,
                            );
                          },
                        );
                      }).toList(),
                    ),
                ],

                const SizedBox(height: 32),

                // Botón de crear
                ElevatedButton(
                  onPressed: _isLoading ? null : _crearTarea,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'CREAR TAREA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildTaskTypeOption(
      String label, IconData icon, bool selected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.teal.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.teal : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.teal : Colors.grey.shade700,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.teal : Colors.grey.shade700,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
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
  late DateTime? _fechaSeleccionada;
  late List<int> _semanasSeleccionadas;
  late List<String> _miembrosSeleccionados;
  late bool _esSemanal;
  List<String> _miembrosHogar = [];
  late int _mesSeleccionado;
  late int _anoSeleccionado;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.tituloInicial);
    _descripcionController = TextEditingController(text: widget.descripcionInicial);
    _esSemanal = widget.tipoInicial == 'semanal';
    _fechaSeleccionada = widget.fechaInicial;
    _semanasSeleccionadas = widget.semanasIniciales;
    _miembrosSeleccionados = widget.asignadosIniciales;
    _mesSeleccionado = widget.mesInicial;
    _anoSeleccionado = widget.anoInicial;
    _cargarMiembrosHogar();
  }

  Future<void> _cargarMiembrosHogar() async {
    final hogarSnapshot = await _firestore
        .collection('hogar')
        .where('miembros', arrayContains: widget.userId)
        .limit(1)
        .get();

    if (hogarSnapshot.docs.isNotEmpty) {
      setState(() {
        _miembrosHogar = List<String>.from(hogarSnapshot.docs.first['miembros']);
      });
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal,
              ),
            ),
          ),
          child: child!,
        );
      },
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

  Future<void> _actualizarTarea() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_esSemanal && _fechaSeleccionada == null) {
      _mostrarError('Selecciona una fecha para tareas puntuales');
      return;
    }

    if (_esSemanal && _semanasSeleccionadas.isEmpty) {
      _mostrarError('Selecciona al menos una semana');
      return;
    }

    if (_esSemanal && _miembrosSeleccionados.isEmpty) {
      _mostrarError('Asigna la tarea a al menos un miembro');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final taskData = {
        'titulo': _tituloController.text,
        'descripcion': _descripcionController.text,
        'tipo': _esSemanal ? 'semanal' : 'puntual',
        'mes': _esSemanal ? _mesSeleccionado : _fechaSeleccionada!.month,
        'año': _esSemanal ? _anoSeleccionado : _fechaSeleccionada!.year,
        'asignados': _miembrosSeleccionados,
        'fechaActualizacion': Timestamp.now(),
      };

      if (_esSemanal) {
        taskData['semanas'] = _semanasSeleccionadas;
      } else {
        taskData['fecha'] = Timestamp.fromDate(_fechaSeleccionada!);
      }

      await _firestore.collection('tareas').doc(widget.tareaId).update(taskData);
      
      widget.onTaskUpdated();
      Navigator.pop(context);
    } catch (e) {
      _mostrarError('Error al actualizar tarea: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meses = DateFormat.MMMM('es').dateSymbols.MONTHS;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Editar Tarea',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 48), // Para balancear el espacio
                  ],
                ),

                const SizedBox(height: 16),

                // Campo Título
                TextFormField(
                  controller: _tituloController,
                  decoration: InputDecoration(
                    labelText: 'Título de la tarea',
                    labelStyle: const TextStyle(color: Colors.grey),
                    floatingLabelStyle: const TextStyle(color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.title, color: Colors.teal),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 16),
                  validator: (value) =>
                      value!.isEmpty ? 'Este campo es obligatorio' : null,
                ),

                const SizedBox(height: 16),

                // Campo Descripción
                TextFormField(
                  controller: _descripcionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    floatingLabelStyle: const TextStyle(color: Colors.teal),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.description, color: Colors.teal),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 20),

                // Selector de Tipo de Tarea
                const Text(
                  'Tipo de tarea',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTaskTypeOption(
                        'Puntual',
                        Icons.calendar_today,
                        !_esSemanal,
                        () => setState(() => _esSemanal = false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTaskTypeOption(
                        'Semanal',
                        Icons.calendar_view_week,
                        _esSemanal,
                        () => setState(() => _esSemanal = true),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Contenido dinámico según tipo de tarea
                if (!_esSemanal) ...[
                  // Selector de fecha para tareas puntuales
                  InkWell(
                    onTap: _seleccionarFecha,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Fecha',
                        labelStyle: const TextStyle(color: Colors.grey),
                        floatingLabelStyle: const TextStyle(color: Colors.teal),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.teal, width: 2),
                        ),
                        prefixIcon: const Icon(
                          Icons.event, color: Colors.teal),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _fechaSeleccionada != null
                                ? DateFormat('EEE, d MMM y', 'es_ES')
                                    .format(_fechaSeleccionada!)
                                : 'Seleccionar fecha',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Selector de mes para tareas semanales
                  const Text(
                    'Mes para las tareas semanales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _mesSeleccionado,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: List.generate(12, (index) {
                      final mesNumero = index + 1;
                      return DropdownMenuItem<int>(
                        value: mesNumero,
                        child: Text(
                          '${meses[index]} $_anoSeleccionado',
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _mesSeleccionado = value);
                      }
                    },
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),

                  const SizedBox(height: 20),

                  // Selector de semanas
                  const Text(
                    'Semanas del mes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(5, (index) {
                      final semana = index + 1;
                      return ChoiceChip(
                        label: Text('Semana $semana'),
                        selected: _semanasSeleccionadas.contains(semana),
                        selectedColor: Colors.teal,
                        backgroundColor: Colors.grey.shade100,
                        labelStyle: TextStyle(
                          color: _semanasSeleccionadas.contains(semana)
                              ? Colors.white
                              : Colors.black87,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onSelected: (selected) => _toggleSemana(semana),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // Selector de miembros
                  const Text(
                    'Asignar a miembros',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_miembrosHogar.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Cargando miembros...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    Column(
                      children: _miembrosHogar.map((miembroId) {
                        return FutureBuilder<DocumentSnapshot>(
                          future: _firestore
                              .collection('usuarios')
                              .doc(miembroId)
                              .get(),
                          builder: (context, snapshot) {
                            final nombre = snapshot.hasData
                                ? snapshot.data!['nombre'] ?? 'Usuario'
                                : '...';
                            final esUsuarioActual = miembroId == widget.userId;
                            
                            return CheckboxListTile(
                              title: Text(
                                esUsuarioActual ? '$nombre (Tú)' : nombre,
                                style: const TextStyle(fontSize: 15),
                              ),
                              value: _miembrosSeleccionados.contains(miembroId),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _miembrosSeleccionados.add(miembroId);
                                  } else {
                                    _miembrosSeleccionados.remove(miembroId);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              activeColor: Colors.teal,
                            );
                          },
                        );
                      }).toList(),
                    ),
                ],

                const SizedBox(height: 32),

                // Botón de actualizar
                ElevatedButton(
                  onPressed: _isLoading ? null : _actualizarTarea,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'ACTUALIZAR TAREA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTypeOption(
      String label, IconData icon, bool selected, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.teal.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.teal : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.teal : Colors.grey.shade700,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.teal : Colors.grey.shade700,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
