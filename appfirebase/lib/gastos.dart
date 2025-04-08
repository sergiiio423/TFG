import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'lista_compra.dart';
import 'principal.dart';
import 'perfil.dart';
import 'tareas_screen.dart';

class GastosScreen extends StatefulWidget {
  @override
  _GastosScreenState createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<String> _miembrosHogar = [];
  Map<String, String> _nombresMiembros = {};
  String? _hogarId;
  bool _loading = true;
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    _cargarDatosHogar();
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

      setState(() {
        _nombresMiembros = {
          for (var doc in usuariosSnapshot.docs)
            doc.id: doc['nombre'] ?? 'Usuario'
        };
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

                        await _firestore.collection('gastos').add({
                          'titulo': _tituloController.text.trim(),
                          'monto': monto,
                          'fecha': _fechaSeleccionada,
                          'pagadoPor': _pagadoPor,
                          'debenPagar': _debenPagar,
                          'montoPorPersona': montoPorPersona,
                          'fechaCreacion': FieldValue.serverTimestamp(),
                          'hogarId': _hogarId,
                        });

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
            // Encabezado similar al de ListaScreen pero para Gastos
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search, size: 28),
                        onPressed: () {
                          // Implementar búsqueda de gastos si es necesario
                        },
                      ),
                      const SizedBox(width: 8),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Text(
                    "Tus gastos recientes",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.filter_list_rounded,
                      color: Colors.teal[700], size: 24),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('gastos')
                    .where('hogarId', isEqualTo: _hogarId)
                    .orderBy('fecha', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(color: Colors.teal));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error al cargar los gastos',
                          style: TextStyle(color: Colors.red)),
                    );
                  }

                  final gastos = snapshot.data?.docs ?? [];
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

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: gastos.length,
                    itemBuilder: (context, index) {
                      final gasto = gastos[index];
                      final fecha = (gasto['fecha'] as Timestamp).toDate();
                      final pagadoPor =
                          _nombresMiembros[gasto['pagadoPor']] ?? 'Usuario';
                      final monto = gasto['monto'] as double;
                      final fechaKey =
                          DateFormat('d MMMM y', 'es_ES').format(fecha);

                      if (index == 0 ||
                          DateFormat('d MMMM y', 'es_ES').format(
                                  (gastos[index - 1]['fecha'] as Timestamp)
                                      .toDate()) !=
                              fechaKey) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 16, bottom: 8),
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
                  );
                },
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

  Widget _buildListaGastos() {
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

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          physics: const BouncingScrollPhysics(),
          itemCount: gastos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final gasto = gastos[index];
            final fecha = (gasto['fecha'] as Timestamp).toDate();
            final pagadoPor = _nombresMiembros[gasto['pagadoPor']] ?? 'Usuario';
            final monto = gasto['monto'] as double;

            return _buildGastoCard(gasto, pagadoPor, monto, fecha);
          },
        );
      },
    );
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
