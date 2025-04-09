import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'lista_compra.dart';
import 'principal.dart';
import 'perfil.dart';
import 'tareas_screen.dart';
import 'package:collection/collection.dart';

class GastosScreen extends StatefulWidget {
  @override
  _GastosScreenState createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<String> _miembrosHogar = [];
  Map<String, String> _nombresMiembros = {};
  String? _hogarId;
  bool _loading = true;
  int _currentIndex = 2;
  late TabController _tabController;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = _auth.currentUser?.uid ?? '';
    _cargarDatosHogar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosHogar() async {
    try {
      final userId = _auth.currentUser?.uid ?? '';
      final hogarSnapshot = await _firestore
          .collection('hogar')
          .where('miembros', arrayContains: userId)
          .limit(1)
          .get();

      if (hogarSnapshot.docs.isNotEmpty) {
        setState(() {
          _miembrosHogar =
              List<String>.from(hogarSnapshot.docs.first['miembros']);
          _hogarId = hogarSnapshot.docs.first.id;
        });
        await _cargarNombresMiembros();
      }
    } catch (e) {
      print('Error cargando datos del hogar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _cargarNombresMiembros() async {
    try {
      if (_miembrosHogar.isEmpty) return;

      final usuariosSnapshot = await _firestore
          .collection('usuarios')
          .where(FieldPath.documentId, whereIn: _miembrosHogar)
          .get();

      final nombresTemp = <String, String>{};
      for (var doc in usuariosSnapshot.docs) {
        nombresTemp[doc.id] = doc['nombre'] ?? 'Usuario';
      }

      setState(() {
        _nombresMiembros = nombresTemp;
      });
    } catch (e) {
      print('Error cargando nombres de miembros: $e');
    }
  }

  void _mostrarModalAgregarGasto(BuildContext context) {
    final TextEditingController _tituloController = TextEditingController();
    final TextEditingController _montoController = TextEditingController();
    DateTime _fechaSeleccionada = DateTime.now();
    String? _pagadoPor;
    List<String> _debenPagar = [];
    double _montoPorPersona = 0.0;

    void _actualizarMontoPorPersona() {
      if (_montoController.text.isNotEmpty && _debenPagar.isNotEmpty) {
        final monto = double.tryParse(_montoController.text) ?? 0;
        setState(() {
          _montoPorPersona = monto / _debenPagar.length;
        });
      } else {
        setState(() {
          _montoPorPersona = 0.0;
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        "Nuevo Gasto",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    TextField(
                      controller: _tituloController,
                      decoration: InputDecoration(
                        labelText: 'Título',
                        labelStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.title, color: Colors.teal),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _montoController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) => _actualizarMontoPorPersona(),
                      decoration: InputDecoration(
                        labelText: 'Cantidad (€)',
                        labelStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.euro, color: Colors.teal),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: _fechaSeleccionada,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (fecha != null) {
                          setModalState(() => _fechaSeleccionada = fecha);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha',
                          labelStyle: TextStyle(color: Colors.teal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon:
                              Icon(Icons.calendar_today, color: Colors.teal),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.teal, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              DateFormat('d MMM y').format(_fechaSeleccionada),
                              style: TextStyle(color: Colors.black87),
                            ),
                            Spacer(),
                            Icon(Icons.arrow_drop_down, color: Colors.teal),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _pagadoPor,
                      decoration: InputDecoration(
                        labelText: 'Pagado por',
                        labelStyle: TextStyle(color: Colors.teal),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.person, color: Colors.teal),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _miembrosHogar.map((miembro) {
                        return DropdownMenuItem<String>(
                          value: miembro,
                          child: Text(_nombresMiembros[miembro] ?? 'Usuario'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() => _pagadoPor = value);
                      },
                      validator: (value) =>
                          value == null ? 'Selecciona quién pagó' : null,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Participantes en el gasto:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Column(
                      children: _miembrosHogar.map((miembro) {
                        return CheckboxListTile(
                          title: Text(_nombresMiembros[miembro] ?? 'Usuario'),
                          value: _debenPagar.contains(miembro),
                          onChanged: (selected) {
                            setModalState(() {
                              if (selected == true) {
                                _debenPagar.add(miembro);
                              } else {
                                _debenPagar.remove(miembro);
                              }
                              _actualizarMontoPorPersona();
                            });
                          },
                          secondary: CircleAvatar(
                            child: Text(
                              _nombresMiembros[miembro]?.substring(0, 1) ?? 'U',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.teal,
                          ),
                          controlAffinity: ListTileControlAffinity.trailing,
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    if (_debenPagar.isNotEmpty &&
                        _montoController.text.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total a dividir: ${_montoController.text}€',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Cada participante pagará: ${_montoPorPersona.toStringAsFixed(2)}€',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (_tituloController.text.isEmpty ||
                            _montoController.text.isEmpty ||
                            _pagadoPor == null ||
                            _debenPagar.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Completa todos los campos requeridos'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final monto =
                            double.tryParse(_montoController.text) ?? 0;
                        final montoPorPersona = monto / _debenPagar.length;

                        final nuevoGasto = {
                          'titulo': _tituloController.text.trim(),
                          'monto': monto,
                          'fecha': _fechaSeleccionada,
                          'pagadoPor': _pagadoPor,
                          'debenPagar': _debenPagar,
                          'montoPorPersona': montoPorPersona,
                          'fechaCreacion': FieldValue.serverTimestamp(),
                          'hogarId': _hogarId,
                          'pagado': false,
                        };

                        // Primero guardar el gasto
                        await _firestore.collection('gastos').add(nuevoGasto);

                        // Luego actualizar las deudas
                        await _actualizarDeudasDesdeGasto(nuevoGasto);

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Guardar Gasto",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    if (_hogarId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No perteneces a ningún hogar",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gastos',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.teal,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.teal,
                tabs: [
                  Tab(text: 'Gastos'),
                  Tab(text: 'Deudas'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGastosTab(),
                  _buildDeudasTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarModalAgregarGasto(context),
        backgroundColor: Colors.orange,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
Widget _buildGastosTab() {
  return StreamBuilder<QuerySnapshot>(
    stream: _firestore
        .collection('gastos')
        .where('hogarId', isEqualTo: _hogarId)
        .orderBy('fecha', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator(color: Colors.teal));
      }

      if (snapshot.hasError) {
        return Center(
          child: Text('Error al cargar los gastos',
              style: TextStyle(color: Colors.red)),
        );
      }

      final gastos = snapshot.data?.docs ?? [];
      
      // Calcular totales
      double totalGastos = 0;
      double misGastos = 0;
      
      for (final gasto in gastos) {
        final monto = gasto['monto'] as double;
        final debenPagar = (gasto['debenPagar'] as List).cast<String>();
        
        totalGastos += monto;
       
        // Si el usuario está entre los que deben pagar
        if (debenPagar.contains(_currentUserId)) {
          misGastos += monto / debenPagar.length; // Suma su parte proporcional
        }
      }

      if (gastos.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.money_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "No hay gastos registrados",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                "Presiona el botón + para agregar uno",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // Resumen de gastos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Mis gastos',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.teal,
                        ),
                      ),
                      Text(
                        '${misGastos.toStringAsFixed(2)}€',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Gastos totales',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        '${totalGastos.toStringAsFixed(2)}€',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de gastos
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: gastos.length,
              itemBuilder: (context, index) {
                final gasto = gastos[index];
                final fecha = (gasto['fecha'] as Timestamp).toDate();
                final pagadoPor = _nombresMiembros[gasto['pagadoPor']] ?? 'Usuario';
                final monto = gasto['monto'] as double;
                final fechaKey = DateFormat('d MMMM y', 'es_ES').format(fecha);

                if (index == 0 ||
                    DateFormat('d MMMM y', 'es_ES').format(
                            (gastos[index - 1]['fecha'] as Timestamp).toDate()) !=
                        fechaKey) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          fechaKey,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                      _buildGastoCard(gasto, pagadoPor, monto, fecha),
                    ],
                  );
                } else {
                  return _buildGastoCard(gasto, pagadoPor, monto, fecha);
                }
              },
            ),
          ),
        ],
      );
    },
  );
}

  Widget _buildDeudasTab() {
  if (_hogarId == null) {
    return Center(
      child: Text('No se ha cargado el ID del hogar'),
    );
  }

  return StreamBuilder<QuerySnapshot>(
    stream: _firestore
        .collection('deudas')
        .where('hogarId', isEqualTo: _hogarId)
        .where('pagado', isEqualTo: false)
        .orderBy('ultimaActualizacion', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator(color: Colors.teal));
      }

      if (snapshot.hasError) {
        print('Error en snapshot: ${snapshot.error}');
        return Center(
          child: Text('Error al cargar las deudas: ${snapshot.error}'),
        );
      }

      // Calcular balances para todos los miembros
      final balances = _calcularBalances(snapshot.data?.docs ?? []);

      // Obtener balance del usuario actual
      final miBalance = balances[_currentUserId] ?? 0.0;

      return Column(
        children: [
          // Summary Card del usuario actual (estilo original)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _buildListaDeudasCompleta(snapshot.data?.docs ?? []),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Tu balance',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${miBalance >= 0 ? 'Te deben' : 'Debes'} ${miBalance.abs().toStringAsFixed(2)}€',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: miBalance >= 0 ? Colors.green[800] : Colors.orange[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Lista de balances de todos los miembros (tarjetas coloreadas)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Balances del hogar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _miembrosHogar.length,
              itemBuilder: (context, index) {
                final miembroId = _miembrosHogar[index];
                final balance = balances[miembroId] ?? 0.0;
                final esYo = miembroId == _currentUserId;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: balance >= 0 ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: balance >= 0 ? (Colors.green[100] ?? Colors.green) : (Colors.orange[100] ?? Colors.orange),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: esYo 
                        ? Colors.teal[100] 
                        : (balance >= 0 ? Colors.green[100] : Colors.orange[100]),
                      child: Text(
                        _nombresMiembros[miembroId]?.substring(0, 1) ?? '?',
                        style: TextStyle(
                          color: esYo 
                            ? Colors.teal 
                            : (balance >= 0 ? Colors.green[800] : Colors.orange[800]),
                        ),
                      ),
                    ),
                    title: Text(
                      '${_nombresMiembros[miembroId] ?? 'Usuario'}${esYo ? ' (Tú)' : ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: Text(
                      '${balance >= 0 ? '+' : ''}${balance.toStringAsFixed(2)}€',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.green[800] : Colors.orange[800],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

// Función para calcular balances de todos los miembros
Map<String, double> _calcularBalances(List<QueryDocumentSnapshot> deudas) {
  final balances = <String, double>{};
  
  for (final deuda in deudas) {
    final deudor = deuda['deudor'] as String;
    final acreedor = deuda['acreedor'] as String;
    final monto = (deuda['monto'] as num).toDouble();
    
    balances[deudor] = (balances[deudor] ?? 0) - monto;
    balances[acreedor] = (balances[acreedor] ?? 0) + monto;
  }
  
  return balances;
}

// Función para construir la lista completa de deudas (para mostrar al hacer tap en el card)
Widget _buildListaDeudasCompleta(List<QueryDocumentSnapshot> deudas) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Todas las deudas'),
      backgroundColor: Colors.teal,
    ),
    body: ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: deudas.length,
      itemBuilder: (context, index) {
        final deuda = deudas[index];
        final deudorId = deuda['deudor'] as String? ?? '';
        final acreedorId = deuda['acreedor'] as String? ?? '';
        final monto = (deuda['monto'] as num?)?.toDouble() ?? 0.0;
        final esCompensada = deuda['esCompensada'] as bool? ?? false;

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_nombresMiembros[deudorId]} → ${_nombresMiembros[acreedorId]}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Deuda: ${monto.toStringAsFixed(2)}€',
                  style: TextStyle(fontSize: 16),
                ),
                if (esCompensada)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      '(Deuda compensada)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _marcarDeudaComoPagada(
                    deuda.reference,
                    deudorId,
                    acreedorId,
                    monto,
                  ),
                  child: Text(
                    'Marcar como pagado',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

 Future<void> _actualizarDeudasDesdeGasto(Map<String, dynamic> gasto) async {
  try {
    final pagadoPor = gasto['pagadoPor'] as String;
    final montoPorPersona = gasto['montoPorPersona'] as double;
    final debenPagar = (gasto['debenPagar'] as List).cast<String>();
    final hogarId = gasto['hogarId'] as String;

    // Obtener TODAS las deudas existentes no pagadas del hogar
    final todasDeudas = await _firestore
        .collection('deudas')
        .where('hogarId', isEqualTo: hogarId)
        .where('pagado', isEqualTo: false)
        .get();

    final batch = _firestore.batch();

    for (final deudor in debenPagar) {
      if (deudor == pagadoPor) continue; // No crear deuda consigo mismo

      // Buscar si ya existe una deuda entre estos usuarios en cualquier dirección
      final QueryDocumentSnapshot<Map<String, dynamic>>? deudaExistente = todasDeudas.docs.firstWhereOrNull(
        (doc) => 
          (doc['deudor'] == deudor && doc['acreedor'] == pagadoPor) ||
          (doc['deudor'] == pagadoPor && doc['acreedor'] == deudor),
      );

      if (deudaExistente != null) {
        // Caso 1: Deuda en la misma dirección (deudor → acreedor)
        if (deudaExistente['deudor'] == deudor && 
            deudaExistente['acreedor'] == pagadoPor) {
          // Sumar al monto existente
          batch.update(deudaExistente.reference, {
            'monto': FieldValue.increment(montoPorPersona),
            'ultimaActualizacion': FieldValue.serverTimestamp(),
          });
        } 
        // Caso 2: Deuda en dirección opuesta (acreedor → deudor)
        else if (deudaExistente['deudor'] == pagadoPor && 
                 deudaExistente['acreedor'] == deudor) {
          final deudaActual = deudaExistente['monto'] as double;
          
          // Compensar deudas
          if (deudaActual > montoPorPersona) {
            // Reducir la deuda existente
            batch.update(deudaExistente.reference, {
              'monto': deudaActual - montoPorPersona,
              'ultimaActualizacion': FieldValue.serverTimestamp(),
            });
          } else if (deudaActual < montoPorPersona) {
            // Eliminar la deuda existente y crear una nueva en dirección opuesta
            batch.delete(deudaExistente.reference);
            
            final nuevaDeudaRef = _firestore.collection('deudas').doc();
            batch.set(nuevaDeudaRef, {
              'deudor': deudor,
              'acreedor': pagadoPor,
              'monto': montoPorPersona - deudaActual,
              'hogarId': hogarId,
              'creadoEn': FieldValue.serverTimestamp(),
              'ultimaActualizacion': FieldValue.serverTimestamp(),
              'pagado': false,
              'esCompensada': true,
            });
          } else {
            // Deudas iguales, se cancelan
            batch.delete(deudaExistente.reference);
          }
        }
      } else {
        // No existe deuda previa, crear nueva
        final nuevaDeudaRef = _firestore.collection('deudas').doc();
        batch.set(nuevaDeudaRef, {
          'deudor': deudor,
          'acreedor': pagadoPor,
          'monto': montoPorPersona,
          'hogarId': hogarId,
          'creadoEn': FieldValue.serverTimestamp(),
          'ultimaActualizacion': FieldValue.serverTimestamp(),
          'pagado': false,
          'esCompensada': false,
        });
      }
    }

    await batch.commit();
    await _compensarDeudas(hogarId); // Recalcular compensaciones globales
  } catch (e) {
    print('Error al actualizar deudas: $e');
    rethrow;
  }
}

Future<void> _compensarDeudas(String hogarId) async {
  try {
    // Obtener todas las deudas del hogar
    final deudasSnapshot = await _firestore
        .collection('deudas')
        .where('hogarId', isEqualTo: hogarId)
        .where('pagado', isEqualTo: false)
        .get();

    // Calcular balances netos para cada usuario
    final balances = <String, double>{};
    for (final doc in deudasSnapshot.docs) {
      final deudor = doc['deudor'] as String;
      final acreedor = doc['acreedor'] as String;
      final monto = doc['monto'] as double;

      balances[deudor] = (balances[deudor] ?? 0) - monto;
      balances[acreedor] = (balances[acreedor] ?? 0) + monto;
    }

    // Separar en deudores y acreedores
    final deudores = balances.entries
        .where((e) => e.value < 0)
        .toList()
          ..sort((a, b) => a.value.compareTo(b.value)); // Ordenar de menor a mayor
    
    final acreedores = balances.entries
        .where((e) => e.value > 0)
        .toList()
          ..sort((a, b) => b.value.compareTo(a.value)); // Ordenar de mayor a menor

    final batch = _firestore.batch();
    
    // Primero: Eliminar todas las deudas existentes
    for (final deuda in deudasSnapshot.docs) {
      batch.delete(deuda.reference);
    }

    // Segundo: Crear nuevas deudas compensadas
    int i = 0, j = 0;
    while (i < deudores.length && j < acreedores.length) {
      final deudor = deudores[i];
      final acreedor = acreedores[j];
      final cantidad = min(-deudor.value, acreedor.value);

      if (cantidad <= 0.01) { // Ignorar diferencias mínimas
        i++;
        j++;
        continue;
      }

      // Crear nueva deuda compensada
      final nuevaDeudaRef = _firestore.collection('deudas').doc();
      batch.set(nuevaDeudaRef, {
        'deudor': deudor.key,
        'acreedor': acreedor.key,
        'monto': cantidad,
        'hogarId': hogarId,
        'creadoEn': FieldValue.serverTimestamp(),
        'ultimaActualizacion': FieldValue.serverTimestamp(),
        'pagado': false,
        'esCompensada': true,
      });

      // Actualizar balances
      deudores[i] = MapEntry(deudor.key, deudor.value + cantidad);
      acreedores[j] = MapEntry(acreedor.key, acreedor.value - cantidad);

      if (deudores[i].value.abs() < 0.01) i++;
      if (acreedores[j].value.abs() < 0.01) j++;
    }

    await batch.commit();
  } catch (e) {
    print('Error en compensación de deudas: $e');
    rethrow;
  }
}



   Future<void> _marcarDeudaComoPagada(
    DocumentReference deudaRef,
    String deudorId,
    String acreedorId,
    double monto,
  ) async {
    try {
      final batch = _firestore.batch();
      
      // 1. Marcar la deuda como pagada
      batch.update(deudaRef, {
        'pagado': true,
        'fechaPago': FieldValue.serverTimestamp(),
      });

      // 2. Registrar el pago
      final pagoRef = _firestore.collection('pagos').doc();
      batch.set(pagoRef, {
        'deudor': deudorId,
        'acreedor': acreedorId,
        'monto': monto,
        'fecha': FieldValue.serverTimestamp(),
        'hogarId': _hogarId,
        'esCompensada': false,
      });

      await batch.commit();

      // 3. Recalcular deudas después del pago
      if (_hogarId != null) {
        await _compensarDeudas(_hogarId!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deuda marcada como pagada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error en _marcarDeudaComoPagada: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al marcar como pagado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildGastoCard(
      DocumentSnapshot gasto, String pagadoPor, double monto, DateTime fecha) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarDetalleGasto(context, gasto),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      gasto['titulo'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                  Text(
                    '${monto.toStringAsFixed(2)}€',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(width: 4),
                  Text(
                    'Pagado por: $pagadoPor',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        color: Colors.teal,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          elevation: 0,
          selectedLabelStyle: TextStyle(fontSize: 10, height: 1.5),
          unselectedLabelStyle: TextStyle(fontSize: 10, height: 1.5),
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
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 28),
      ),
      label: label,
      activeIcon: Container(
        padding: EdgeInsets.all(6),
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
            pageBuilder: (_, __, ___) => TareasScreen(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ListaScreen(),
            transitionDuration: Duration.zero,
          ),
        );
        break;
    }
  }

  void _mostrarDetalleGasto(BuildContext context, DocumentSnapshot gasto) {
    final pagadoPor = _nombresMiembros[gasto['pagadoPor']] ?? 'Usuario';
    final monto = gasto['monto'] as double;
    final montoPorPersona = gasto['montoPorPersona'] as double;
    final debenPagar = (gasto['debenPagar'] as List).cast<String>();
    final fecha = (gasto['fecha'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(gasto['titulo'], style: TextStyle(color: Colors.teal)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleItem(
                icon: Icons.euro,
                label: 'Total:',
                value: '${monto.toStringAsFixed(2)}€',
              ),
              _buildDetalleItem(
                icon: Icons.person,
                label: 'Pagado por:',
                value: pagadoPor,
              ),
              _buildDetalleItem(
                icon: Icons.calendar_today,
                label: 'Fecha:',
                value: DateFormat('d MMM y').format(fecha),
              ),
              SizedBox(height: 16),
              Text(
                'Dividido entre:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              SizedBox(height: 8),
              Column(
                children: debenPagar.map((miembro) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(_nombresMiembros[miembro] ?? 'Usuario'),
                        Spacer(),
                        Text(
                          '${montoPorPersona.toStringAsFixed(2)}€',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
