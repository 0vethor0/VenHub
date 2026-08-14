import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ven911_app/models/punto_camara.dart';
import 'package:ven911_app/screens/map/map_screen.dart';

void main() {
  test(
    'nearestCamara devuelve el punto más cercano, no el primero de la lista',
    () {
      final tap = const LatLng(10.0, -68.0);
      final lejano = PuntoCamara(
        id: '1',
        nombre: 'A',
        latitud: 10.5,
        longitud: -68.5,
      );
      final cercano = PuntoCamara(
        id: '2',
        nombre: 'B',
        latitud: 10.001,
        longitud: -68.001,
      );

      final resultado = nearestCamara(tap, [lejano, cercano]);
      expect(resultado?.id, '2');
    },
  );
}
