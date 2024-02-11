import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lugar.dart';
import 'login_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key});

  Future<void> cargarLugarConImagen(
      String nombre, String descripcion, String imagenUrl) async {
    Lugar nuevoLugar = Lugar(
      nombre: nombre,
      descripcion: descripcion,
      imagenUrl: imagenUrl,
    );

    try {
      await FirebaseFirestore.instance.collection('lugares_turisticos').add({
        'nombre': nuevoLugar.nombre,
        'descripcion': nuevoLugar.descripcion,
        'imagen': nuevoLugar.imagenUrl,
      });
      print("nombre: ${nuevoLugar.nombre}\n${nuevoLugar.descripcion}");
    } catch (e) {
      print('Error al agregar el lugar con imagen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lugares turisticos'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lugares_turisticos')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            );
          }

          var lugares = snapshot.data!.docs;

          List<Widget> listaLugares = [];
          for (var lugar in lugares) {
            var nombre = lugar['nombre'];
            var descripcion = lugar['descripcion'];
            var imagenUrl = lugar['imagen'];

            listaLugares.add(
              Column(
                children: [
                  Image.network(
                    imagenUrl,
                    width: 600,
                    height: 600,
                  ),
                  SizedBox(height: 8),
                  Text(nombre),
                  Text(descripcion),
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
            children: listaLugares,
          );
        },
      ),
    );
  }
}
