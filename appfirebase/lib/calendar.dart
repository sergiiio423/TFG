import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'dart:async';
import 'perfil.dart';
import 'navigation_bar.dart';

class CalendarioScreen extends StatefulWidget {
  @override
  _CalendarioScreenState createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _dailyTasks = {};
  List<Map<String, dynamic>> _weeklyTasks = [];
  Map<String, String> _userNames = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  int _currentIndex = 1;
  List<String> _householdMembers = [];
  StreamSubscription? _householdSubscription;
  StreamSubscription? _tasksSubscription;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null).then((_) {
      setState(() {});
    });
    _selectedDay = _focusedDay;
    _loadUserNames();
    _setupHouseholdListener();
  }

  @override
  void dispose() {
    _householdSubscription?.cancel();
    _tasksSubscription?.cancel();
    super.dispose();
  }

  void _setupHouseholdListener() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    _householdSubscription = FirebaseFirestore.instance
        .collection('hogar')
        .where('miembros', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _householdMembers =
              List<String>.from(snapshot.docs.first['miembros']);
        });
        
        _loadTasksFromFirestore();
      }
    }, onError: (e) {
      print('Error al escuchar hogar: $e');
    });
  }

  void _loadTasksFromFirestore() {
    _tasksSubscription?.cancel(); 

    _tasksSubscription = FirebaseFirestore.instance
        .collection('tareas')
        .snapshots()
        .listen((snapshot) {
      Map<DateTime, List<Map<String, dynamic>>> tempDailyTasks = {};
      List<Map<String, dynamic>> tempWeeklyTasks = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        data['id'] = doc.id;

        if (data['tipo'] == 'puntual' &&
            data['fecha'] is Timestamp &&
            data['usuarioId'] == userId) {
          DateTime taskDate = (data['fecha'] as Timestamp).toDate();
          DateTime normalizedDate =
              DateTime(taskDate.year, taskDate.month, taskDate.day);
          tempDailyTasks.putIfAbsent(normalizedDate, () => []).add(data);
        }
        else if (data['tipo'] == 'semanal' &&
            _householdMembers.contains(data['usuarioId'])) {
          tempWeeklyTasks.add(data);
        }
      }

      setState(() {
        _dailyTasks = tempDailyTasks;
        _weeklyTasks = tempWeeklyTasks;
      });
    }, onError: (e) {
      print('Error al cargar tareas: $e');
    });
  }

  Future<void> _loadUserNames() async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('usuarios').get();
      setState(() {
        _userNames = {
          for (var doc in usersSnapshot.docs)
            doc.id: doc['nombre'] ?? 'Usuario desconocido'
        };
      });
    } catch (e) {
      print('Error al cargar nombres de usuarios: $e');
    }
  }

  List<Map<String, dynamic>> _getDailyTasks(DateTime day) {
    return _dailyTasks[DateTime(day.year, day.month, day.day)] ?? [];
  }

  List<Map<String, dynamic>> _getWeeklyTasksForDay(DateTime day) {
    return _weeklyTasks.where((task) {
      final semanas = List<int>.from(task['semanas'] ?? []);
      final mes = task['mes'] as int?;
      final ano = task['año'] as int?;

      if (mes == null || ano == null) return false;

      final weekOfMonth = ((day.day - 1) ~/ 7) + 1;
      return semanas.contains(weekOfMonth) &&
          day.month == mes &&
          day.year == ano;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dailyTasks = _getDailyTasks(_selectedDay!);
    final weeklyTasks = _getWeeklyTasksForDay(_selectedDay!);

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
                    'Calendario',
                    style: const TextStyle(
                      fontSize: 26,
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
            ),
            Expanded(
              child: Column(
                children: [
                  _buildCalendar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(
                          bottom: 80), 
                      child: Column(
                        children: [
                          if (weeklyTasks.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Tareas Semanales',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              children: weeklyTasks
                                  .map((task) => _buildTaskCard(task))
                                  .toList(),
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Tareas del Día',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ),
                          dailyTasks.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text("No hay tareas para este día"),
                                )
                              : Column(
                                  children: dailyTasks
                                      .map((task) => _buildTaskCard(task))
                                      .toList(),
                                ),
                          const SizedBox(
                              height: 60), 
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: _currentIndex, context: context),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _mostrarModalCrearTarea(context),
      backgroundColor: Colors.orange,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        locale: 'es_ES',
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        availableGestures: AvailableGestures.all,
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.orange.shade100,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.teal,
            shape: BoxShape.circle,
          ),
          markersAlignment: Alignment.bottomCenter,
          markerDecoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: Colors.red.shade400),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          formatButtonShowsNext: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        eventLoader: (day) {
          final dailyTasks = _getDailyTasks(day);
          final weeklyTasks = _getWeeklyTasksForDay(day);

          if (dailyTasks.isNotEmpty && weeklyTasks.isNotEmpty) {
            return [1, 2];
          } else if (dailyTasks.isNotEmpty) {
            return [1];
          } else if (weeklyTasks.isNotEmpty) {
            return [2];
          }
          return [];
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox();

            final hasDaily = events.contains(1);
            final hasWeekly = events.contains(2);

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasDaily)
                  Container(
                    margin: const EdgeInsets.only(right: 2),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (hasWeekly)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final bool completada = task['completada'] ?? false;
    final String tipo = task['tipo'] ?? 'puntual';
    final List<dynamic> asignados = task['asignados'] ?? [];
    final Color cardColor =
        tipo == 'semanal' ? Colors.teal.shade50 : Colors.orange.shade50;
    final fecha = task['tipo'] == 'puntual' && task['fecha'] != null
        ? (task['fecha'] as Timestamp).toDate()
        : null;
    final fechaCreacion = task['fechaCreacion'] != null
        ? (task['fechaCreacion'] as Timestamp).toDate()
        : null;

    return GestureDetector(
      onTap: () {
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
                    task['titulo'] ?? 'Sin título',
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
                  value: task['descripcion'] ?? 'Sin descripción',
                ),
                _buildDetalleItem(
                  icon: Icons.calendar_today,
                  label: 'Tipo:',
                  value: task['tipo'] == 'puntual'
                      ? 'Tarea puntual'
                      : 'Tarea semanal',
                ),
                if (task['tipo'] == 'puntual' && fecha != null)
                  _buildDetalleItem(
                    icon: Icons.date_range,
                    label: 'Fecha:',
                    value: DateFormat('dd/MM/yyyy').format(fecha),
                  ),
                if (task['tipo'] == 'semanal')
                  _buildDetalleItem(
                    icon: Icons.calendar_view_week,
                    label: 'Semanas:',
                    value: (task['semanas'] as List?)?.join(', ') ?? '',
                  ),
                _buildDetalleItem(
                  icon: Icons.calendar_month,
                  label: 'Periodo:',
                  value: '${_obtenerNombreMes(task['mes'])} ${task['año']}',
                ),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(task['usuarioId'])
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
                if (asignados.isNotEmpty) ...[
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
                    children: (asignados as List).map<Widget>((uid) {
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
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
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 5,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: ListTile(
            leading: IconButton(
              icon: Icon(
                completada ? Icons.check_circle : Icons.radio_button_unchecked,
                color: completada ? Colors.teal : Colors.grey,
              ),
              onPressed: () => _toggleTaskCompletion(task),
            ),
            title: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task['titulo'] ?? 'Tarea sin nombre',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                      decoration:
                          completada ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task['descripcion'] != null &&
                    task['descripcion'].isNotEmpty)
                  Text(
                    task['descripcion'],
                    style: TextStyle(color: Colors.black54),
                  ),
                const SizedBox(height: 4),
                if (asignados.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: asignados
                        .map<Widget>((uid) => Chip(
                              label: Text(
                                _userNames[uid] ?? 'Usuario desconocido',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black54),
              color: Colors.white,
              onSelected: (value) => _handleTaskAction(value, task),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'eliminar',
                  child: Row(
                    children: [
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

  void _toggleTaskCompletion(Map<String, dynamic> task) {
    final bool currentStatus = task['completada'] ?? false;
    FirebaseFirestore.instance
        .collection('tareas')
        .doc(task['id'])
        .update({'completada': !currentStatus});
  }

  void _handleTaskAction(String action, Map<String, dynamic> task) {
    if (action == 'editar') {
      _mostrarModalEditarTarea(context, task);
    } else if (action == 'eliminar') {
      _confirmDeleteTask(task['id']);
    }
  }

  void _confirmDeleteTask(String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Eliminar tarea'),
        content:
            const Text('¿Estás seguro de que quieres eliminar esta tarea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('tareas')
                  .doc(taskId)
                  .delete();
              Navigator.pop(context);
            },
            child: const Text(
              'Eliminar',
              style:
                  TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarModalCrearTarea(BuildContext context) {
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

  void _mostrarModalEditarTarea(
      BuildContext context, Map<String, dynamic> task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => EditarTareaForm(
        tareaId: task['id'],
        tituloInicial: task['titulo'] ?? '',
        descripcionInicial: task['descripcion'] ?? '',
        tipoInicial: task['tipo'] ?? 'puntual',
        fechaInicial: task['tipo'] == 'puntual' && task['fecha'] != null
            ? (task['fecha'] as Timestamp).toDate()
            : null,
        semanasIniciales: List<int>.from(task['semanas'] ?? []),
        asignadosIniciales: List<String>.from(task['asignados'] ?? []),
        mesInicial: task['mes'] ?? DateTime.now().month,
        anoInicial: task['año'] ?? DateTime.now().year,
        userId: userId,
        onTaskUpdated: () => setState(() {}),
      ),
    );
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
    if (!_formKey.currentState!.validate()) return;

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
    if (!_formKey.currentState!.validate()) return;

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
      'fechaActualizacion': Timestamp.now(),
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
