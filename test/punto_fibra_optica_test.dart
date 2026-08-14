import 'package:flutter_test/flutter_test.dart';
import 'package:ven911_app/models/punto_fibra_optica.dart';

void main() {
  test('fromMap parsea ubicacion en formato GeoJSON', () {
    final map = {
      'id': 'abc',
      'ubicacion': {
        'coordinates': [-68.735, 10.339],
      },
      'altura_poste_metros': 7.5,
    };
    final p = PuntoFibraOptica.fromMap(map);
    expect(p.latitud, 10.339);
    expect(p.longitud, -68.735);
    expect(p.alturaPosteMetros, 7.5);
  });

  test('fromMap parsea ubicacion en formato WKT', () {
    final map = {'id': 'abc', 'ubicacion': 'POINT(-68.735 10.339)'};
    final p = PuntoFibraOptica.fromMap(map);
    expect(p.latitud, 10.339);
    expect(p.longitud, -68.735);
  });
}
