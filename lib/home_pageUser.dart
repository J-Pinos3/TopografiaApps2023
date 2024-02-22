import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gtk_flutter/pages/map_page.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';

class HomePageUser extends StatelessWidget {
  const HomePageUser({Key? key});
  
  User? getCurrentUser(){
    final User? user = FirebaseAuth.instance.currentUser;
    return user;
  }

  Future<Position> _determinePosition() async{
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled(); 
    if(!serviceEnabled){
      return Future.error("Location is disabled");
    }

    permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied){
      permission = await Geolocator.requestPermission();
      if(permission == LocationPermission.denied){
        return Future.error("Location is denied");
      }   
    }

    if(permission == LocationPermission.deniedForever){
      return Future.error("Location services are denied forever, can't use geolocation services :(");
    }
    
    return await Geolocator.getCurrentPosition();
  }

  Future<Position> getUserCurrentPosition() async {
    try {
      Position position = await _determinePosition();
      User? usr = getCurrentUser();
      print("Position for ${usr?.email} ${usr?.displayName} ");
      print("Latitud: ${position.latitude}   Longitud: ${position.longitude}");
      return position;
    } catch (e) {
      print("Error getting user position: $e");
      return Future.error(e.toString());
    }
  }

  Future<void> _sendUserLocationToFirestore() async {
    try {
      Position position = await getUserCurrentPosition();
      User? user = getCurrentUser();

      // Verificar que la posición y el usuario sean válidos antes de enviar a Firestore
      if (user != null) {
        QuerySnapshot query = await FirebaseFirestore.instance
            .collection('posiciones')
            .where('userEmail', isEqualTo: user.email)
            .get();

        if (query.docs.isNotEmpty) {
          // El documento ya existe, actualiza sus campos
          final String docId = query.docs[0].id;

          await FirebaseFirestore.instance.collection('posiciones').doc(docId).update({
            'latitud': position.latitude,
            'longitud': position.longitude,
          });

          print("Ubicación actualizada en Firestore: ${position.latitude}, ${position.longitude}");
        } else {
          // El documento no existe, créalo
          await FirebaseFirestore.instance.collection("posiciones").add({
            'latitud': position.latitude,
            'longitud': position.longitude,
            'userEmail': user.email,
          });

          print("Nuevo documento creado en Firestore: ${position.latitude}, ${position.longitude}");
        }
      }
    } catch (e) {
      print("Error al enviar ubicación a Firestore: $e");
    }
  }

  void callbackDispatcher(){
    Workmanager().executeTask((task, inputData) async{
      
      print("Ejecutando tarea en segundo plano");

      await _sendUserLocationToFirestore();

      return Future.value(true);
    });
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
    final currentUserID = FirebaseAuth.instance.currentUser?.uid;
    
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuario'),
        actions: [
          ElevatedButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Workmanager().cancelAll();
              removeUserFromRealtime(user!.email!);
            },
            child: const Text('Cerrar Sesión'),
          ),
          ElevatedButton(
            onPressed: (){
              Navigator.push(context,
              MaterialPageRoute(builder: (context)=> MapPage()),);

              Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
              Workmanager().registerPeriodicTask(
                "1",
                "simpleTaskLocation",
                frequency: const Duration(seconds: 10)
              );
            },
            child: const Text("Ubicación Actual")
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(currentUserID)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          var usuario = snapshot.data!;
          var nombre = usuario['nombre'];
          var apellido = usuario['apellido'];
          var rol = usuario['rol'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Text('Nombre: $nombre $apellido'),
                Text('Rol: $rol'),
              ],
            ),
          );
        },
      ),
    );
  }
}
