import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_screen.dart'; // Asumiendo que RegisterScreen está en un archivo separado

class RegisterScreen extends StatelessWidget {
  RegisterScreen({Key? key}) : super(key: key);

  String selectedRole = 'Usuario';

  Future<void> _registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String lastName,
    BuildContext context,
  ) async {
    try {
      final UserCredential authResult =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Actualizar el nombre de usuario
      await authResult.user!.updateDisplayName('$name $lastName');

      // Guardar datos adicionales en Firestore, incluyendo el correo electrónico
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(authResult.user!.uid)
          .set({
        'nombre': name,
        'apellido': lastName,
        'rol': selectedRole,
        'email': email, // Agregar el correo electrónico aquí
      });

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error de Registro'),
            content: Text(e.message ?? 'Ocurrió un error durante el registro.'),
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
    String name = '';
    String lastName = '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrarse'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: ['Usuario', 'Administrador']
                  .map((role) => DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      ))
                  .toList(),
              onChanged: (value) {
                selectedRole = value!;
              },
              decoration: InputDecoration(
                labelText: 'Rol',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              onChanged: (value) {
                name = value;
              },
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              onChanged: (value) {
                lastName = value;
              },
              decoration: InputDecoration(
                labelText: 'Apellido',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              onChanged: (value) {
                email = value;
              },
              decoration: InputDecoration(
                labelText: 'Correo Electrónico',
                border: OutlineInputBorder(),
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
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _registerWithEmailAndPassword(
                  email,
                  password,
                  name,
                  lastName,
                  context,
                );
              },
              child: const Text('Registrarse'),
            ),
          ],
        ),
      ),
    );
  }
}
