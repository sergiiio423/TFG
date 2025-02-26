import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectHomeScreen extends StatelessWidget {
  const ConnectHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFAF5),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Conéctate con tu hogar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF52A090),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Crea tu propio hogar o únete a uno ya existente',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/crear_hogar');
              },
              style: buttonStyle(),
              child: Text('Crea tu hogar', style: buttonTextStyle()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _showJoinHomeModal(context);
              },
              style: buttonStyle(),
              child: Text('Unirse a un hogar', style: buttonTextStyle()),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Función para mostrar el modal de unión
  void _showJoinHomeModal(BuildContext context) {
    List<TextEditingController> controllers = List.generate(6, (index) => TextEditingController());

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Introduce el código del hogar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (index) => Container(
                    width: 40,
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: controllers[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  String code = controllers.map((controller) => controller.text).join();
                  if (code.length == 6) {
                    // Verificar si el código corresponde a un hogar existente
                    bool success = await _joinHomeWithCode(code, context);
                    if (success) {
                       Navigator.pushReplacementNamed(context, '/home');
                    } else {
                      // Mostrar error si el código no es válido
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código de hogar inválido')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El código debe tener 6 dígitos')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF52A090),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Unirse',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Función para unirse a un hogar con un código
  Future<bool> _joinHomeWithCode(String code, BuildContext context) async {
    try {
      // Buscar el hogar en Firestore con el código
      var homeDoc = await FirebaseFirestore.instance
          .collection('hogar')
          .where('codigo', isEqualTo: code)
          .get();

      if (homeDoc.docs.isNotEmpty) {
        // Si el hogar existe, asociar el hogar con el usuario actual
        String homeId = homeDoc.docs.first.id;
        String userId = FirebaseAuth.instance.currentUser!.uid;

        // Agregar el uid del usuario al array de miembros del hogar
        await FirebaseFirestore.instance
            .collection('hogar')
            .doc(homeId)
            .update({
          'miembros': FieldValue.arrayUnion([userId]),
        });

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Te has unido al hogar exitosamente')),
        );

        return true;
      } else {
        // Si no se encuentra el hogar
        return false;
      }
    } catch (e) {
      // Si ocurre algún error
      print(e);
      return false;
    }
  }
}

// Estilos reutilizables para los botones
ButtonStyle buttonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF52A090),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    padding: const EdgeInsets.symmetric(vertical: 15),
    minimumSize: const Size(double.infinity, 50),
    shadowColor: Colors.black.withOpacity(0.2),
    elevation: 4,
  );
}

TextStyle buttonTextStyle() {
  return const TextStyle(fontSize: 18, color: Colors.white);
}
