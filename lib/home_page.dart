import 'dart:html';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import './provider/auth_provider.dart';
import "./pages/territory_page.dart";
import 'package:firebase_database/firebase_database.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key});

  Future<void> _eliminarUsuario(
      String userId, String userEmail, BuildContext context) async {
        final authProvider = context.watch<AuthenticationProvider>();
    // Muestra una alerta para confirmar la eliminación del usuario
    bool confirmacion = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eliminar Usuario'),
          content: Text('¿Está seguro de eliminar este usuario?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancelar
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirmar
              },
              child: Text('Eliminar'),
            ),
          ],
        );
      },
    );

    // Si se confirmó la eliminación, borra el usuario de Firebase Authentication y Firestore
    if (confirmacion) {
      try {
        // Borra el usuario de la colección 'usuarios' en Firestore
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .delete();

        // Autenticar con el usuario a eliminar
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: userEmail,
          password:
              'temporalPassword', // Esta es una contraseña temporal, ya que Firebase Auth no permite eliminar cuentas sin una contraseña
        );

        // Obtener el usuario actualmente logeado
        User? user = FirebaseAuth.instance.currentUser;

        // Verificar si el usuario a eliminar es diferente al usuario actualmente logeado
        if (user != null && user.uid != userId) {
          // Eliminar el usuario correspondiente a userId
          await user.delete();
          authProvider.removeUserFromOnlineList(user!.email!);
          print("usuario eliminado: ${authProvider.onlineUserEmails.length} -- ${authProvider.onlineUserEmails}");
        } else {
          print('No se puede eliminar el usuario actualmente logueado');
        }

        // Desloguear al usuario después de eliminar la cuenta
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        // Maneja cualquier error
        print('Error al eliminar usuario: $e');
      }
    }
  }

  void removeUserFromRealtime(String userMail) async{
    try {
      if(userMail.isNotEmpty){
        DatabaseReference logedUsersReference = FirebaseDatabase.instance.ref().child("logedusers");

        final query = logedUsersReference.orderByChild("logedUserMail").equalTo(userMail);
        query.once().then((event){
          DataSnapshot snapshot = event.snapshot;
          if(snapshot.exists){
              final logoutUserRef = snapshot.children.first.ref;
              logoutUserRef.remove();
          }else{
            return ;
          }
        });
      }
    } catch (e) {
      print("Error al eliminar usuario de la base de datos: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;


    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrador'),
        actions: [
          ElevatedButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              removeUserFromRealtime(user!.email!);
            },
            child: const Text('Cerrar Sesión'),
          ),
          ElevatedButton(
            onPressed: () {
                Navigator.push(context,
                MaterialPageRoute(builder: (context)=>TerritoryPage()) );
            },
            child: const Text('Topografia'),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            );
          }

          var usuarios = snapshot.data!.docs;

          List<Widget> listaUsuarios = [];
          for (var usuario in usuarios) {
            var nombre = usuario['nombre'];
            var apellido = usuario['apellido'];
            var email = usuario['email'];
            var rol = usuario['rol'];
            var userId = usuario.id;

            // Verificar si el usuario actual es igual al usuario que se está mostrando
            bool esUsuarioActual =
                FirebaseAuth.instance.currentUser?.uid == userId;

            listaUsuarios.add(
              Column(
                children: [
                  SizedBox(height: 8),
                  Text('Nombre: $nombre $apellido'),
                  Text('Correo: $email'),
                  Text('Rol: $rol'),
                  // Mostrar el icono de eliminación solo si el usuario no es el actualmente logeado
                  if (!esUsuarioActual)
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _eliminarUsuario(userId, email, context);
                      },
                    ),
                  Divider(
                    height: 8,
                    thickness: 1,
                    indent: 8,
                    endIndent: 8,
                    color: Colors.grey,
                  ),
                ],
              ),
            );
          }

          return ListView(
            children: listaUsuarios,
          );
        },
        
      ),

      
    );
  }
}
