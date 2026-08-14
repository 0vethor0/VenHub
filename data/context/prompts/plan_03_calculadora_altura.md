# Plan de Acción — Feature 3: Calculadora de Altura por Trigonometría

**Parte de un set de 4 planes independientes:** `01_mapa_editable` · `02_fibra_optica_y_campos_camara` · `03_calculadora_altura` (este) · `04_exportacion_reportes`.
**Archivos que esta feature comparte con las otras:** `lib/screens/map/widgets/point_form_modal.dart`, `pubspec.yaml`. Si Feature 2 agregó `fibra_form_modal.dart`, el botón de esta feature se agrega ahí también (mismo widget, dos puntos de uso).
**No depende de** ninguna otra feature ni de cambios de base de datos — usa el campo `altura_poste_metros` que ya existe.

---

## 0. Corrección técnica antes de implementar

Pediste "giroscopio" — el sensor correcto es el **acelerómetro**. El giroscopio mide velocidad angular; integrarla para estimar orientación acumula error (deriva) en segundos. Lo que se necesita es una lectura de inclinación **estática y puntual**: el acelerómetro mide el vector de gravedad, y con el teléfono quieto apuntando a la punta del poste, el ángulo entre ese vector y el eje del teléfono da la inclinación directamente, sin integración ni deriva. En Flutter: `sensors_plus` → `accelerometerEventStream()`.

Fórmula (correcta, la propuesta original):

```
altura_poste = altura_observador + distancia_al_poste * tan(angulo_inclinacion)
```

Dos correcciones que meten error **sistemático**, no ruido, si se pasan por alto:

1. **"Altura del observador" debe ser altura de OJO, no estatura total** — el ángulo se mide desde donde está el ojo/teléfono, no desde el piso. Restar ~10 cm a la estatura es la aproximación de campo estándar; ponlo como hint del input, no lo asumas en silencio.
2. **El ángulo es respecto al eje horizontal, no al vertical** — confirmar el signo al implementar el cálculo desde `(x, y, z)` del acelerómetro. Invertir esto no da un error grande: da un resultado sin sentido (alturas negativas o absurdas).

**Sobre precisión, para que las expectativas de campo sean realistas:** con pulso de mano y una sola lectura, el acelerómetro de un celular típico tiene ±3–5° de ruido. A 15 m de distancia eso es más de 1 m de error en la altura estimada — aceptable para planear campo de visión de cámara, no para ingeniería estructural. Se mitiga promediando ~2 segundos de muestras (no una lectura instantánea).

---

## 1. Dependencia nueva

```yaml
dependencies:
  sensors_plus: ^6.0.0   # verificar última versión estable en pub.dev al implementar
```

iOS requiere agregar en `ios/Runner/Info.plist`:

```xml
<key>NSMotionUsageDescription</key>
<string>Necesitamos acceso al sensor de movimiento para calcular la altura del poste con la cámara del teléfono.</string>
```

Sin esto la app crashea al pedir el sensor en iOS — no es opcional.

---

## 2. Lógica central (pura, sin UI)

```dart
import 'dart:math';

/// Ángulo de inclinación respecto a la horizontal, en radianes.
/// Asume el teléfono sostenido en vertical (retrato), pantalla hacia el
/// usuario, borde superior apuntando al punto más alto del poste.
/// VALIDAR el mapeo de ejes (x/y/z) con un dispositivo real antes de
/// confiar en el signo — varía según cómo el usuario sostiene el teléfono
/// y no hay forma de garantizarlo solo desde el código.
double anguloDesdeAcelerometro(double x, double y, double z) {
  return atan2(z, sqrt(x * x + y * y));
}

double calcularAlturaPoste({
  required double alturaObservadorMetros, // altura de OJO, no estatura
  required double distanciaMetros,
  required double anguloRadianes,
}) {
  return alturaObservadorMetros + distanciaMetros * tan(anguloRadianes);
}
```

`ponytail:` estas dos funciones van en un archivo propio sin dependencias de Flutter (`lib/utils/height_calculator_math.dart`), no adentro del widget — así se testean sin levantar un `WidgetTester` y sin mockear sensores.

---

## 3. Widget — `lib/screens/map/widgets/height_calculator_sheet.dart` (nuevo)

