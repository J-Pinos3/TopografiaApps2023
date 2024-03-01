import 'dart:collection';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gtk_flutter/home_page.dart';
import 'package:provider/provider.dart';
import "dart:async";
import 'package:firebase_database/firebase_database.dart';

class TerritoryPage extends StatefulWidget {
  const TerritoryPage({super.key});

  @override
  State<TerritoryPage> createState() => _TerritoryPageState();
}

class _TerritoryPageState extends State<TerritoryPage> {
  late Timer _locationUpdateTimer;
  List<Map> listaPosiciones = [];
  List<Polyline> polylines = [];
  double area = 0.0;
  List<String> correos = [];
  Set<Polygon> _poligono = HashSet<Polygon>();

  @override
  void initState() {
    super.initState();

    _startUpdateLocationTimer();
  }

  @override
  void dispose() {
    _locationUpdateTimer.cancel();
    super.dispose();
  }

  void _updatePositions() async {
    try {
      List<Map> updatedPositions = await getUsersPositionsFromLogedUsers();
      setState(() {
        listaPosiciones = updatedPositions;
      });
    } catch (e) {
      print("Error fetching updated positions: $e");
    }
  }

  void _startUpdateLocationTimer() {
    _locationUpdateTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _updatePositions();
    });
  }

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

  static double convertToRadian(double input) {
    return input * pi / 180;
  }

  double showArea(List<LatLng> posiciones) {
    double areaSup = 0;

    if (posiciones.length > 2) {
      for (var i = 0; i < posiciones.length - 1; i++) {
        var p1 = posiciones[i];
        var p2 = posiciones[i + 1];
        areaSup += convertToRadian(p2.longitude - p1.longitude) *
            (2 +
                sin(convertToRadian(p1.latitude)) +
                sin(convertToRadian(p2.latitude)));
      }

      areaSup = areaSup * 6378137 * 6378137 / 2;
    }

    areaSup = areaSup.abs();

    print("AREA DEL POLÍGONO: $areaSup");
    return areaSup;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map>>(
      future: getUsersPositionsFromLogedUsers(),
      builder: (context, snapshot) {
        final LatLng _poliPlex = LatLng(-0.2101573, -78.4888634);
        final LatLng _japanPlex = LatLng(-35.0108686, -135.7597307);
        final LatLng _pomasquiPlex = LatLng(-0.0513676, -78.4572629);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else {
          listaPosiciones = snapshot.data!;
          List<Marker> markersList = [];
          List<LatLng> polylineCoordinates = listaPosiciones
              .map((posicion) => LatLng(posicion["latitud"] as double,
                  posicion["longitud"] as double))
              .toList();

          area = showArea(polylineCoordinates);

          polylineCoordinates.add(polylineCoordinates.first);

          Polyline polyline = Polyline(
            polylineId: PolylineId("ruta"),
            color: Colors.blue,
            points: polylineCoordinates.cast<LatLng>(),
            width: 5,
          );

          Set<Polyline> polylines = Set<Polyline>.of([polyline]);

          for (int i = 0; i < listaPosiciones.length; i++) {
            double latitude = listaPosiciones[i]['latitud'] as double;
            double longitude = listaPosiciones[i]['longitud'] as double;

            Marker marker = Marker(
              markerId: MarkerId('${correos[i]}'),
              icon: BitmapDescriptor.defaultMarker,
              position: LatLng(latitude, longitude),
            );

            markersList.add(marker);
          }

          _poligono.add(
            Polygon(
                polygonId: PolygonId("1"),
                points: polylineCoordinates,
                fillColor: Colors.green.withOpacity(0.3),
                strokeColor: Colors.green,
                geodesic: true,
                strokeWidth: 4),
          );

          return Scaffold(
            body: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _poliPlex,
                    zoom: 13,
                  ),
                  markers: Set<Marker>.of(markersList),
                  polygons: _poligono,
                ),
                Positioned(
                  top: 16.0,
                  left: 16.0,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => HomePage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 186, 193, 199),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      elevation: 6.0,
                    ),
                    child: Text(
                      'Perfil',
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ),
                Positioned(
                  top: 16.0,
                  left: MediaQuery.of(context).size.width / 2 - 100,
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "Área del Polígono: ${area.toStringAsFixed(2)}",
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold),
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
