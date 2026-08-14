import 'dart:math';

/// Ángulo de inclinación respecto a la horizontal, en radianes.
/// Asume el teléfono sostenido en vertical (retrato), pantalla hacia el
/// usuario, borde superior apuntando al punto más alto del poste.
double anguloDesdeAcelerometro(double x, double y, double z) {
  // En modo retrato, y es el eje vertical del teléfono.
  // z es el eje perpendicular a la pantalla.
  // atan2(z, y) daría el ángulo si x fuera 0.
  // Usamos sqrt(x*x + y*y) para ser robustos a ligeras inclinaciones laterales.
  return atan2(z, sqrt(x * x + y * y));
}

double calcularAlturaPoste({
  required double alturaObservadorMetros, // altura de OJO, no estatura
  required double distanciaMetros,
  required double anguloRadianes,
}) {
  return alturaObservadorMetros + distanciaMetros * tan(anguloRadianes);
}