Flujo:

1. Input "Altura de tus ojos (m)" — hint: *"Tu estatura menos ~10 cm, o mide directo hasta el ojo"*.
2. Input "Distancia hasta la base del poste (m)".
3. Botón "Apuntar y capturar ángulo": suscribe a `accelerometerEventStream()` durante ~2 segundos, promedia las lecturas de `x, y, z`, calcula el ángulo una sola vez con el promedio (no con la primera muestra — el ruido instantáneo es alto). Muestra el ángulo en vivo mientras se captura, para que el usuario vea si el teléfono se mueve demasiado.
4. Botón "Calcular" → aplica `calcularAlturaPoste` → muestra el resultado con el aviso *"Estimado, ajusta si lo sabes con mayor precisión"* → botón "Usar este valor" que retorna el número al modal que lo invocó.
5. Fallback manual: si `onError` del stream dispara (sensor no disponible) o el usuario no confía en la lectura, mostrar un input numérico de ángulo en grados como alternativa — mismo cálculo, sin bloquear el flujo por falta de hardware.

Captura promediada:

```dart
Future<double> capturarAnguloPromedio({Duration duracion = const Duration(seconds: 2)}) async {
  final muestras = <AccelerometerEvent>[];
  final completer = Completer<double>();
  late final StreamSubscription sub;

  sub = accelerometerEventStream().listen(
    (e) => muestras.add(e),
    onError: (_) {
      sub.cancel();
      if (!completer.isCompleted) completer.completeError('sensor no disponible');
    },
  );

  Future.delayed(duracion, () {
    sub.cancel();
    if (muestras.isEmpty) {
      if (!completer.isCompleted) completer.completeError('sin muestras');
      return;
    }
    final x = muestras.map((e) => e.x).reduce((a, b) => a + b) / muestras.length;
    final y = muestras.map((e) => e.y).reduce((a, b) => a + b) / muestras.length;
    final z = muestras.map((e) => e.z).reduce((a, b) => a + b) / muestras.length;
    if (!completer.isCompleted) completer.complete(anguloDesdeAcelerometro(x, y, z));
  });

  return completer.future;
}
```

---

## 4. Botón en el formulario — `point_form_modal.dart`

Al lado del input `_alturaPosteController`:

```dart
IconButton(
  icon: const Icon(Icons.straighten, color: AppTheme.primaryBlue),
  tooltip: 'Calcular altura con el teléfono',
  onPressed: () async {
    final resultado = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const HeightCalculatorSheet(),
    );
    if (resultado != null) {
      _alturaPosteController.text = resultado.toStringAsFixed(2);
    }
  },
),
```

El sheet **nunca escribe el input directamente sin que el usuario confirme** ("Usar este valor") — y el input sigue editable después, para que el usuario pueda ajustar el número si lo sabe con más precisión.

`ponytail:` no promedies con un filtro de Kalman ni fusión de sensores. Un promedio simple de ~2 s ya reduce el ruido lo suficiente para este caso de uso (estimación de campo, no topografía). Sube complejidad solo si en campo real el error resulta inaceptable.

---

## 5. Fase de Validación

1. **`flutter test`**
   - Estas dos funciones son puras y triviales de testear — sin excusa para saltárselo:
     ```dart
     // test/height_calculator_math_test.dart
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

       test('anguloDesdeAcelerometro con telefono en reposo (apuntando horizontal)', () {
         // z=0 (sin componente vertical) => angulo 0
         final angulo = anguloDesdeAcelerometro(0, 9.8, 0);
         expect(angulo, closeTo(0, 0.01));
       });
     }
     ```
   - Si algún test existente falla por este cambio, corrige el código o el test — nunca borres un test para que pase.
2. **`flutter analyze`**
   - Cero errores antes de continuar. Corrige los warnings que introduce este cambio; no arrastres limpieza de warnings preexistentes ajenos a este PR.
   - Si aparece un error, corrígelo y vuelve a correr `flutter test` antes de seguir.
3. **`dart format .`**
   - Sobre todo el repo, no solo los archivos tocados.
   - Si formatea archivos que esta feature no tocó, sepáralos en un commit aparte (`chore: dart format`).

Orden importa: test → analyze → format.
