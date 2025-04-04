import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'lista_compra.dart';
import 'principal.dart';
import 'tareas_screen.dart';

class ProductosListaScreen extends StatefulWidget {
  final String listaId;
  final String nombreLista;

  const ProductosListaScreen({
    super.key,
    required this.listaId,
    required this.nombreLista,
  });

  @override
  State<ProductosListaScreen> createState() => _ProductosListaScreenState();
}

class _ProductosListaScreenState extends State<ProductosListaScreen> {
  final Map<String, GlobalKey<_ProductoItemState>> _productKeys = {};
  int _currentIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.nombreLista,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist_rounded),
            onPressed: _marcarTodosComoComprados,
            tooltip: 'Marcar todos como comprados',
          ),
        ],
      ),
      body: _buildProductosLista(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarModalAgregarProducto(context),
        backgroundColor: Colors.orange,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildProductosLista() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('producto')
          .where('listaId', isEqualTo: widget.listaId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_basket_outlined, 
                    size: 64, color: Colors.teal.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  "No hay productos en esta lista",
                  style: TextStyle(
                    color: Colors.teal[700],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Presiona el botón + para agregar uno",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final productos = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aComprado = a['comprado'] ?? false;
            final bComprado = b['comprado'] ?? false;
            return aComprado ? 1 : -1;
          });

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: productos.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            var producto = productos[index];
            final key = GlobalKey<_ProductoItemState>();
            _productKeys[producto.id] = key;

            return _ProductoItem(
              key: key,
              producto: producto,
              onUpdate: (cambio) => _cambiarCantidad(producto, cambio),
              onDelete: () => _eliminarProducto(producto.id),
              onToggleComprado: () => _marcarComoComprado(producto),
            );
          },
        );
      },
    );
  }

  Future<void> _cambiarCantidad(DocumentSnapshot producto, int cambio) async {
    final int cantidadActual = producto['cantidad'] ?? 1;
    final int nuevaCantidad = cantidadActual + cambio;

    if (nuevaCantidad > 0) {
      await FirebaseFirestore.instance
          .collection('producto')
          .doc(producto.id)
          .update({'cantidad': nuevaCantidad});
    }
  }

  Future<void> _agregarProducto(String nombre, String icono, String cantidad) async {
    await FirebaseFirestore.instance.collection('producto').add({
      'nombre': nombre,
      'icono': icono,
      'cantidad': int.tryParse(cantidad) ?? 1,
      'comprado': false,
      'fechaCreacion': FieldValue.serverTimestamp(),
      'listaId': widget.listaId,
    });
  }

  Future<void> _marcarComoComprado(DocumentSnapshot producto) async {
    final bool comprado = producto['comprado'] ?? false;
    final nuevoEstado = !comprado;
    
    await FirebaseFirestore.instance
        .collection('producto')
        .doc(producto.id)
        .update({
          'comprado': nuevoEstado,
          'fechaComprado': nuevoEstado ? FieldValue.serverTimestamp() : null,
        });

    if (_productKeys.containsKey(producto.id)) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _productKeys[producto.id]?.currentState?.updateCompradoState(nuevoEstado);
      });
    }
  }

  Future<void> _eliminarProducto(String productoId) async {
    await FirebaseFirestore.instance
        .collection('producto')
        .doc(productoId)
        .delete();
  }

  Future<void> _marcarTodosComoComprados() async {
    final productosSnapshot = await FirebaseFirestore.instance
        .collection('producto')
        .where('listaId', isEqualTo: widget.listaId)
        .get();

    for (var producto in productosSnapshot.docs) {
      await FirebaseFirestore.instance
          .collection('producto')
          .doc(producto.id)
          .update({'comprado': true, 'fechaComprado': FieldValue.serverTimestamp()});
    }
  }

  void _mostrarModalAgregarProducto(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final cantidadController = TextEditingController(text: "1");
    String selectedIcon = " 🍽️ ";
    final List<String> emoticons = [" 🍽️ ", "🥩", "🐟", "🍞", "🍎", "🥚", "🥬","🥔","🫘","🍚","🍪"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Agregar Producto",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: "Nombre del producto",
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Selecciona un icono:",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: emoticons.map((emoji) {
                      return ChoiceChip(
                        label: Text(emoji, style: const TextStyle(fontSize: 24)),
                        selected: selectedIcon == emoji,
                        selectedColor: Colors.orange.withOpacity(0.2),
                        backgroundColor: Colors.grey[200],
                        onSelected: (selected) {
                          setState(() => selectedIcon = emoji);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: cantidadController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Cantidad",
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nombreController.text.isNotEmpty) {
                          _agregarProducto(
                            nombreController.text,
                            selectedIcon,
                            cantidadController.text,
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "AGREGAR PRODUCTO",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
            spreadRadius: 2,
          ),
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

class _ProductoItem extends StatefulWidget {
  final DocumentSnapshot producto;
  final Function(int) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onToggleComprado;

  const _ProductoItem({
    required Key key,
    required this.producto,
    required this.onUpdate,
    required this.onDelete,
    required this.onToggleComprado,
  }) : super(key: key);

  @override
  _ProductoItemState createState() => _ProductoItemState();
}

class _ProductoItemState extends State<_ProductoItem> {
  late bool _isComprado;

  @override
  void initState() {
    super.initState();
    _isComprado = widget.producto['comprado'] ?? false;
  }

  void updateCompradoState(bool comprado) {
    setState(() {
      _isComprado = comprado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.producto['icono'],
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          widget.producto['nombre'],
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: _isComprado ? TextDecoration.lineThrough : null,
            color: _isComprado ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Text(
          "Cantidad: ${widget.producto['cantidad']}",
          style: TextStyle(
            decoration: _isComprado ? TextDecoration.lineThrough : null,
            color: _isComprado ? Colors.grey : Colors.black54,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isComprado) ...[
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                color: Colors.red[400],
                onPressed: () => widget.onUpdate(-1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                color: Colors.teal[400],
                onPressed: () => widget.onUpdate(1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              icon: Icon(
                _isComprado ? Icons.check_circle : Icons.radio_button_unchecked,
                color: _isComprado ? Colors.teal : Colors.grey,
              ),
              onPressed: () {
                widget.onToggleComprado();
              },
            ),
            if (!_isComprado)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[500]),
                onSelected: (value) {
                  widget.onDelete();
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: const [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar producto'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

}

  