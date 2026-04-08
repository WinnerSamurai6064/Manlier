import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService extends ChangeNotifier {
  int _steps = 0;
  double _currentSpeed = 0.0; // m/s approx
  bool _isRunning = false;
  Timer? _timer;
  int _elapsedSeconds = 0;

  // Accelerometer-based step detection
  double _lastMagnitude = 0;
  bool _stepPeak = false;
  StreamSubscription? _accelSub;

  int get steps => _steps;
  double get currentSpeed => _currentSpeed;
  bool get isRunning => _isRunning;
  int get elapsedSeconds => _elapsedSeconds;

  double get distanceKm {
    // Average stride length ~0.75m
    return (_steps * 0.75) / 1000;
  }

  double caloriesBurned(double weightKg) {
    // MET value ~8 for running, simplified
    return (_elapsedSeconds / 3600) * 8 * weightKg;
  }

  double get pace {
    if (distanceKm == 0 || _elapsedSeconds == 0) return 0;
    return (_elapsedSeconds / 60) / distanceKm;
  }

  void startRun() {
    _steps = 0;
    _elapsedSeconds = 0;
    _isRunning = true;
    _startAccelerometer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  void _startAccelerometer() {
    _accelSub = accelerometerEventStream().listen((event) {
      final magnitude = _magnitude(event.x, event.y, event.z);
      _detectStep(magnitude);
      _currentSpeed = _estimateSpeed(magnitude);
    });
  }

  double _magnitude(double x, double y, double z) {
    return (x * x + y * y + z * z) / 100;
  }

  void _detectStep(double mag) {
    const threshold = 1.2;
    if (mag > threshold && !_stepPeak && _isRunning) {
      _stepPeak = true;
      _steps++;
      notifyListeners();
    } else if (mag < threshold * 0.8) {
      _stepPeak = false;
    }
    _lastMagnitude = mag;
  }

  double _estimateSpeed(double mag) {
    // Rough speed estimation from acceleration magnitude
    if (mag < 0.9) return 0;
    if (mag < 1.2) return 1.5;
    if (mag < 1.8) return 3.0;
    if (mag < 2.5) return 5.0;
    return 7.0;
  }

  void pauseRun() {
    _isRunning = false;
    _timer?.cancel();
    _accelSub?.cancel();
    notifyListeners();
  }

  void resumeRun() {
    _isRunning = true;
    _startAccelerometer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  void stopRun() {
    _isRunning = false;
    _timer?.cancel();
    _accelSub?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accelSub?.cancel();
    super.dispose();
  }
}
