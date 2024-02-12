import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_screen.dart';
import 'home_page.dart';
import 'home_pageUser.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  Future<void> _signInWithEmailAndPassword(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Obtener el rol del usuario
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .get();
      final rol = userDoc.get('rol');

      // Redirige al HomePage adecuado según el rol del usuario
      if (rol == 'Administrador') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else if (rol == 'Usuario') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePageUser()),
        );
      } else {
        // Si el rol no es válido, lanzar una excepción
        throw FirebaseAuthException(
          code: 'invalid-user-role',
          message: 'Rol de usuario no válido',
        );
      }
    } on FirebaseAuthException catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error de Inicio de Sesión'),
            content: Text(
              e.message ?? 'Ocurrió un error durante el inicio de sesión.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String email = '';
    String password = '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              onChanged: (value) {
                email = value;
              },
              decoration: InputDecoration(labelText: 'Correo Electrónico'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) {
                password = value;
              },
              obscureText: true,
              decoration: InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _signInWithEmailAndPassword(email, password, context);
              },
              child: const Text('Iniciar Sesión'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: const Text('Registrarse'),
            ),
            const SizedBox(height: 32),
            // Agregar el widget para mostrar los nombres de los desarrolladores
            DeveloperNamesWidget(),
          ],
        ),
      ),
    );
  }
}

class DeveloperNamesWidget extends StatelessWidget {
  const DeveloperNamesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Integrantes:'),
        const SizedBox(height: 8),
        Text('Miguel Carapaz'),
        Text('David Basantes'),
        Text('Jose Pinos'),
      ],
    );
  }
}
