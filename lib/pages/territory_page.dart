import 'dart:collection';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gtk_flutter/home_page.dart';
import 'package:provider/provider.dart';
import "dart:async";
import '../provider/auth_provider.dart';
import 'package:firebase_database/firebase_database.dart';

class TerritoryPage extends StatefulWidget {
  const TerritoryPage({super.key});

  @override
  State<TerritoryPage> createState() => _TerritoryPageState();
}

class _TerritoryPageState extends State<TerritoryPage> {
  List<Polyline> polylines = [];
  double area = 0.0;
  List<String> correos = [];
  Set<Polygon> _poligono = HashSet<Polygon>();

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
          //print("valor latitud: " + latitud["latitud"].toString());
          //print("valor longitud: " + latitud["longitud"].toString());
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

  void showArea(List<LatLng> posiciones) {
    area = 0;

    if (posiciones.length > 2) {
      for (var i = 0; i < posiciones.length - 1; i++) {
        var p1 = posiciones[i];
        var p2 = posiciones[i + 1];
        area += convertToRadian(p2.longitude - p1.longitude) *
            (2 +
                sin(convertToRadian(p1.latitude)) +
                sin(convertToRadian(p2.latitude)));
      }

      area = area * 6378137 * 6378137 / 2;
    }

    setState(() {
        area = area.abs();
    });
    print("AREA DE LA REGIÓN SOMBREADA: $area");
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map>>(
      // Usa FutureBuilder para la lista de posiciones

      future: getUsersPositionsFromLogedUsers(),
      builder: (context, snapshot) {
        final LatLng _japanPlex = LatLng(-35.0108686, -135.7597307);
        final LatLng _pomasquiPlex = LatLng(-0.0513676, -78.4572629);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else {
          // Extrae la lista de posiciones del snapshot
          List<Map> listaPosiciones = snapshot.data!;
          listaPosiciones.add({
            "latitud": _japanPlex.latitude,
            "longitud": _japanPlex.longitude
          });
          listaPosiciones.add({
            "latitud": _pomasquiPlex.latitude,
            "longitud": _pomasquiPlex.longitude
          });
          // Crea una lista de marcadores vacía
          List<Marker> markersList = [];
          List<LatLng> polylineCoordinates = listaPosiciones
              .map((posicion) => LatLng(posicion["latitud"] as double,
                  posicion["longitud"] as double))
              .toList();
          showArea(polylineCoordinates);
          polylineCoordinates.add(polylineCoordinates.first);

          Polyline polyline = Polyline(
            polylineId: PolylineId("ruta"),
            color: Colors.blue,
            points: polylineCoordinates.cast<LatLng>(),
            width: 5,
          );

          Set<Polyline> polylines = Set<Polyline>.of([polyline]);

          // Itera sobre las posiciones y crea un marcador para cada una
          for (int i = 0; i < listaPosiciones.length; i++) {
            double latitude = listaPosiciones[i]['latitud'] as double;
            double longitude = listaPosiciones[i]['longitud'] as double;

            Marker marker = Marker(
              markerId: MarkerId('${correos[i]}'), // Usa el email como ID
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

          final LatLng _poliPlex = LatLng(-0.2101573, -78.4888634);
          return Scaffold(
              body: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _poliPlex,
                  zoom: 13,
                ),
                markers: Set<Marker>.of(
                    markersList), // Usa Set para evitar marcadores duplicados
                polygons: _poligono,
              ),
              floatingActionButton: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => HomePage()));
                  },
                  child: const Text('Perfil'),
                ),
              ));
        }
      },
    );
  }
}
