import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "dart:async";

import 'package:gtk_flutter/home_pageUser.dart';
import 'package:firebase_database/firebase_database.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  late Timer _locationTimer;
  List<String> correos = [];
  List<Map> listaPosiciones = []; // Lista para almacenar las posiciones de los usuarios

    Future<List<String>> getAllLogedUsersEmail() async{
    try {
      DatabaseReference logedUsersReference= FirebaseDatabase.instance.ref().child("logedusers");
      final snapshot = await logedUsersReference.once().then((value) => value.snapshot);

      List<String> emails = [];
      for(var child in snapshot.children){
        emails.add( child.child("logedUserMail").value as String );
      }

      return emails;
    } catch (e) {
      print("error al obtener los correos de los usuarios logeados: $e");
      return [];
    }
  }

    

  Future<List<Map>> getUsersPositions(final List<String> correosPosicion) async {
    try {

      List<Map> listaPosiciones = [];
      for(int i = 0; i < correosPosicion.length; i++){
        QuerySnapshot query = await FirebaseFirestore.instance
          .collection("posiciones")
          .where("userEmail", isEqualTo: correosPosicion[i])
          .get();

      
        if(query.docs.isNotEmpty){
          final String docId = query.docs[0].id;
            var latitud = await FirebaseFirestore.instance.collection("posiciones").doc(docId).get();
            //print("valor latitud: " + latitud["latitud"].toString());
            //print("valor longitud: " + latitud["longitud"].toString());
          listaPosiciones.add( {"latitud":latitud["latitud"] as double, "longitud":latitud["longitud"] as double} );
        }
      }


      print("Lista de posiciones de logeados: $listaPosiciones");
      return listaPosiciones;
    } catch (e) {
      
      print("Error al mostrar los usuarios: $e");
      return [];
    }
  }

  Future<List<Map>> getUsersPositionsFromLogedUsers() async {
    correos = await getAllLogedUsersEmail();
    Future.delayed(Duration(seconds: 2));
    return getUsersPositions(correos);
  }

  @override
  void initState() {
    super.initState();
    
    _startLocationTimer();
  }

    @override
  void dispose() {
    // Cancela el temporizador al salir de la página para evitar pérdida de recursos
    _locationTimer.cancel();
    super.dispose();
  }


    // Inicia el temporizador
  void _startLocationTimer() {
    _locationTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _updateUserAndOthersLocations();
    });
  }

  Future<void> _updateUserAndOthersLocations() async {
    try {
      Position userPosition = await getUserCurrentPosition();
      User? user = getCurrentUser();

      // Actualizar la ubicación del usuario en Firestore
      if (user != null) {
        await _updateUserLocationInFirestore(userPosition, user.email);
      }

      // Obtener las posiciones de otros usuarios y actualizar el estado
      List<Map> otherUsersPositions = await getUsersPositionsFromLogedUsers();
      setState(() {
        listaPosiciones = otherUsersPositions;
      });
    } catch (e) {
      print("Error al actualizar ubicación: $e");
    }
  }

    Future<void> _updateUserLocationInFirestore(Position position, String? userEmail) async {
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('posiciones')
          .where('userEmail', isEqualTo: userEmail)
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
          'userEmail': userEmail,
        });

        print("Nuevo documento creado en Firestore: ${position.latitude}, ${position.longitude}");
      }
    } catch (e) {
      print("Error al enviar ubicación a Firestore: $e");
    }
  }
  // Método para enviar la ubicación del usuario a Firestore
  /*
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
*/


  User? getCurrentUser(){
    final User? user = FirebaseAuth.instance.currentUser;
    return user;
  }

  //current user location with permissions
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
    
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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
  

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<Position>(
      future: getUserCurrentPosition(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else {
          Position userPosition  = snapshot.data!;
          listaPosiciones.add({"latitud": userPosition.latitude, "longitud": userPosition.longitude});

          // Crear marcadores para el usuario y otros usuarios
          List<Marker> markersList = [];

          for (int i = 0; i < listaPosiciones.length; i++) {
            double latitude = listaPosiciones[i]['latitud'] as double;
            double longitude = listaPosiciones[i]['longitud'] as double;
            String correo = correos[i]; // Obtener el correo del usuario

            Marker marker = Marker(
              markerId: MarkerId(correo), // Usar el correo como ID
              icon: BitmapDescriptor.defaultMarker,
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(
                title: "Ubicación de $correo",
                snippet: "Latitud: $latitude \nLongitud: $longitude",
              ),
            );

            markersList.add(marker);
          }

          return Scaffold(
            
            body: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(userPosition.latitude, userPosition.longitude),
                zoom: 13,
                
              ),
              markers: Set<Marker>.of(markersList),
            ),
            floatingActionButton: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                  MaterialPageRoute(builder: (context)=> HomePageUser())
                  );
                },
                child: const Text('Perfil'),
              ),
            ),
          );
        }
      },
    );
  }

}