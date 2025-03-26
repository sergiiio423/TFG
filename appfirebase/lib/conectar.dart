import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectHomeScreen extends StatelessWidget {
  const ConnectHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con overlay degradado
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/fondo.png'),
                  fit: BoxFit.cover,
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.6),
                    Colors.white.withOpacity(0.8)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // Contenido principal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Encabezado
                Column(
                  children: [
                    Text(
                      'Conéctate con tu hogar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.teal,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Crea tu propio hogar o únete a uno ya existente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                
                _buildActionButton(
                  context: context,
                  text: 'Crea tu hogar',
                  icon: Icons.home_rounded,
                  route: '/crear_hogar',
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  context: context,
                  text: 'Unirse a un hogar',
                  icon: Icons.group_add_rounded,
                  onPressed: () => _showJoinHomeModal(context),
                ),
                const SizedBox(height: 40),

                // Botón de cerrar sesión
                OutlinedButton.icon(
                  icon: Icon(Icons.logout_rounded, size: 18, color: Colors.grey[800]),
                  label: Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/bienvenida');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    String? route,
    Function()? onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24, color: Colors.white),
      label: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF52A090),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      onPressed: () => onPressed != null 
          ? onPressed() 
          : Navigator.pushNamed(context, route!),
    );
  }

  void _showJoinHomeModal(BuildContext context) {
    final controllers = List.generate(6, (index) => TextEditingController());
    final focusNodes = List.generate(6, (index) => FocusNode());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado del modal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Unirse a un hogar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Campos de código
              Text(
                'Ingresa el código de 6 dígitos',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              
              // Inputs numéricos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 48,
                    child: TextField(
                      controller: controllers[index],
                      focusNode: focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal[800],
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.teal[400]!, width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
           
              ElevatedButton(
                onPressed: () async {
                  final code = controllers.map((c) => c.text).join();
                  if (code.length == 6) {
                    final success = await _joinHomeWithCode(code, context);
                    if (success && context.mounted) {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      _buildCustomSnackBar('El código debe tener 6 dígitos', Icons.error_rounded),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF52A090),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Verificar código',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SnackBar _buildCustomSnackBar(String text, IconData icon) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
      backgroundColor: Colors.red[400],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    );
  }

  Future<bool> _joinHomeWithCode(String code, BuildContext context) async {
    try {
      final homeDoc = await FirebaseFirestore.instance
          .collection('hogar')
          .where('codigo', isEqualTo: code)
          .get();

      if (homeDoc.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildCustomSnackBar('Código inválido', Icons.warning_rounded),
        );
        return false;
      }

      final homeId = homeDoc.docs.first.id;
      final userId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('hogar').doc(homeId).update({
        'miembros': FieldValue.arrayUnion([userId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        _buildCustomSnackBar('¡Unión exitosa!', Icons.check_circle_rounded),
      );

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildCustomSnackBar('Error en la conexión', Icons.error_outline_rounded),
      );
      return false;
    }
  }
}