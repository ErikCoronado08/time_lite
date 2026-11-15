import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/app_settings.dart';
import 'share_run_screen.dart';

class RunningScreen extends StatefulWidget {
  const RunningScreen({super.key});

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  bool _isRunStarted = false;
  int _secondsElapsed = 0;
  Timer? _timer;

  double _totalDistanceMeters = 0.0;
  final List<LatLng> _routePoints = [];
  LatLng _currentPosition = const LatLng(19.4326, -99.1332);
  StreamSubscription<Position>? _positionStream;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled || !mounted) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || !mounted) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_currentPosition, 16.0);
  }

  void _startRun() {
    setState(() {
      _isRunStarted = true;
      _secondsElapsed = 0;
      _totalDistanceMeters = 0.0;
      _routePoints.clear();
      _routePoints.add(_currentPosition);
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      if (!mounted) return;
      LatLng newPoint = LatLng(position.latitude, position.longitude);
      setState(() {
        if (_routePoints.isNotEmpty) {
          double distance = Geolocator.distanceBetween(
            _currentPosition.latitude,
            _currentPosition.longitude,
            newPoint.latitude,
            newPoint.longitude,
          );
          _totalDistanceMeters += distance;
        }
        _currentPosition = newPoint;
        _routePoints.add(newPoint);
      });
      _mapController.move(newPoint, 16.0);
    });
  }

  void _stopRun() {
    _timer?.cancel();
    _positionStream?.cancel();
    if (mounted) {
      setState(() => _isRunStarted = false);
      _showSummaryDialog();
    }
  }

  void _showSummaryDialog() {
    final isDark = appSettings.isDarkMode;
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);
    double km = _totalDistanceMeters / 1000;
    int calories = (km * 65).toInt();
    String timeFormatted =
        '${(_secondsElapsed ~/ 60).toString().padLeft(2, '0')}:${(_secondsElapsed % 60).toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          appSettings.t('workout_finished'),
          style: TextStyle(
            color: isDark ? const Color(0xFF8FFF00) : const Color(0xFF3F51B5),
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${appSettings.t('distance_label')}: ${km.toStringAsFixed(2)} km',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${appSettings.t('time_label')}: $timeFormatted',
              style: TextStyle(color: textColor, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '${appSettings.t('calories_label')}: $calories kcal',
              style: TextStyle(color: textColor, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              appSettings.t('close'),
              style: const TextStyle(color: Colors.grey),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8FFF00),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: Text(
              appSettings.t('share'),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShareRunScreen(
                    routePoints: List<LatLng>.from(_routePoints),
                    distanceKm: km,
                    durationSeconds: _secondsElapsed,
                    calories: calories,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appSettings.isDarkMode;
    final panelColor =
        isDark ? const Color(0xFF161B2E).withOpacity(0.95) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A237E);

    String minutes = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    String seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    double km = _totalDistanceMeters / 1000;
    int calories = (km * 65).toInt();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: CircleAvatar(
            backgroundColor: panelColor,
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            appSettings.t('run_mode'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.time_lite',
              ),
              if (_routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6.0,
                      color: const Color(0xFF00E5FF),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition,
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF8FFF00),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8FFF00).withOpacity(0.6),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tarjeta flotante de telemetría
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(22.0),
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _metricCard(
                        appSettings.t('distance'),
                        '${km.toStringAsFixed(2)} km',
                        const Color(0xFF8FFF00),
                        textColor,
                      ),
                      _metricCard(
                        appSettings.t('time'),
                        '$minutes:$seconds',
                        const Color(0xFF00E5FF),
                        textColor,
                      ),
                      _metricCard(
                        'KCAL',
                        '$calories',
                        Colors.orangeAccent,
                        textColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: _isRunStarted
                            ? [Colors.redAccent, Colors.deepOrange]
                            : [
                                const Color(0xFF8FFF00),
                                const Color(0xFF00E5FF)
                              ],
                      ),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: _isRunStarted ? _stopRun : _startRun,
                      child: Text(
                        _isRunStarted
                            ? appSettings.t('stop_run')
                            : appSettings.t('start_run'),
                        style: TextStyle(
                          color: _isRunStarted ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
    String label,
    String value,
    Color accentColor,
    Color textColor,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: accentColor,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}