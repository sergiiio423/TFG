import 'package:flutter/material.dart';
import 'registro.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _showContent = false;
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 300), () {
        setState(() => _showContent = true);
      });
      Future.delayed(Duration(milliseconds: 800), () {
        setState(() => _showButtons = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/fondo.png',
              fit: BoxFit.cover,
            ),
          ),
          AnimatedOpacity(
            opacity: _showContent ? 1.0 : 0.0,
            duration: Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            child: AnimatedSlide(
              offset: _showContent ? Offset.zero : Offset(0.0, 0.1),
              duration: Duration(milliseconds: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Image.asset('assets/imagen.png'),
                    ),
                  ),
                  _buildTextContent(),
                  _buildButtons(context),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      children: [
        Text(
          '¡Empieza a gestionar tu hogar!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Color(0xFF4BA58A),
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Organiza tareas, divide gastos y vive mejor con tus compañeros',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            color: Colors.black54,
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return AnimatedOpacity(
      opacity: _showButtons ? 1.0 : 0.0,
      duration: Duration(milliseconds: 500),
      child: AnimatedSlide(
        offset: _showButtons ? Offset.zero : Offset(0.0, 0.5),
        duration: Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4BA58A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/inicio_sesion');
                },
                child: Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistrationPage(),
                      settings: RouteSettings(),
                    ),
                  );
                },
                child: Text(
                  'Registrarse',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}