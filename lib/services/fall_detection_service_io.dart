import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/material.dart';

class FallDetectionService extends ChangeNotifier {
  // Modèle TFLite
  Interpreter? _interpreter;

  // Paramètres de normalisation
  final List<double> _means = [
    21.753410248600193,
    5.051467270102476,
    9.964557502975554,
    3.906186028182702,
    7.934861058242888,
    1.711623379329533,
    1.6260487354153212,
    3.232623636686232,
    5.190129045684866,
  ];
  final List<double> _stds = [
    5.477851792474112,
    2.9644680794124263,
    11.983541292070731,
    5.49373254780357,
    4.428214123459073,
    1.5298242087715417,
    0.9992553057764303,
    3.4314081260842455,
    4.9901304665097586,
  ];

  static const int windowSize = 100;
  final List<List<double>> _buffer = [];

  List<double>? _lastAccel;
  List<double>? _lastGyro;

  Timer? _samplingTimer;
  double _threshold = 0.8;

  Function? onFallDetected;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'models/fall_detection.tflite',
      );
      print('✅ Modèle IA chargé');
    } catch (e) {
      print('❌ Erreur chargement modèle: $e');
    }
  }

  void startListening() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      _lastAccel = [event.x, event.y, event.z];
    });
    gyroscopeEvents.listen((GyroscopeEvent event) {
      _lastGyro = [event.x, event.y, event.z];
    });
    _samplingTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      if (_lastAccel != null && _lastGyro != null) {
        _addSample([..._lastAccel!, ..._lastGyro!]);
      }
    });
  }

  void _addSample(List<double> sample) {
    _buffer.add(sample);
    if (_buffer.length > windowSize) _buffer.removeAt(0);
    if (_buffer.length == windowSize) _processWindow();
  }

  void _processWindow() {
    List<double> features = _extractFeatures(_buffer);
    double probability = _predict(features);
    if (probability > _threshold) {
      print('🚨 Chute détectée ! Probabilité: $probability');
      onFallDetected?.call();
    }
  }

  List<double> _extractFeatures(List<List<double>> window) {
    List<double> accNorms = window
        .map((e) => sqrt(e[0] * e[0] + e[1] * e[1] + e[2] * e[2]))
        .toList();
    List<double> gyroNorms = window
        .map((e) => sqrt(e[3] * e[3] + e[4] * e[4] + e[5] * e[5]))
        .toList();

    double accMax = accNorms.reduce(max);
    double gyroMax = gyroNorms.reduce(max);
    double accKurtosis = _kurtosis(accNorms);
    double gyroKurtosis = _kurtosis(gyroNorms);
    double linMax = accMax;
    double accSkewness = _skewness(accNorms);
    double gyroSkewness = _skewness(gyroNorms);
    double postGyroMax = gyroMax;
    double postLinMax = accMax;

    return [
      accMax,
      gyroMax,
      accKurtosis,
      gyroKurtosis,
      linMax,
      accSkewness,
      gyroSkewness,
      postGyroMax,
      postLinMax,
    ];
  }

  double _mean(List<double> data) => data.reduce((a, b) => a + b) / data.length;

  double _skewness(List<double> data) {
    double n = data.length.toDouble();
    double m = _mean(data);
    double m2 = 0, m3 = 0;
    for (var v in data) {
      double dev = v - m;
      m2 += dev * dev;
      m3 += dev * dev * dev;
    }
    m2 /= n;
    m3 /= n;
    if (m2 == 0) return 0;
    return m3 / pow(m2, 1.5);
  }

  double _kurtosis(List<double> data) {
    double n = data.length.toDouble();
    double m = _mean(data);
    double m2 = 0, m4 = 0;
    for (var v in data) {
      double dev = v - m;
      m2 += dev * dev;
      m4 += dev * dev * dev * dev;
    }
    m2 /= n;
    m4 /= n;
    if (m2 == 0) return 0;
    return m4 / (m2 * m2) - 3;
  }

  List<double> _normalize(List<double> input) {
    return List.generate(
      input.length,
      (i) => (input[i] - _means[i]) / _stds[i],
    );
  }

  double _predict(List<double> features) {
    if (_interpreter == null) return 0;
    var input = [_normalize(features)];
    var output = List.filled(1, 0.0).reshape([1, 1]);
    _interpreter!.run(input, output);
    return output[0][0];
  }

  @override
  void dispose() {
    _samplingTimer?.cancel();
    _interpreter?.close();
    super.dispose();
  }

  /// Test helper used only for manual testing in the UI.
  /// Calls the `onFallDetected` callback if set.
  void triggerTestFall() {
    try {
      onFallDetected?.call();
    } catch (_) {}
  }
}
