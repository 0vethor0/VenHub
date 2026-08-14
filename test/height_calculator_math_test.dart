import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:ven911_app/utils/height_calculator_math.dart';

void main() {
  test('calcularAlturaPoste con angulo 45 grados', () {
    // observador a 1.6m, 10m de distancia, angulo de 45 grados (tan=1)
    final altura = calcularAlturaPoste(
      alturaObservadorMetros: 1.6,
      distanciaMetros: 10,
      anguloRadianes: pi / 4,
    );
    expect(altura, closeTo(11.6, 0.01));
  });

  test(
    'anguloDesdeAcelerometro con telefono en reposo (apuntando horizontal)',
    () {
      // z=0 (sin componente vertical) => angulo 0
      final angulo = anguloDesdeAcelerometro(0, 9.8, 0);
      expect(angulo, closeTo(0, 0.01));
    },
  );

  test(
    'anguloDesdeAcelerometro con telefono inclinado hacia arriba 45 grados',
    () {
      // y=z => atan2(z, y) = 45 grados
      final angulo = anguloDesdeAcelerometro(0, 7, 7);
      expect(angulo, closeTo(pi / 4, 0.01));
    },
  );
}
