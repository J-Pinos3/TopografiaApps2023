import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "dart:async";

import 'package:gtk_flutter/home_pageUser.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {

  late Timer _locationTimer;


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
    _locationTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _sendUserLocationToFirestore();
    });
  }

  // Método para enviar la ubicación del usuario a Firestore
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


  static const LatLng _pGooglePlex = LatLng(62.241061, 25.7396192);
  static const LatLng _pGooglePartKey = LatLng(62.304253, 25.829452);
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
          Position userPosition = snapshot.data!;
          return Scaffold(
            body: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(userPosition.latitude, userPosition.longitude),
                zoom: 13,
              ),
              markers: {
                Marker(
                  markerId: MarkerId("_currentLocation"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _pGooglePlex,
                ),
                Marker(
                  markerId: MarkerId("_secondLocation"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _pGooglePartKey,
                ),
                Marker(
                  markerId: MarkerId("_userLocarion"),
                  icon: BitmapDescriptor.defaultMarker,
                  position:
                      LatLng(userPosition.latitude, userPosition.longitude),
                ),
              },
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