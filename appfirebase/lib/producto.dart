import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'lista_compra.dart';
import 'principal.dart';

class ProductosListaScreen extends StatelessWidget {
  final String listaId;
  final String nombreLista;

  const ProductosListaScreen({super.key, required this.listaId, required this.nombreLista});

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
      ),
      body: _buildProductosLista(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarModalAgregarProducto(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
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
        BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart), label: 'Compra'),
      ],
      onTap: (index) => _onBottomNavTapped(context, index),
    );
  }

  void _onBottomNavTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const HomePage()));
        break;
      case 1:
        break;
      case 2:
        // Navegar a WalletScreen
        break;
      case 3:
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ListaScreen()));
        break;
    }
  }

  Widget _buildProductosLista() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('producto')
          .where('listaId', isEqualTo: listaId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("No hay productos en esta lista.",
                  style: TextStyle(color: Colors.teal)));
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
            );
          },
        );
      },
    );
  }

  void _mostrarModalAgregarProducto(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    TextEditingController nombreController = TextEditingController();
    TextEditingController cantidadController = TextEditingController(text: "1");
    String selectedIcon = "📦";
    final List<String> emoticons = ["📦", "🍎", "🥑", "🍞", "🥛"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Agregar Producto",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal)),
                  const SizedBox(height: 15),
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: "Nombre del producto",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_basket, color: Colors.teal),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: emoticons.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () => setState(() => selectedIcon = emoticons[index]),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selectedIcon == emoticons[index]
                                ? Colors.teal.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            emoticons[index],
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: cantidadController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Cantidad",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers, color: Colors.teal),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _agregarProducto(
                          nombreController.text, selectedIcon, cantidadController.text);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text("AGREGAR",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
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
    });
  }

  void _cambiarCantidad(DocumentSnapshot producto, int cambio) {
    int nuevaCantidad = producto['cantidad'] + cambio;
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
}

class _ProductoItem extends StatelessWidget {
  final DocumentSnapshot producto;
  final Function(int) onUpdate;
  final VoidCallback onDelete;

  const _ProductoItem({
    required this.producto,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(producto['icono'], style: const TextStyle(fontSize: 24)),
      ),
      title: Text(
        producto['nombre'],
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.teal),
            onPressed: () => onUpdate(-1),
          ),
          Text(producto['cantidad'].toString(),
              style: const TextStyle(color: Colors.teal)),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.teal),
            onPressed: () => onUpdate(1),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}