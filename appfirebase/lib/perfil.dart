import 'package:appfirebase/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'navigation_bar.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? email;
  String? homeCode;
  String? homeName;
  List<String> members = [];
  String? firstName;
  String? lastName;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (_currentUser != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('usuarios').doc(_currentUser!.uid).get();

      if (userDoc.exists) {
        setState(() {
          firstName = userDoc['nombre'];
          lastName = userDoc['apellidos'];
          email = _currentUser!.email;
        });

        QuerySnapshot hogarSnapshot = await _firestore
            .collection('hogar')
            .where('miembros', arrayContains: _currentUser!.uid)
            .limit(1)
            .get();

        if (hogarSnapshot.docs.isNotEmpty) {
          var hogarData = hogarSnapshot.docs.first;
          setState(() {
            homeCode = hogarData['codigo'];
            homeName = hogarData['nombre'];
          });

          List<dynamic> memberIds = hogarData['miembros'];
          memberIds.remove(_currentUser!.uid);

          if (memberIds.isNotEmpty) {
            QuerySnapshot membersSnapshot = await _firestore
                .collection('usuarios')
                .where(FieldPath.documentId, whereIn: memberIds)
                .get();

            setState(() {
              members = membersSnapshot.docs
                  .map((doc) => "${doc['nombre']} ${doc['apellidos']}")
                  .toList();
            });
          }
        }
      }
    }
  }

  Future<void> _updateProfile(String newFirstName, String newLastName) async {
    try {
      await _firestore.collection('usuarios').doc(_currentUser!.uid).update({
        'nombre': newFirstName,
        'apellidos': newLastName,
      });
      
      setState(() {
        firstName = newFirstName;
        lastName = newLastName;
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditProfileModal() {
    TextEditingController firstNameController = 
      TextEditingController(text: firstName);
    TextEditingController lastNameController = 
      TextEditingController(text: lastName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white, 
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Editar Perfil',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: const TextStyle(color: Colors.teal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.teal),
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.teal),
                  filled: true,
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: 'Apellidos',
                  labelStyle: const TextStyle(color: Colors.teal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.teal),
                  ),
                  prefixIcon: const Icon(Icons.people, color: Colors.teal),
                  filled: true,
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese apellidos' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                initialValue: email,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.teal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  prefixIcon: const Icon(Icons.email, color: Colors.teal),
                  filled: true,
                  enabled: false,
                ),
                readOnly: true,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () async {
                  if (firstNameController.text.isEmpty ||
                      lastNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nombre y apellidos son requeridos'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  await _updateProfile(
                    firstNameController.text.trim(),
                    lastNameController.text.trim(),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Guardar Cambios',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: _showEditProfileModal,
              child: _buildProfileHeader(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildProfileContent(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 0, context: context),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD39C82).withOpacity(0.9),
            const Color(0xFFB87D64),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(Icons.person, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$firstName $lastName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email ?? "Cargando...",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.edit, color: Colors.white, size: 22),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _buildSectionCard(
          title: 'Configuración del hogar',
          children: [
            _buildEditableHomeNameItem(),
            const SizedBox(height: 12),
            _buildInfoItem(Icons.info, 'Código del hogar', homeCode),
            const SizedBox(height: 12),
            _buildMembersList(),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Preferencias',
          children: [
            _buildSwitchItem('Notificaciones', true),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Acciones',
          children: [
            _buildActionItem(Icons.exit_to_app, 'Abandonar hogar'),
            const Divider(height: 24),
            _buildActionItem(Icons.logout, 'Cerrar sesión', isLogout: true),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          "Versión 1.0.0",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableHomeNameItem() {
    return Row(
      children: [
        Icon(Icons.home_filled, color: Colors.teal, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nombre del hogar',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      homeName ?? "No disponible",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.teal),
                    onPressed: _showEditHomeModal,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _updateHomeName(String newHomeName) async {
    try {
      QuerySnapshot hogarSnapshot = await _firestore
          .collection('hogar')
          .where('miembros', arrayContains: _currentUser!.uid)
          .limit(1)
          .get();

      if (hogarSnapshot.docs.isNotEmpty) {
        var hogarDoc = hogarSnapshot.docs.first;
        await hogarDoc.reference.update({'nombre': newHomeName});
        setState(() => homeName = newHomeName);
      }
    } catch ( e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el hogar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditHomeModal() {
    TextEditingController homeNameController = 
      TextEditingController(text: homeName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Editar Hogar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: homeNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del hogar',
                  labelStyle: const TextStyle(color: Colors.teal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.teal),
                  ),
                  prefixIcon: const Icon(Icons.home, color: Colors.teal),
                  filled: true,
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: () async {
                  if (homeNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('El nombre del hogar es requerido'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  await _updateHomeName(homeNameController.text.trim());
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Guardar Cambios',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.orange.shade50, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String? value) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value ?? "No disponible",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_alt, color: Colors.teal, size: 24),
            const SizedBox(width: 12),
            Text(
              'Miembros del hogar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (members.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: Text(
              'No hay otros miembros registrados',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          )
        else
          ...members.map((member) => Padding(
                padding: const EdgeInsets.only(left: 36, bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 18, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(member, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildSwitchItem(String title, bool value) {
    return Row(
      children: [
        Icon(Icons.notifications_active, color: Colors.teal, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Switch(
          value: value,
          onChanged: (bool newValue) {},
          activeColor: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String title, {bool isLogout = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.teal),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: () {
        if (isLogout) {
          _confirmarCerrarSesion();
        } else if (title == "Abandonar hogar") {
          _confirmarAbandonoHogar();
        }
      },
    );
  }

  void _confirmarAbandonoHogar() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          title: Text(
            "Abandonar Hogar",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          content: Text(
            "¿Estás seguro de que deseas abandonar este hogar? Esta acción no se puede deshacer.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                "Cancelar",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(
                "Sí, Abandonar",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _abandonarHogar();
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmarCerrarSesion() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          title: Text(
            "Cerrar Sesión",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          content: Text(
            "¿Estás seguro de que deseas cerrar tu sesión?",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                "Cancelar",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text(
                "Sí, Cerrar Sesión",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _auth.signOut();
                Navigator.pushReplacementNamed(context, '/bienvenida');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _abandonarHogar() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      String userId = user.uid;

      DocumentSnapshot hogarSnapshot = await _firestore
          .collection('hogar')
          .where('miembros', arrayContains: userId)
          .limit(1)
          .get()
          .then((querySnapshot) => querySnapshot.docs.first);

      if (hogarSnapshot.exists) {
        String hogarId = hogarSnapshot.id;

        await _firestore.collection('hogar').doc(hogarId).update({
          'miembros': FieldValue.arrayRemove([userId])
        });

        Navigator.pushReplacementNamed(context, '/conectar');
      }
    } catch (e) {
      print("Error al abandonar el hogar: $e");
    }
  }

}