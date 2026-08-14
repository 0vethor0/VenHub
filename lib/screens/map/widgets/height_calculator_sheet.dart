import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/height_calculator_math.dart';

class HeightCalculatorSheet extends StatefulWidget {
  const HeightCalculatorSheet({super.key});

  @override
  State<HeightCalculatorSheet> createState() => _HeightCalculatorSheetState();
}

class _HeightCalculatorSheetState extends State<HeightCalculatorSheet> {
  final _alturaOjoController = TextEditingController(text: '1.60');
  final _distanciaController = TextEditingController();
  double? _anguloCapturado;
  bool _isCapturing = false;
  String? _error;

  @override
  void dispose() {
    _alturaOjoController.dispose();
    _distanciaController.dispose();
    super.dispose();
  }

  Future<void> _capturarAngulo() async {
    setState(() {
      _isCapturing = true;
      _error = null;
      _anguloCapturado = null;
    });

    try {
      final muestras = <AccelerometerEvent>[];
      final completer = Completer<double>();
      late final StreamSubscription sub;

      sub = accelerometerEventStream().listen(
        (e) => muestras.add(e),
        onError: (err) {
          if (!completer.isCompleted) {
            completer.completeError('Sensor no disponible');
          }
        },
      );

      // Capturar durante 2 segundos
      await Future.delayed(const Duration(seconds: 2));
      sub.cancel();

      if (muestras.isEmpty) {
        throw 'No se recibieron muestras del sensor';
      }

      final x =
          muestras.map((e) => e.x).reduce((a, b) => a + b) / muestras.length;
      final y =
          muestras.map((e) => e.y).reduce((a, b) => a + b) / muestras.length;
      final z =
          muestras.map((e) => e.z).reduce((a, b) => a + b) / muestras.length;

      final angulo = anguloDesdeAcelerometro(x, y, z);
      setState(() {
        _anguloCapturado = angulo;
        _isCapturing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isCapturing = false;
      });
    }
  }

  void _confirmar() {
    final hOjo = double.tryParse(_alturaOjoController.text);
    final dist = double.tryParse(_distanciaController.text);
    final ang = _anguloCapturado;

    if (hOjo != null && dist != null && ang != null) {
      final altura = calcularAlturaPoste(
        alturaObservadorMetros: hOjo,
        distanciaMetros: dist,
        anguloRadianes: ang,
      );
      Navigator.pop(context, altura);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anguloGrados = _anguloCapturado != null
        ? (_anguloCapturado! * 180 / pi).toStringAsFixed(1)
        : null;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Calculadora de Altura',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Usa trigonometría para estimar la altura del poste.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _alturaOjoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Altura de tus ojos (m)',
              hintText: 'Tu estatura menos ~10cm',
              prefixIcon: Icon(Icons.accessibility),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _distanciaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Distancia al poste (m)',
              hintText: 'Distancia desde tus pies a la base',
              prefixIcon: Icon(Icons.straighten),
            ),
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: AppTheme.dangerRed),
              ),
            ),
          ElevatedButton.icon(
            onPressed: _isCapturing ? null : _capturarAngulo,
            icon: _isCapturing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.camera_alt),
            label: Text(
              _isCapturing
                  ? 'Capturando ángulo...'
                  : 'Apuntar y capturar ángulo',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCapturing
                  ? Colors.grey
                  : AppTheme.primaryBlue,
            ),
          ),
          if (anguloGrados != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Ángulo capturado: $anguloGrados°',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.successGreen,
                ),
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed:
                (_anguloCapturado != null &&
                    _distanciaController.text.isNotEmpty)
                ? _confirmar
                : null,
            child: const Text('Calcular y usar valor'),
          ),
        ],
      ),
    );
  }
}
