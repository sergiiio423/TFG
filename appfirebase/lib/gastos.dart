import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GastosScreen extends StatefulWidget {
  @override
  _GastosScreenState createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _mostrarModalAgregarGasto(BuildContext context) {
    TextEditingController descripcionController = TextEditingController();
    TextEditingController montoController = TextEditingController();
    DateTime fechaSeleccionada = DateTime.now();
    String? usuarioSeleccionado;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Añadir Gasto",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: descripcionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: montoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monto (€)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: fechaSeleccionada,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        fechaSeleccionada = picked;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Seleccionar fecha: ${DateFormat('d MMM y').format(fechaSeleccionada)}",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: usuarioSeleccionado,
                  hint: Text("Pagado por"),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: _auth.currentUser!.uid,
                      child: Text("Yo"),
                    ),
                    // Aquí puedes cargar otros miembros del hogar si los tienes
                  ],
                  onChanged: (value) {
                    setState(() {
                      usuarioSeleccionado = value;
                    });
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (descripcionController.text.isNotEmpty &&
                        montoController.text.isNotEmpty &&
                        usuarioSeleccionado != null) {
                      await _firestore.collection('gastos').add({
                        'descripcion': descripcionController.text.trim(),
                        'monto': double.parse(montoController.text),
                        'fecha': fechaSeleccionada,
                        'pagadoPor': usuarioSeleccionado,
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Añadir Gasto",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Gastos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
      ),
      body: StreamBuilder(
        stream: _firestore.collection('gastos').orderBy('fecha', descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: Colors.teal));
          final gastos = snapshot.data!.docs;
          Map<String, List<DocumentSnapshot>> gastosAgrupados = {};

          for (var gasto in gastos) {
            DateTime fecha = (gasto['fecha'] as Timestamp).toDate();
            String fechaKey = DateFormat('d MMM y').format(fecha);
            if (!gastosAgrupados.containsKey(fechaKey)) {
              gastosAgrupados[fechaKey] = [];
            }
            gastosAgrupados[fechaKey]!.add(gasto);
          }

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: gastosAgrupados.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      entry.key,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal),
                    ),
                  ),
                  ...entry.value.map((gasto) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          gasto['descripcion'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Pagado por: ${gasto['pagadoPor']}", style: TextStyle(color: Colors.grey)),
                        trailing: Text(
                          "${gasto['monto']}€",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ),
                    );
                  }).toList()
                ],
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarModalAgregarGasto(context),
        child: Icon(Icons.add, size: 30),
        backgroundColor: Colors.orange,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}