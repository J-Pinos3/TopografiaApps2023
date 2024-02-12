import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class Lugar {
  String nombre;
  String descripcion;
  String imagenUrl;

  Lugar({
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
  });

  Future<void> subirImagen(File imagen) async {
    try {
      var storageRef = FirebaseStorage.instance.ref();

      var imagePath = 'lugares_turisticos/${nombre.replaceAll(' ', '_')}.jpg';

      var imageRef = storageRef.child(imagePath);

      await imageRef.putFile(imagen);

      var nuevaImagenUrl = await imageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('lugares_turisticos')
          .doc(nombre)
          .update({'imagen': nuevaImagenUrl});

      imagenUrl = nuevaImagenUrl;
    } catch (e) {
      print('Error al subir la imagen: $e');
    }
  }
}
