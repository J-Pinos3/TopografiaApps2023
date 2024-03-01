import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'register_screen.dart';
import 'home_page.dart';
import 'home_pageUser.dart';
import 'package:firebase_database/firebase_database.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  Future<void> _signInWithEmailAndPassword(
    String email,
    String password,
    BuildContext context,
  ) async {
    // Verificar si el correo electrónico contiene caracteres en mayúsculas
    if (email.contains(RegExp(r'[A-Z]'))) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error de Inicio de Sesión'),
            content:
                const Text('El correo electrónico debe estar en minúsculas.'),
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
      return; // Detener el proceso de inicio de sesión
    }

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

  void sendLogedUserEmail({required String email}) async {
    try {
      DatabaseReference logedUsersReference =
          FirebaseDatabase.instance.ref().child("logedusers");

      //**************************
      QuerySnapshot query1 = await FirebaseFirestore.instance
          .collection("usuarios")
          .where("email", isEqualTo: email)
          .get();

      if (query1.docs.isNotEmpty) {
        final String docId = query1.docs[0].id;
        var usuario = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(docId)
            .get();
        final rol = usuario.get('rol');
        if (rol == "Administrador") {
          print("El administrador no envía posición");
          return;
        }
      }
      //**************************

      final query =
          logedUsersReference.orderByChild('logedUserMail').equalTo(email);
      final snapshot = await query.once();

      if (snapshot.snapshot.value != null) {
        print("El usuario ya se logeó en la app");
        return;
      }

      await logedUsersReference.push().set({'logedUserMail': email});

      print("El usuario ${email} se ha logeado");
    } catch (e) {
      print("No se pudo agregar el usuario logeado a la lista: $e");
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
            TextFormField(
              onChanged: (value) {
                email = value;
              },
              decoration: InputDecoration(
                labelText: 'Correo Electrónico',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              onChanged: (value) {
                password = value;
              },
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _signInWithEmailAndPassword(email, password, context);
                sendLogedUserEmail(email: email);
                //print("usuario agregado: ${authProvider.onlineUserEmails.length} -- ${authProvider.onlineUserEmails}");
              },
              child: const Text('Iniciar Sesión'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()),
                );
              },
              child: const Text('¿No tienes una cuenta? Regístrate aquí'),
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
        const Text('Integrantes:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Miguel Carapaz'),
        Text('David Basantes'),
        Text('Jose Pinos'),
      ],
    );
  }
}
