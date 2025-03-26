import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'lista_compra.dart';
import 'principal.dart';

class ProductosListaScreen extends StatelessWidget {
  final String listaId;
  final String nombreLista;

  const ProductosListaScreen({
    super.key,
    required this.listaId,
    required this.nombreLista,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          nombreLista,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () => _marcarTodosComoComprados(),
          ),
        ],
      ),
      body: _buildProductosLista(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarModalAgregarProducto(context),
        backgroundColor: Colors.teal,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductosLista() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('producto')
          .where('listaId', isEqualTo: listaId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.teal));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No hay productos en esta lista.",
              style: TextStyle(
                color: Colors.teal.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            var producto = snapshot.data!.docs[index];
            return _ProductoItem(
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

  void _agregarProducto(String nombre, String icono, String cantidad) {
    FirebaseFirestore.instance.collection('producto').add({
      'nombre': nombre,
      'icono': icono,
      'cantidad': int.parse(cantidad),
      'listaId': listaId,
      'comprado': false,  // Nuevo campo para indicar si el producto ha sido comprado
    });
  }

  void _cambiarCantidad(DocumentSnapshot producto, int cambio) {
    int nuevaCantidad = (producto['cantidad'] as int) + cambio;
    if (nuevaCantidad <= 0) {
      _eliminarProducto(producto.id);
    } else {
      FirebaseFirestore.instance
          .collection('producto')
          .doc(producto.id)
          .update({'cantidad': nuevaCantidad});
    }
  }

  void _eliminarProducto(String productoId) {
    FirebaseFirestore.instance.collection('producto').doc(productoId).delete();
  }

  void _marcarComoComprado(DocumentSnapshot producto) {
    bool comprado = producto['comprado'] ?? false;
    FirebaseFirestore.instance
        .collection('producto')
        .doc(producto.id)
        .update({'comprado': !comprado});
  }

  void _marcarTodosComoComprados() {
    FirebaseFirestore.instance
        .collection('producto')
        .where('listaId', isEqualTo: listaId)
        .get()
        .then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        FirebaseFirestore.instance
            .collection('producto')
            .doc(doc.id)
            .update({'comprado': true});
      }
    });
  }

  void _mostrarModalAgregarProducto(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    TextEditingController nombreController = TextEditingController();
    TextEditingController cantidadController = TextEditingController(text: "1");
    String selectedIcon = "📦";
    final List<String> emoticons = ["📦", "🍎", "🥑", "🍞", "🥛", "🍗", "🥕"];

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
                  const Text(
                    "Agregar Producto",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nombreController,
                    decoration: InputDecoration(
                      labelText: "Nombre del producto",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children: emoticons.map((emoji) {
                      return GestureDetector(
                        onTap: () => setState(() => selectedIcon = emoji),
                        child: Text(
                          emoji,
                          style: TextStyle(
                            fontSize: 28,
                            backgroundColor: selectedIcon == emoji ? Colors.teal.withOpacity(0.2) : Colors.transparent,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: cantidadController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Cantidad",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      _agregarProducto(
                        nombreController.text,
                        selectedIcon,
                        cantidadController.text,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text("Agregar"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductoItem extends StatelessWidget {
  final DocumentSnapshot producto;
  final Function(int) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onToggleComprado;

  const _ProductoItem({
    required this.producto,
    required this.onUpdate,
    required this.onDelete,
    required this.onToggleComprado,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(
        producto['icono'],
        style: const TextStyle(fontSize: 24),
      ),
      title: Text(producto['nombre']),
      subtitle: Text("Cantidad: ${producto['cantidad']}"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.red),
            onPressed: () => onUpdate(-1),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.green),
            onPressed: () => onUpdate(1),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.grey),
            onPressed: onDelete,
          ),
          IconButton(
            icon: Icon(
              producto['comprado'] ? Icons.check_circle : Icons.radio_button_unchecked,
              color: producto['comprado'] ? Colors.green : Colors.grey,
            ),
            onPressed: onToggleComprado,
          ),
        ],
      ),
    );
  }
}
