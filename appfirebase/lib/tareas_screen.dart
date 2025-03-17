import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
    final firstDay = DateTime(fecha.year, fecha.month, 1);
    return ((fecha.difference(firstDay).inDays + firstDay.weekday) / 7).ceil();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: _buildAppBar(),
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlanificacionSemanal(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              "Tareas Semanales",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          _buildListaTareas(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              "Tareas de Hoy",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
          _buildListaTareasHoy(),
        ],
      ),
    ),
    floatingActionButton: _buildFloatingActionButton(),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    bottomNavigationBar: _buildBottomNavBar(),
  );
}

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        "Mis tareas",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Icon(Icons.person_outline, color: Colors.black54),
        ),
      ],
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
      onTap: () => setState(() => _fechaSeleccionada = fecha),
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

Widget _buildListaTareas() {
  final semanaActual = _obtenerSemanaMes(_fechaSeleccionada);
  return StreamBuilder<QuerySnapshot>(
    stream: _firestore
        .collection('tareas')
        .where('mes', isEqualTo: _fechaSeleccionada.month)
        .where('año', isEqualTo: _fechaSeleccionada.year)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const LinearProgressIndicator();
      
      final tasks = snapshot.data!.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final esCreador = data['usuarioId'] == userId;
        final estaAsignado = (data['asignados'] as List?)?.contains(userId) ?? false;
        
        if (!esCreador && !estaAsignado) return false;

        if (data['tipo'] == 'puntual') {
          final fecha = (data['fecha'] as Timestamp).toDate();
          return _obtenerSemanaMes(fecha) == semanaActual;
        }
        return data['tipo'] == 'semanal' && (data['semanas'] as List).contains(semanaActual);
      }).toList();

      return Container(
        height: 200, // Ajusta el alto según tus necesidades
        child: ListView(
          children: tasks.map((doc) => _buildTareaCard(doc)).toList(),
        ),
      );
    },
  );
}
  Widget _buildListaTareasHoy() {
    final hoy = DateTime.now();
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
            return DateUtils.isSameDay(fecha, hoy);
          }
          return data['tipo'] == 'semanal' && 
                 (data['semanas'] as List).contains(_obtenerSemanaMes(hoy));
        }).toList();

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
      child: Container(
        decoration: BoxDecoration(
          color: completada ? Colors.teal : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, blurRadius: 5, offset: const Offset(2, 2))
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
              Text(data['descripcion'],
                  style: TextStyle(color: completada ? Colors.white70 : Colors.black54)),
              if (data['asignados'] != null)
                Wrap(
                  spacing: 4,
                  children: (data['asignados'] as List)
                      .map<Widget>((uid) => FutureBuilder<DocumentSnapshot>(
                            future: _firestore.collection('usuarios').doc(uid).get(),
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
          trailing: const Icon(Icons.more_horiz, color: Colors.black54),
        ),
      ),
    );
  }

  Future<void> _actualizarEstadoTarea(String taskId, bool completada) async {
    await _firestore.collection('tareas').doc(taskId).update({'completada': completada});
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
      isScrollControlled: true,
      builder: (context) => CrearTareaForm(
        userId: userId,
        onTaskCreated: () => setState(() {}),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: Colors.teal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: const Icon(Icons.home, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.list, color: Colors.white), onPressed: () {}),
          const SizedBox(width: 40),
          IconButton(icon: const Icon(Icons.account_balance_wallet, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.shopping_cart, color: Colors.white), onPressed: () {}),
        ],
      ),
    );
  }
}

class CrearTareaForm extends StatefulWidget {
  final String userId;
  final VoidCallback onTaskCreated;

  const CrearTareaForm({super.key, required this.userId, required this.onTaskCreated});

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

  @override
  void initState() {
    super.initState();
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
        _miembrosHogar = List<String>.from(hogarSnapshot.docs.first['miembros']);
      });
    }
  }

  Future<void> _seleccionarFecha() async {
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

    final taskData = {
      'titulo': _tituloController.text,
      'descripcion': _descripcionController.text,
      'completada': false,
      'usuarioId': widget.userId,
      'tipo': _esSemanal ? 'semanal' : 'puntual',
      'fechaCreacion': Timestamp.now(),
      'mes': DateTime.now().month,
      'año': DateTime.now().year,
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
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nueva Tarea',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) => value!.isEmpty ? 'Ingrese un título' : null,
            ),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Tipo de tarea:'),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Puntual'),
                  selected: !_esSemanal,
                  onSelected: (val) => setState(() => _esSemanal = !val),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Semanal'),
                  selected: _esSemanal,
                  onSelected: (val) => setState(() => _esSemanal = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (!_esSemanal)
              InkWell(
                onTap: _seleccionarFecha,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Fecha'),
                  child: Row(
                    children: [
                      Text(
                        _fechaSeleccionada != null
                            ? DateFormat('dd/MM/yyyy').format(_fechaSeleccionada!)
                            : 'Seleccionar fecha',
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
            if (_esSemanal) ...[
              const Text('Semanas del mes:'),
              Wrap(
                spacing: 8,
                children: List.generate(5, (index) {
                  final semana = index + 1;
                  return FilterChip(
                    label: Text('Semana $semana'),
                    selected: _semanasSeleccionadas.contains(semana),
                    onSelected: (val) => _toggleSemana(semana),
                  );
                }),
              ),
              const SizedBox(height: 10),
              const Text('Asignar a miembros:'),
              Wrap(
                spacing: 8,
                children: _miembrosHogar.map((miembro) {
                  return FilterChip(
                    label: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('usuarios').doc(miembro).get(),
                      builder: (context, snapshot) {
                        final nombre = snapshot.hasData ? snapshot.data!['nombre'] ?? 'Usuario' : '...';
                        return Text(nombre);
                      },
                    ),
                    selected: _miembrosSeleccionados.contains(miembro),
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
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Crear Tarea', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}