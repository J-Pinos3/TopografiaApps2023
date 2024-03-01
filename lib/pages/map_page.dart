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
  List<Map> listaPosiciones = [];

  Future<List<String>> getAllLogedUsersEmail() async {
    try {
      DatabaseReference logedUsersReference =
          FirebaseDatabase.instance.ref().child("logedusers");
      final snapshot =
          await logedUsersReference.once().then((value) => value.snapshot);

      List<String> emails = [];
      for (var child in snapshot.children) {
        emails.add(child.child("logedUserMail").value as String);
      }

      return emails;
    } catch (e) {
      print("error al obtener los correos de los usuarios logeados: $e");
      return [];
    }
  }

  Future<List<Map>> getUsersPositions(
      final List<String> correosPosicion) async {
    try {
      List<Map> listaPosiciones = [];
      for (int i = 0; i < correosPosicion.length; i++) {
        QuerySnapshot query = await FirebaseFirestore.instance
            .collection("posiciones")
            .where("userEmail", isEqualTo: correosPosicion[i])
            .get();

        if (query.docs.isNotEmpty) {
          final String docId = query.docs[0].id;
          var latitud = await FirebaseFirestore.instance
              .collection("posiciones")
              .doc(docId)
              .get();
          listaPosiciones.add({
            "latitud": latitud["latitud"] as double,
            "longitud": latitud["longitud"] as double
          });
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
    return getUsersPositions(correos);
  }

  @override
  void initState() {
    super.initState();

    _startLocationTimer();
  }

  @override
  void dispose() {
    _locationTimer.cancel();
    super.dispose();
  }

  void _startLocationTimer() {
    _locationTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _updateUserAndOthersLocations();
    });
  }

  Future<void> _updateUserAndOthersLocations() async {
    try {
      Position userPosition = await getUserCurrentPosition();
      User? user = getCurrentUser();

      if (user != null) {
        await _updateUserLocationInFirestore(userPosition, user.email);
      }

      List<Map> otherUsersPositions = await getUsersPositionsFromLogedUsers();
      setState(() {
        listaPosiciones = otherUsersPositions;
      });
    } catch (e) {
      print("Error al actualizar ubicación: $e");
    }
  }

  Future<void> _updateUserLocationInFirestore(
      Position position, String? userEmail) async {
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('posiciones')
          .where('userEmail', isEqualTo: userEmail)
          .get();

      if (query.docs.isNotEmpty) {
        final String docId = query.docs[0].id;

        await FirebaseFirestore.instance
            .collection('posiciones')
            .doc(docId)
            .update({
          'latitud': position.latitude,
          'longitud': position.longitude,
        });

        print(
            "Ubicación actualizada en Firestore: ${position.latitude}, ${position.longitude}");
      } else {
        await FirebaseFirestore.instance.collection("posiciones").add({
          'latitud': position.latitude,
          'longitud': position.longitude,
          'userEmail': userEmail,
        });

        print(
            "Nuevo documento creado en Firestore: ${position.latitude}, ${position.longitude}");
      }
    } catch (e) {
      print("Error al enviar ubicación a Firestore: $e");
    }
  }

  User? getCurrentUser() {
    final User? user = FirebaseAuth.instance.currentUser;
    return user;
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Location is disabled");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location is denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          "Location services are denied forever, can't use geolocation services :(");
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
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
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else {
          Position userPosition = snapshot.data!;
          listaPosiciones.add({
            "latitud": userPosition.latitude,
            "longitud": userPosition.longitude
          });

          List<Marker> markersList = listaPosiciones.map((position) {
            double latitude = position['latitud'] as double;
            double longitude = position['longitud'] as double;

            return Marker(
                markerId: MarkerId('${position.hashCode}'),
                icon: BitmapDescriptor.defaultMarker,
                position: LatLng(latitude, longitude),
                infoWindow: InfoWindow(
                    title: "Posición",
                    snippet: "Latitud: $latitude\nLongitud: $longitude"));
          }).toList();

          return Scaffold(
            body: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target:
                        LatLng(userPosition.latitude, userPosition.longitude),
                    zoom: 13,
                  ),
                  markers: Set<Marker>.of(markersList),
                ),
                Positioned(
                  top: 16.0,
                  left: 16.0,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => HomePageUser()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(
                          255, 201, 210, 217), // Cambiar color de fondo
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            20.0), // Agregar bordes redondeados
                      ),
                      elevation: 6.0, // Agregar sombra
                    ),
                    child: const Text(
                      'Perfil',
                      style: TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
