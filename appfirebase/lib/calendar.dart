import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class CalendarioScreen extends StatefulWidget {
  @override
  _CalendarioScreenState createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

@override
void initState() {
  super.initState();
  initializeDateFormatting('es_ES', null).then((_) {
    setState(() {}); // Para recargar después de la inicialización
  });
  _selectedDay = _focusedDay;
  _loadTasksFromFirestore();
}

  /// Carga las tareas desde Firestore
  Future<void> _loadTasksFromFirestore() async {
    FirebaseFirestore.instance.collection('tareas').snapshots().listen((snapshot) {
      Map<DateTime, List<Map<String, dynamic>>> tempEvents = {};
      for (var doc in snapshot.docs) {
        var data = doc.data();
        DateTime taskDate = DateFormat('yyyy-MM-dd').parse(data['fecha']);
        tempEvents.putIfAbsent(taskDate, () => []).add(data);
      }
      setState(() {
        _events = tempEvents;
      });
    });
  }

  /// Obtiene las tareas para Aun día específico
  List<Map<String, dynamic>> _getTasksForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calendario")),
      body: Column(
        children: [
          _buildCalendar(),
          Expanded(child: _buildTaskList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskModal(context),
        child: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// Construye el calendario
 Widget _buildCalendar() {
  return Container(
    margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
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
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: CalendarFormat.month,
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
        formatButtonVisible: false,
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
      eventLoader: _getTasksForDay,
    ),
  );
}

  /// Construye la lista de tareas
  Widget _buildTaskList() {
  List<Map<String, dynamic>> tasks = _getTasksForDay(_selectedDay!);
  return tasks.isEmpty
      ? const Center(
          child: Text(
            "No hay tareas para este día",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        )
      : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            var task = tasks[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: ListTile(
                leading: Icon(
                  task['completado'] ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: task['completado'] ? Colors.teal : Colors.grey,
                ),
                title: Text(
                  task['nombre'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  task['descripcion'] ?? '',
                  style: TextStyle(color: Colors.black54),
                ),
                trailing: Checkbox(
                  value: task['completado'],
                  onChanged: (value) {
                    FirebaseFirestore.instance
                        .collection('tareas')
                        .doc(task['id'])
                        .update({'completado': value});
                  },
                ),
              ),
            );
          },
        );
}
  /// Muestra el modal para agregar una nueva tarea
  void _showAddTaskModal(BuildContext context) {
  TextEditingController nombreController = TextEditingController();
  TextEditingController descripcionController = TextEditingController();
  DateTime? selectedDate;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Añadir nueva tarea",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: "Nombre de la tarea *",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(
                labelText: "Descripción",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2022),
                  lastDate: DateTime(2030),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Seleccionar fecha",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (nombreController.text.isNotEmpty && selectedDate != null) {
                  FirebaseFirestore.instance.collection('tareas').add({
                    'nombre': nombreController.text,
                    'descripcion': descripcionController.text,
                    'fecha': DateFormat('yyyy-MM-dd').format(selectedDate!),
                    'completado': false,
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Añadir",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}
  /// Construye la barra de navegación inferior
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.teal,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lista'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Compra'),
      ],
    );
  }
}
