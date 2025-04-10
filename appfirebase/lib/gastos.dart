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

  void _mostrarModalAgregarGasto(BuildContext context,
      {DocumentSnapshot? gastoExistente}) {
    final TextEditingController _tituloController =
        TextEditingController(text: gastoExistente?['titulo'] ?? '');
    final TextEditingController _montoController =
        TextEditingController(text: gastoExistente?['monto']?.toString() ?? '');
    DateTime _fechaSeleccionada = gastoExistente != null
        ? (gastoExistente['fecha'] as Timestamp).toDate()
        : DateTime.now();
    String? _pagadoPor = gastoExistente?['pagadoPor'];
    List<String> _debenPagar = gastoExistente != null
        ? List<String>.from(gastoExistente['debenPagar'])
        : [];
    double _montoPorPersona = gastoExistente?['montoPorPersona'] ?? 0.0;

    // Variables para control de errores
    bool _tituloError = false;
    bool _montoError = false;
    bool _pagadoPorError = false;
    bool _debenPagarError = false;

    void _actualizarMontoPorPersona() {
      if (_montoController.text.isNotEmpty && _debenPagar.isNotEmpty) {
        final monto =
            double.tryParse(_montoController.text.replaceAll(',', '.')) ?? 0;
        setState(() {
          _montoPorPersona = monto / _debenPagar.length;
        });
      } else {
        setState(() {
          _montoPorPersona = 0.0;
        });
      }
    }

    void _validarCampos() {
      setState(() {
        _tituloError = _tituloController.text.isEmpty;
        _montoError = _montoController.text.isEmpty;
        _pagadoPorError = _pagadoPor == null;
        _debenPagarError = _debenPagar.isEmpty;
      });
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
                        gastoExistente != null ? "Editar Gasto" : "Nuevo Gasto",
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
                        labelStyle: TextStyle(
                            color: _tituloError ? Colors.red : Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _tituloError ? Colors.red : Colors.grey,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.title,
                            color: _tituloError ? Colors.red : Colors.teal),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _tituloError ? Colors.red : Colors.teal,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorText:
                            _tituloError ? 'Este campo es obligatorio' : null,
                        errorStyle: TextStyle(color: Colors.red),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _montoController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        setModalState(() {
                          _montoError = value.isEmpty;
                        });
                        _actualizarMontoPorPersona();
                      },
                      decoration: InputDecoration(
                        labelText: 'Cantidad (€)',
                        labelStyle: TextStyle(
                            color: _montoError ? Colors.red : Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _montoError ? Colors.red : Colors.grey,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.euro,
                            color: _montoError ? Colors.red : Colors.teal),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _montoError ? Colors.red : Colors.teal,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorText:
                            _montoError ? 'Este campo es obligatorio' : null,
                        errorStyle: TextStyle(color: Colors.red),
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
                        labelStyle: TextStyle(
                            color: _pagadoPorError ? Colors.red : Colors.teal),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _pagadoPorError ? Colors.red : Colors.grey,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.person,
                            color: _pagadoPorError ? Colors.red : Colors.teal),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _pagadoPorError ? Colors.red : Colors.teal,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorText:
                            _pagadoPorError ? 'Selecciona quién pagó' : null,
                        errorStyle: TextStyle(color: Colors.red),
                      ),
                      dropdownColor: Colors.white,
                      items: _miembrosHogar.map((miembro) {
                        return DropdownMenuItem<String>(
                          value: miembro,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_nombresMiembros[miembro] ?? 'Usuario'),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          _pagadoPor = value;
                          _pagadoPorError = value == null;
                        });
                      },
                      icon: Icon(Icons.arrow_drop_down, color: Colors.teal),
                      style: TextStyle(color: Colors.black),
                      isExpanded: true,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Participantes en el gasto:',
                      style: TextStyle(
                        fontSize: 16,
                        color: _debenPagarError ? Colors.red : Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_debenPagarError)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Selecciona al menos un participante',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    SizedBox(height: 8),
                    Column(
                      children: _miembrosHogar.map((miembro) {
                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          margin: EdgeInsets.only(bottom: 8),
                          child: CheckboxListTile(
                            title: Text(
                              _nombresMiembros[miembro] ?? 'Usuario',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            value: _debenPagar.contains(miembro),
                            onChanged: (selected) {
                              setModalState(() {
                                if (selected == true) {
                                  _debenPagar.add(miembro);
                                } else {
                                  _debenPagar.remove(miembro);
                                }
                                _debenPagarError = _debenPagar.isEmpty;
                                _actualizarMontoPorPersona();
                              });
                            },
                            secondary: CircleAvatar(
                              child: Text(
                                _nombresMiembros[miembro]?.substring(0, 1) ??
                                    'U',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.teal,
                            ),
                            controlAffinity: ListTileControlAffinity.trailing,
                          ),
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
                    Row(
                      children: [
                        if (gastoExistente != null)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                setModalState(() {
                                  _validarCampos();
                                });

                                if (_tituloError ||
                                    _montoError ||
                                    _pagadoPorError ||
                                    _debenPagarError) {
                                  return;
                                }

                                final monto = double.tryParse(_montoController
                                        .text
                                        .replaceAll(',', '.')) ??
                                    0;
                                final montoPorPersona =
                                    monto / _debenPagar.length;

                                await gastoExistente.reference.update({
                                  'titulo': _tituloController.text.trim(),
                                  'monto': monto,
                                  'fecha': _fechaSeleccionada,
                                  'pagadoPor': _pagadoPor,
                                  'debenPagar': _debenPagar,
                                  'montoPorPersona': montoPorPersona,
                                });

                                // Actualizar deudas
                                await _actualizarDeudasDesdeGasto({
                                  'titulo': _tituloController.text.trim(),
                                  'monto': monto,
                                  'fecha': _fechaSeleccionada,
                                  'pagadoPor': _pagadoPor,
                                  'debenPagar': _debenPagar,
                                  'montoPorPersona': montoPorPersona,
                                  'hogarId': _hogarId,
                                });

                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Actualizar",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (gastoExistente != null) SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              setModalState(() {
                                _validarCampos();
                              });

                              if (_tituloError ||
                                  _montoError ||
                                  _pagadoPorError ||
                                  _debenPagarError) {
                                return;
                              }

                              final monto = double.tryParse(_montoController
                                      .text
                                      .replaceAll(',', '.')) ??
                                  0;
                              final montoPorPersona =
                                  monto / _debenPagar.length;

                              if (gastoExistente != null) {
                                await _eliminarGasto(gastoExistente);
                              } else {
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

                                await _firestore
                                    .collection('gastos')
                                    .add(nuevoGasto);
                                await _actualizarDeudasDesdeGasto(nuevoGasto);
                              }

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gastoExistente != null
                                  ? Colors.red
                                  : Colors.orange,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              gastoExistente != null ? "Eliminar" : "Guardar",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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
              padding: const EdgeInsets.symmetric(
                  vertical: 8), // Reducimos el padding vertical
              child: Center(
                // Centramos el TabBar
                child: Container(
                  width: MediaQuery.of(context).size.width *
                      0.65, // 80% del ancho de pantalla
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.teal,
                    unselectedLabelColor: Colors.grey[600],
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(
                        child: Text(
                          'Gastos',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Deudas',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
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
          final pagadoPor = gasto['pagadoPor'] as String;
          final debenPagar = (gasto['debenPagar'] as List).cast<String>();

          totalGastos += monto;

          // Si el usuario pagó el gasto
          if (pagadoPor == _currentUserId) {
            misGastos += monto; // Suma el monto completo
          }
          // Si el usuario está entre los que deben pagar
          else if (debenPagar.contains(_currentUserId)) {
            misGastos +=
                monto / debenPagar.length; // Suma su parte proporcional
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
            // Resumen de gastos (sin card)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 60.0, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mis gastos',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${misGastos.toStringAsFixed(2)}€',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Gastos totales',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${totalGastos.toStringAsFixed(2)}€',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Divider(
                    // Línea separadora
                    height: 1,
                    thickness: 1,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),

            // Lista de gastos
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: 80),
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
                          padding: const EdgeInsets.only(
                              left: 24, top: 16, bottom: 8),
                          child: Text(
                            fechaKey,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        _buildListaDeudasCompleta(snapshot.data?.docs ?? []),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                padding: EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Balance principal
                        Text(
                          'Balance Total',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${miBalance.toStringAsFixed(2)}€',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: miBalance >= 0
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                        SizedBox(height: 8),

                        // Subtítulo según el balance
                        Text(
                          miBalance >= 0
                              ? 'Mira cómo te deben devolver dinero'
                              : 'Mira cómo puedes devolver el dinero',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    // Flecha indicadora a la derecha
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                          color: Colors.grey[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Lista de balances de todos los miembros
            SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Balances del hogar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _miembrosHogar.length,
                itemBuilder: (context, index) {
                  final miembroId = _miembrosHogar[index];
                  final balance = balances[miembroId] ?? 0.0;
                  final esYo = miembroId == _currentUserId;

                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color:
                          balance >= 0 ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: balance >= 0
                            ? Colors.green[100]!
                            : Colors.orange[100]!,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (balance >= 0
                            ? Colors.green[100]
                            : Colors.orange[100]),
                        child: Text(
                          _nombresMiembros[miembroId]?.substring(0, 1) ?? '?',
                          style: TextStyle(
                            color: (balance >= 0
                                ? Colors.green[800]
                                : Colors.orange[800]),
                          ),
                        ),
                      ),
                      title: Text(
                        '${_nombresMiembros[miembroId] ?? 'Usuario'}${esYo ? ' (Tú)' : ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          fontSize: 17,
                        ),
                      ),
                      trailing: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: balance >= 0
                              ? Colors.green[50]
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${balance > 0 ? '+' : ''}${balance.toStringAsFixed(2)}€',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: balance >= 0
                                ? Colors.green[800]
                                : Colors.orange[800],
                          ),
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

  Widget _buildGastoCard(
      DocumentSnapshot gasto, String pagadoPor, double monto, DateTime fecha) {
    final esPagador = gasto['pagadoPor'] == _currentUserId;
    final participaEnGasto =
        (gasto['debenPagar'] as List).contains(_currentUserId);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                        fontSize: 18,
                        color: Colors.black.withOpacity(0.80),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${monto.toStringAsFixed(2)}€',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      SizedBox(width: 8),
                      PopupMenuButton<String>(
                        color: Colors.white,
                        icon: Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _mostrarModalAgregarGasto(context,
                                gastoExistente: gasto);
                          } else if (value == 'delete') {
                            _mostrarConfirmacionEliminar(context, gasto);
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.teal),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Eliminar'),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Pagado por ',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    pagadoPor.isNotEmpty ? pagadoPor : "Usuario",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                    ),
                  ),
                  Spacer(),
                  if (esPagador || participaEnGasto)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: esPagador ? Colors.teal[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        esPagador ? 'Pagaste' : 'Participas',
                        style: TextStyle(
                          fontSize: 12,
                          color: esPagador ? Colors.teal : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
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

  void _mostrarConfirmacionEliminar(
      BuildContext context, DocumentSnapshot gasto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar este gasto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _eliminarGasto(gasto);
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarGasto(DocumentSnapshot gasto) async {
    try {
      // Primero actualizar las deudas (revertir el efecto de este gasto)
      await _revertirDeudasDesdeGasto(gasto);

      // Luego eliminar el gasto
      await gasto.reference.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gasto eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error al eliminar gasto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar el gasto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _revertirDeudasDesdeGasto(DocumentSnapshot gasto) async {
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
        if (deudor == pagadoPor) continue;

        // Buscar si ya existe una deuda entre estos usuarios en cualquier dirección
        final QueryDocumentSnapshot<Map<String, dynamic>>? deudaExistente =
            todasDeudas.docs.firstWhereOrNull(
          (doc) =>
              (doc['deudor'] == deudor && doc['acreedor'] == pagadoPor) ||
              (doc['deudor'] == pagadoPor && doc['acreedor'] == deudor),
        );

        if (deudaExistente != null) {
          // Caso 1: Deuda en la misma dirección (deudor → acreedor)
          if (deudaExistente['deudor'] == deudor &&
              deudaExistente['acreedor'] == pagadoPor) {
            // Restar el monto existente
            batch.update(deudaExistente.reference, {
              'monto': FieldValue.increment(-montoPorPersona),
              'ultimaActualizacion': FieldValue.serverTimestamp(),
            });
          }
          // Caso 2: Deuda en dirección opuesta (acreedor → deudor)
          else if (deudaExistente['deudor'] == pagadoPor &&
              deudaExistente['acreedor'] == deudor) {
            final deudaActual = deudaExistente['monto'] as double;

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
          // No existe deuda previa, crear una nueva en dirección opuesta
          final nuevaDeudaRef = _firestore.collection('deudas').doc();
          batch.set(nuevaDeudaRef, {
            'deudor': pagadoPor,
            'acreedor': deudor,
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
      print('Error al revertir deudas: $e');
      rethrow;
    }
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

  Widget _buildListaDeudasCompleta(List<QueryDocumentSnapshot> deudas) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Todas las deudas',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.grey[50],
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 32),
          itemCount: deudas.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final deuda = deudas[index];
            final deudorId = deuda['deudor'] as String? ?? '';
            final acreedorId = deuda['acreedor'] as String? ?? '';
            final monto = (deuda['monto'] as num?)?.toDouble() ?? 0.0;
            final esCompensada = deuda['esCompensada'] as bool? ?? false;

            // Verificar si la deuda involucra al usuario actual
            final involucraAlUsuario =
                deudorId == _currentUserId || acreedorId == _currentUserId;
            final esPositiva = acreedorId == _currentUserId;

            return Material(
              borderRadius: BorderRadius.circular(12),
              elevation: 1,
              color: Colors.white,
              child: Opacity(
                opacity: involucraAlUsuario ? 1.0 : 0.6,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con icono y dirección de la deuda
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: involucraAlUsuario
                                  ? (esPositiva
                                      ? Colors.green[50]
                                      : Colors.orange[50])
                                  : Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              esPositiva
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: involucraAlUsuario
                                  ? (esPositiva
                                      ? Colors.green[700]
                                      : Colors.orange[700])
                                  : Colors.grey[600],
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  involucraAlUsuario
                                      ? (esPositiva ? 'TE DEBEN' : 'DEBES')
                                      : 'DEUDA EXTERNA',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: involucraAlUsuario
                                        ? Colors.grey[600]
                                        : Colors.grey[500],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${_nombresMiembros[deudorId] ?? 'Usuario'} → ${_nombresMiembros[acreedorId] ?? 'Usuario'}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: involucraAlUsuario
                                        ? Colors.grey[800]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Detalle del monto
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Monto:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${monto.toStringAsFixed(2)}€',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: involucraAlUsuario
                                    ? (esPositiva
                                        ? Colors.green[700]
                                        : Colors.orange[700])
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (esCompensada) ...[
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.merge, size: 16, color: Colors.teal),
                            SizedBox(width: 4),
                            Text(
                              'Deuda compensada',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.teal,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (involucraAlUsuario) ...[
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: esPositiva
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => _marcarDeudaComoPagada(
                              deuda.reference,
                              deudorId,
                              acreedorId,
                              monto,
                            ),
                            child: Text(
                              esPositiva
                                  ? 'Marcar como cobrado'
                                  : 'Marcar como pagado',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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
        if (deudor == pagadoPor) continue;

        // Buscar si ya existe una deuda entre estos usuarios
        final QueryDocumentSnapshot<Map<String, dynamic>>? deudaExistente =
            todasDeudas.docs.firstWhereOrNull(
          (doc) =>
              (doc['deudor'] == deudor && doc['acreedor'] == pagadoPor) ||
              (doc['deudor'] == pagadoPor && doc['acreedor'] == deudor),
        );

        if (deudaExistente != null) {
          // Caso 1: Deuda en la misma dirección
          if (deudaExistente['deudor'] == deudor &&
              deudaExistente['acreedor'] == pagadoPor) {
            batch.update(deudaExistente.reference, {
              'monto': FieldValue.increment(montoPorPersona),
              'ultimaActualizacion': FieldValue.serverTimestamp(),
            });
          }
          // Caso 2: Deuda en dirección opuesta
          else if (deudaExistente['deudor'] == pagadoPor &&
              deudaExistente['acreedor'] == deudor) {
            final deudaActual = deudaExistente['monto'] as double;

            if (deudaActual > montoPorPersona) {
              batch.update(deudaExistente.reference, {
                'monto': deudaActual - montoPorPersona,
                'ultimaActualizacion': FieldValue.serverTimestamp(),
              });
            } else if (deudaActual < montoPorPersona) {
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
      await _compensarDeudas(hogarId);
    } catch (e) {
      print('Error al actualizar deudas: $e');
      rethrow;
    }
  }

  Future<void> _compensarDeudas(String hogarId) async {
    try {
      final deudasSnapshot = await _firestore
          .collection('deudas')
          .where('hogarId', isEqualTo: hogarId)
          .where('pagado', isEqualTo: false)
          .get();

      final balances = <String, double>{};
      for (final doc in deudasSnapshot.docs) {
        final deudor = doc['deudor'] as String;
        final acreedor = doc['acreedor'] as String;
        final monto = doc['monto'] as double;

        balances[deudor] = (balances[deudor] ?? 0) - monto;
        balances[acreedor] = (balances[acreedor] ?? 0) + monto;
      }

      final deudores = balances.entries.where((e) => e.value < 0).toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final acreedores = balances.entries.where((e) => e.value > 0).toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final batch = _firestore.batch();

      for (final deuda in deudasSnapshot.docs) {
        batch.delete(deuda.reference);
      }

      int i = 0, j = 0;
      while (i < deudores.length && j < acreedores.length) {
        final deudor = deudores[i];
        final acreedor = acreedores[j];
        final cantidad = min(-deudor.value, acreedor.value);

        if (cantidad <= 0.01) {
          i++;
          j++;
          continue;
        }

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

      batch.update(deudaRef, {
        'pagado': true,
        'fechaPago': FieldValue.serverTimestamp(),
      });

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
  final esPagador = gasto['pagadoPor'] == _currentUserId;

  showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header fijo
            Container(
              padding: EdgeInsets.fromLTRB(24, 16, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detalle del gasto',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Contenido desplazable
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tarjeta de resumen
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gasto['titulo'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[800],
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: esPagador 
                                      ? Colors.teal.withOpacity(0.1) 
                                      : Colors.orange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  esPagador ? Icons.payment : Icons.people,
                                  size: 18,
                                  color: esPagador ? Colors.teal : Colors.orange,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                esPagador ? 'Pagaste este gasto' : 'Participas en este gasto',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Sección de detalles
                    Text(
                      'Detalles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[800],
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Detalles en tarjetas
                    _buildDetailCard(
                      icon: Icons.euro,
                      title: 'Monto total',
                      value: '${monto.toStringAsFixed(2)}€',
                      color: Colors.teal,
                    ),
                    
                    SizedBox(height: 8),
                    
                    _buildDetailCard(
                      icon: Icons.person,
                      title: 'Pagado por',
                      value: pagadoPor,
                      color: Colors.orange,
                    ),
                    
                    SizedBox(height: 8),
                    
                    _buildDetailCard(
                      icon: Icons.calendar_today,
                      title: 'Fecha',
                      value: DateFormat('d MMM y').format(fecha),
                      color: Colors.purple,
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Participantes
                    Text(
                      'Participantes (${debenPagar.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[800],
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    ...debenPagar.map((miembro) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.withOpacity(0.1),
                            child: Text(
                              _nombresMiembros[miembro]?.substring(0, 1) ?? '?',
                              style: TextStyle(color: Colors.teal),
                            ),
                          ),
                          title: Text(
                            _nombresMiembros[miembro] ?? 'Usuario',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: Text(
                            '${montoPorPersona.toStringAsFixed(2)}€',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[700],
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            
            // Footer fijo con botones
            Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.teal),
                      ),
                      child: Text(
                        'Cerrar',
                        style: TextStyle(color: Colors.teal),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _mostrarModalAgregarGasto(context, gastoExistente: gasto);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Editar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
